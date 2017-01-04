# SKQueue
Lightweight port of [VDKQueue](https://github.com/bdkjones/VDKQueue).

SKQueue is a simple and efficient Swift wrapper around kernel queues (kQueues). It allows you to watch a file or folder for changes and be notified when they occur. See [VDKQueue](https://github.com/bdkjones/VDKQueue) for more info.

## Example
### Code
```swift
class SomeClass: SKQueueDelegate {
  func receivedNotification(_ notification: SKQueueNotification, forPath path: String, queue: SKQueue) {
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
