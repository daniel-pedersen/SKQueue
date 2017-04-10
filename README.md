# SKQueue
Lightweight port of [VDKQueue](https://github.com/bdkjones/VDKQueue).

SKQueue is a simple and efficient Swift wrapper around kernel queues (kQueues). It allows you to watch a file or folder for changes and be notified when they occur. See [VDKQueue](https://github.com/bdkjones/VDKQueue) for more info.

## Installation

### Swift Package Manager

1. Create a new project ex. `swift package init --type executable`
2. Add SKQueue as a dependency to your Package.swift
```swift
import PackageDescription

let package = Package(
    name: "SampleProject",
    dependencies: [.Package(url: "https://github.com/daniel-pedersen/SKQueue.git", majorVersion: 1)]
)
```
3. Fetch dependencies. `swift package fetch`
4. (Optional) Generate and open an Xcode project. `swift package generate-xcodeproj && open *.xcodeproj`

## Example
### Code
```swift
class SomeClass: SKQueueDelegate {
  func receivedNotification(_ notification: SKQueueNotification, path: String, queue: SKQueue) {
    print("\(notification.toStrings().map { $0.rawValue }) @ \(path)")
  }
}

if let queue = SKQueue() {
  let delegate = SomeClass()

  queue.delegate = delegate
  queue.addPath("/some/file/or/directory")
  queue.addPath("/some/other/file/or/directory")
}
```

### Output samples
Action | Output
------ | ----------------------
Add or remove file in `/directory` | `["Write"] @ /directory`
Add or remove directory in `/directory` | `["Write", "SizeIncrease"] @ /directory`
Write to file in `/directory/file` | `["Rename", "SizeIncrease"] @ /directory/file`
