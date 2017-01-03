//
//  SKQueue.swift
//
//  Created by Daniel J F Pedersen on 2015-06-29
//  Copyright 2015 Daniel J F Pedersen
//
//  Port of VDKQueue to Swift. VDKQueue was created and copyrighted by Bryan D K Jones on 28 March 2012.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software.
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//     1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//     2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//     3. This notice may not be removed or altered from any source
//     distribution.
//

import Foundation
import Darwin

private func ev_create(ident: UInt, filter: Int16, flags: UInt16, fflags: UInt32, data: Int, udata: UnsafeMutableRawPointer) -> kevent {
    var ev = kevent()
    ev.ident = ident
    ev.filter = filter
    ev.flags = flags
    ev.fflags = fflags
    ev.data = data
    ev.udata = udata
    return ev
}

// MARK: - SKQueueDelegate
protocol SKQueueDelegate {
    func receivedNotification(queue: SKQueue, _ notification: SKQueueNotification, forPath path: String)
    func receivedNotification(queue: SKQueue, _ notificationName: SKQueueNotificationString, forPath path: String)
}

extension SKQueueDelegate {
    func receivedNotification(queue: SKQueue, _ notification: SKQueueNotification, forPath path: String) {
      notification.toStrings().forEach { self.receivedNotification(queue: queue, $0, forPath: path) }
    }
}

// MARK: - SKQueueNotificationString
enum SKQueueNotificationString: String {
    case Rename
    case Write
    case Delete
    case AttributeChange
    case SizeIncrease
    case LinkCountChange
    case AccessRevocation
}

// MARK: - SKQueueNotification
struct SKQueueNotification: OptionSet {
    let rawValue: UInt32
    
    static let None             = SKQueueNotification(rawValue: 0)
    static let Rename           = SKQueueNotification(rawValue: 1 << 0)
    static let Write            = SKQueueNotification(rawValue: 1 << 1)
    static let Delete           = SKQueueNotification(rawValue: 1 << 2)
    static let AttributeChange  = SKQueueNotification(rawValue: 1 << 3)
    static let SizeIncrease     = SKQueueNotification(rawValue: 1 << 4)
    static let LinkCountChange  = SKQueueNotification(rawValue: 1 << 5)
    static let AccessRevocation = SKQueueNotification(rawValue: 1 << 6)
    static let Default          = SKQueueNotification(rawValue: 0x7F)
    
    func toStrings() -> [SKQueueNotificationString] {
        var s = [SKQueueNotificationString]()
        if contains(.Rename)           { s.append(.Rename) }
        if contains(.Write)            { s.append(.Write) }
        if contains(.Delete)           { s.append(.Delete) }
        if contains(.AttributeChange)  { s.append(.AttributeChange) }
        if contains(.SizeIncrease)     { s.append(.SizeIncrease) }
        if contains(.LinkCountChange)  { s.append(.LinkCountChange) }
        if contains(.AccessRevocation) { s.append(.AccessRevocation) }
        return s
    }
}

// MARK: - SKQueuePath
private class SKQueuePath {
    var path: String, fileDescriptor: CInt, notification: SKQueueNotification
    
    init?(path: String, notification: SKQueueNotification) {
        self.path = path
        self.fileDescriptor = open((path as NSString).fileSystemRepresentation, O_EVTONLY, 0)
        self.notification = notification
        if self.fileDescriptor < 0 {
            return nil
        }
    }
    
    deinit {
        if self.fileDescriptor >= 0 {
            close(self.fileDescriptor)
        }
    }
}

// MARK: - SKQueue
class SKQueue {
    private var kqueueId: CInt, watchedPaths = [String: SKQueuePath](), keepWatcherThreadRunning = false
    var delegate: SKQueueDelegate?
    
    init?() {
        kqueueId = kqueue()
        if (kqueueId == -1) {
            return nil
        }
    }
    
    deinit {
        keepWatcherThreadRunning = false
        removeAllPaths()
    }
    
    private func addPathToQueue(path: String, notifyingAbout notification: SKQueueNotification) -> SKQueuePath? {
        var pathEntry = watchedPaths[path]
        
        if pathEntry != nil {
            if pathEntry!.notification.contains(notification) {
                return pathEntry
            }
            pathEntry!.notification.insert(notification)
        } else {
            pathEntry = SKQueuePath(path: path, notification: notification)
            if pathEntry == nil {
                return nil
            }
            watchedPaths[path] = pathEntry!
        }
        
        var nullts = timespec(tv_sec: 0, tv_nsec: 0)
        var ev = ev_create(
            ident: UInt(pathEntry!.fileDescriptor),
            filter: Int16(EVFILT_VNODE),
            flags: UInt16(EV_ADD | EV_ENABLE | EV_CLEAR),
            fflags: notification.rawValue,
            data: 0,
            udata: UnsafeMutableRawPointer(Unmanaged<SKQueuePath>.passRetained(watchedPaths[path]!).toOpaque())
        )
        
        kevent(kqueueId, &ev, 1, nil, 0, &nullts)
        
        if !keepWatcherThreadRunning {
            keepWatcherThreadRunning = true
          DispatchQueue.global(qos: .default).async(execute: watcherThread)
        }
        
        return pathEntry
    }
    
    private func watcherThread() {
        var ev = kevent(), timeout = timespec(tv_sec: 1, tv_nsec: 0), fd = kqueueId
        
        while (keepWatcherThreadRunning) {
            let n = kevent(fd, nil, 0, &ev, 1, &timeout)
            if n > 0 && ev.filter == Int16(EVFILT_VNODE) && ev.fflags != 0 {
                let pathEntry = Unmanaged<SKQueuePath>.fromOpaque(UnsafeRawPointer(ev.udata)).takeUnretainedValue()
                let notification = SKQueueNotification(rawValue: ev.fflags)
                DispatchQueue.main.async {
                  self.delegate?.receivedNotification(queue: self, notification, forPath: pathEntry.path)
                }
            }
        }
        
        if close(fd) == -1 {
            print("SKQueue watcherThread: Couldn't close main kqueue (\(errno))")
        }
    }
    
    func addPath(_ path: String, notifyingAbout notification: SKQueueNotification = SKQueueNotification.Default) {
        if addPathToQueue(path: path, notifyingAbout: notification) == nil {
            print("SKQueue tried to add the path \(path) to watchedPaths, but the SKQueuePath was nil. \nIt's possible that the host process has hit its max open file descriptors limit.")
        }
    }
    
    func isPathWatched(path: String) -> Bool {
        return watchedPaths[path] != nil
    }

    func removePath(_ path: String) {
        if let pathEntry = watchedPaths.removeValue(forKey: path) {
            Unmanaged<SKQueuePath>.passUnretained(pathEntry).release()
        }
    }
    
    func removeAllPaths() {
        watchedPaths.keys.forEach(removePath)
    }
    
    func numberOfWatchedPaths() -> Int {
        return watchedPaths.count
    }
}
