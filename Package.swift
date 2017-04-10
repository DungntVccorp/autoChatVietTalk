// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "autoChatVietTalk",
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/BlueSocket.git", Version(0,12,43)),
        .Package(url: "https://github.com/apple/swift-protobuf.git", Version(0,9,24)),
    ]
)
