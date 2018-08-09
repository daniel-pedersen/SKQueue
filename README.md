# SKQueue
SKQueue is a Swift libary used to monitor changes to the filesystem. It is a wrapper around the kernel event notification interface of libc, i.e. [kqueue](https://en.wikipedia.org/wiki/Kqueue).

SKQueue allocates one file descriptor per path watched and wraps the kernel events around a callback. This means SKQueue has an extremely small footprint and is highly scalable, just like kqueue.

## Installation

### Swift Package Manager
Add SKQueue to the dependencies array in your `Package.swift`. Then fetch dependencies with `swift package fetch`.
```swift
dependencies: [
  .package(url: "https://github.com/daniel-pedersen/SKQueue.git", .branch("develop"))
]
```

## Usage

### Example
```swift
import SKQueue

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

|                 Action                 |                     Sample output                     |
|:--------------------------------------:|:-----------------------------------------------------:|
|   Add or remove file in `directory`    |               `["Write"] @ /directory`                |
| Add or remove directory in `directory` |       `["Write", "SizeIncrease"] @ /directory`        |
| Write to file `directory/example.txt`  | `["Rename", "SizeIncrease"] @ /directory/example.txt` |

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D
