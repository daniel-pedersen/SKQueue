// swift-tools-version:4.2

import PackageDescription

let package = Package(
  name: "SKQueue",
  products: [
    .library(name: "SKQueue", targets: ["SKQueue"])
  ],
  dependencies: [],
  targets: [
    .target(name: "SKQueue", path: ".", sources: ["SKQueue.swift"])
  ]
)
