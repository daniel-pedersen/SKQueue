# SKQueue
SKQueue is a Swift libary used to monitor changes to the filesystem.
It wraps the part of the kernel event notification interface of libc, [kqueue](https://en.wikipedia.org/wiki/Kqueue).
This means SKQueue has a very small footprint and is highly scalable, just like kqueue.

## Requirements
* Swift tools version 4

To build in older environments just replace `Package.swift` with [this file](https://github.com/daniel-pedersen/SKQueue/blob/v1.1.0/Package.swift).

## Installation

### Swift Package Manager
To use SKQueue, add the code below to your `dependencies` in `Package.swift`.
Then run `swift package fetch` to fetch SKQueue.
```swift
.package(url: "https://github.com/daniel-pedersen/SKQueue.git", from: "1.2.0"),
```

## Usage
To monitor the filesystem with `SKQueue`, you first need a `SKQueueDelegate` instance that can accept notifications.
Paths to watch can then be added with `addPath`, as per the example below.

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

queue.addPath("/Users/steve/Documents")
queue.addPath("/Users/steve/Documents/dog.jpg")
```
|                       Action                        |                         Sample output                         |
|:---------------------------------------------------:|:-------------------------------------------------------------:|
|   Add or remove file in `/Users/steve/Documents`    |             `["Write"] @ /Users/steve/Documents`              |
| Add or remove directory in `/Users/steve/Documents` |     `["Write", "SizeIncrease"] @ /Users/steve/Documents`      |
|   Write to file `/Users/steve/Documents/dog.jpg`    | `["Rename", "SizeIncrease"] @ /Users/steve/Documents/dog.jpg` |

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D
