import Foundation

func ev_create(ident: UInt, filter: Int16, flags: UInt16, fflags: UInt32, data: Int, udata: UnsafeMutableRawPointer) -> kevent {
  var ev = kevent()
  ev.ident = ident
  ev.filter = filter
  ev.flags = flags
  ev.fflags = fflags
  ev.data = data
  ev.udata = udata
  return ev
}

public protocol SKQueueDelegate {
  func receivedNotification(_ notification: SKQueueNotification, path: String, queue: SKQueue)
}

public enum SKQueueNotificationString: String {
  case Rename
  case Write
  case Delete
  case AttributeChange
  case SizeIncrease
  case LinkCountChange
  case AccessRevocation
  case Unlock
  case DataAvailable
}

public struct SKQueueNotification: OptionSet {
  public let rawValue: UInt32

  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }

  public static let None             = SKQueueNotification(rawValue: 0)
  public static let Rename           = SKQueueNotification(rawValue: UInt32(NOTE_RENAME))
  public static let Write            = SKQueueNotification(rawValue: UInt32(NOTE_WRITE))
  public static let Delete           = SKQueueNotification(rawValue: UInt32(NOTE_DELETE))
  public static let AttributeChange  = SKQueueNotification(rawValue: UInt32(NOTE_ATTRIB))
  public static let SizeIncrease     = SKQueueNotification(rawValue: UInt32(NOTE_EXTEND))
  public static let LinkCountChange  = SKQueueNotification(rawValue: UInt32(NOTE_LINK))
  public static let AccessRevocation = SKQueueNotification(rawValue: UInt32(NOTE_REVOKE))
  public static let Unlock           = SKQueueNotification(rawValue: UInt32(NOTE_FUNLOCK))
  public static let DataAvailable    = SKQueueNotification(rawValue: UInt32(NOTE_NONE))
  public static let Default          = SKQueueNotification(rawValue: UInt32(INT_MAX))

  public func toStrings() -> [SKQueueNotificationString] {
    var s = [SKQueueNotificationString]()
    if contains(.Rename)           { s.append(.Rename) }
    if contains(.Write)            { s.append(.Write) }
    if contains(.Delete)           { s.append(.Delete) }
    if contains(.AttributeChange)  { s.append(.AttributeChange) }
    if contains(.SizeIncrease)     { s.append(.SizeIncrease) }
    if contains(.LinkCountChange)  { s.append(.LinkCountChange) }
    if contains(.AccessRevocation) { s.append(.AccessRevocation) }
    if contains(.Unlock)           { s.append(.Unlock) }
    if contains(.DataAvailable)    { s.append(.DataAvailable) }
    return s
  }
}

class SKQueuePath {
  var path: String
  var fileDescriptor: Int32
  var notification: SKQueueNotification

  init?(_ path: String, notification: SKQueueNotification) {
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

public class SKQueue {
  private var kqueueId: Int32
  private var watchedPaths = [String: SKQueuePath]()
  private var keepWatcherThreadRunning = false
  public var delegate: SKQueueDelegate?

  public init?(delegate: SKQueueDelegate? = nil) {
    kqueueId = kqueue()
    if (kqueueId == -1) {
      return nil
    }
    self.delegate = delegate
  }

  deinit {
    keepWatcherThreadRunning = false
    removeAllPaths()
    close(kqueueId)
  }

  public func addPath(_ path: String, notifyingAbout notification: SKQueueNotification = SKQueueNotification.Default) -> Int32? {
    var pathEntry = watchedPaths[path]
 
    if pathEntry != nil {
      if pathEntry!.notification.contains(notification) {
        return pathEntry?.fileDescriptor
      }
      pathEntry!.notification.insert(notification)
    } else {
      pathEntry = SKQueuePath(path, notification: notification)
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
      DispatchQueue.global().async(execute: watcherThread)
    }

    return pathEntry?.fileDescriptor
  }

  private func watcherThread() {
    var ev = kevent(), timeout = timespec(tv_sec: 1, tv_nsec: 0), fd = kqueueId

    while (keepWatcherThreadRunning) {
      let n = kevent(fd, nil, 0, &ev, 1, &timeout)
      if n > 0 && ev.filter == Int16(EVFILT_VNODE) && ev.fflags != 0 {
        let pathEntry = Unmanaged<SKQueuePath>.fromOpaque(ev.udata).takeUnretainedValue()
        let notification = SKQueueNotification(rawValue: ev.fflags)
        DispatchQueue.global().async {
          self.delegate?.receivedNotification(notification, path: pathEntry.path, queue: self)
        }
      }
    }
  }

  public func isPathWatched(_ path: String) -> Bool {
    return watchedPaths[path] != nil
  }

  public func removePath(_ path: String) {
    if let pathEntry = watchedPaths.removeValue(forKey: path) {
      Unmanaged<SKQueuePath>.passUnretained(pathEntry).release()
    }
  }

  public func removeAllPaths() {
    watchedPaths.keys.forEach(removePath)
  }

  public func numberOfWatchedPaths() -> Int {
    return watchedPaths.count
  }

  public func fileDescriptorForPath(_ path: String) -> Int32 {
    if let fileDescriptor = watchedPaths[path]?.fileDescriptor {
      return fcntl(fileDescriptor, F_DUPFD)
    }
    return -1
  }
}
