# SKQueue
Lightweight port of [VDKQueue](https://github.com/bdkjones/VDKQueue).

SKQueue is a simple and efficient Swift wrapper around kernel queues (kQueues). It allows you to watch a file or folder for changes and be notified when they occur. See [VDKQueue](https://github.com/bdkjones/VDKQueue) for more info.

## Example
```swift
class SomeClass: SKQueueDelegate {
    func receivedNotification(queue: SKQueue, _ notificationName: SKQueueNotificationString, forPath path: String) {
        print("\(notificationName.rawValue) @ \(path)")
    }
}
```

```swift
if let queue = SKQueue() {
    let delegate = SomeClass()

    queue.delegate = delegate
    queue.addPath("/some/file/or/directory")
    queue.addPath("/some/other/file/or/directory")
}
```

```swift
// Possible output when adding a file to '/some/file/or/directory':
//     > Write @ /some/file/or/directory
//     > SizeIncrease @ /some/file/or/directory
```
