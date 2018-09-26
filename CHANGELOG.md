# Changelog
All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2018-09-27
### Added
- Swift 4 support.
- `Unlock` event notification, for files being unlocked by the `funlock` syscall.
- `DataAvailable` event notification, to test for `EVFILT_READ` activation.
- This changelog.

### Removed
- Logging to the system console.

## [1.1.0] - 2017-04-25
### Added
- Method `fileDescriptorForPath` in `SKQueue`.
- Optional `delegate` parameter to the `SKQueue` initializer.

## [1.0.0] - 2017-04-10
### Changed
- API follows the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).

### Removed
- An overloaded `receivedNotification` in the `SKQueueDelegate` protocol which accepts notification as a string.

## [0.9.0] - 2017-04-10
### Added
- Swift package manager support.

[1.2.0]: https://github.com/daniel-pedersen/SKQueue/tree/v1.2.0
[1.1.0]: https://github.com/daniel-pedersen/SKQueue/tree/v1.1.0
[1.0.0]: https://github.com/daniel-pedersen/SKQueue/tree/v1.0.0
[0.9.0]: https://github.com/daniel-pedersen/SKQueue/tree/v0.9.0
