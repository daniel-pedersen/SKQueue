# SKQueue
SKQueue is a simple and efficient Swift library that uses kernel event notifications (kernel queues or kqueue) to monitor changes to the filesystem. It allows you to watch any file or folder for changes and be notified immediately when they occur.

## Installation

### Swift Package Manager

1. Create a new project ex. `swift package init --type executable`
2. Add SKQueue as a dependency to your Package.swift
```swift
import PackageDescription

let package = Package(
  name: "SampleProject",
  dependencies: [
    .Package(url: "https://github.com/daniel-pedersen/SKQueue.git", majorVersion: 1)
  ]
)
```
3. Fetch dependencies. `swift package fetch`
4. (Optional) Generate and open an Xcode project. `swift package generate-xcodeproj && open *.xcodeproj`

## Usage

### Example
```swift
class SomeClass: SKQueueDelegate {
  func receivedNotification(_ notification: SKQueueNotification, path: String, queue: SKQueue) {
    print("\(notification.toStrings().map { $0.rawValue }) @ \(path)")
  }
}

let delegate = SomeClass()
let queue = SKQueue(delegate: delegate)!

queue.addPath("/some/file/or/directory")
queue.addPath("/some/other/file/or/directory")
```

#### Output samples
Action | Output
------ | ----------------------
Add or remove file in `/directory` | `["Write"] @ /directory`
Add or remove directory in `/directory` | `["Write", "SizeIncrease"] @ /directory`
Write to file in `/directory/file` | `["Rename", "SizeIncrease"] @ /directory/file`

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## History

### v1.1
- Added method fileDescriptorForPath to SKQueue
- Added delegate parameter to SKQueue initializer

### v1.0
- New API (see example above)
- Removed extension of the SKQueueDelegate protocol (see below)

### v0.9
- Legacy API (see source)

#### Migrating to v1.0
The naming and ordering of parameters have changed, Xcode points this out at the appropriate locations.

If you have been using the overloaded receivedNotification that takes strings, you need to manually extend SKQueueDelegate as follows
```swift
extension SKQueueDelegate {
  func receivedNotification(_ queue: SKQueue, _ notificationName: SKQueueNotificationString, forPath path: String)
  func receivedNotification(_ queue: SKQueue, _ notification: SKQueueNotification, forPath path: String) {
    notification.toStrings().forEach { self.receivedNotification(queue, $0, forPath: path) }
  }
}
```
