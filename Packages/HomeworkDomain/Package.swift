// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HomeworkDomain",
    platforms: [.iOS("26.0"), .macOS(.v15)],
    products: [.library(name: "HomeworkDomain", targets: ["HomeworkDomain"])],
    targets: [
        .target(name: "HomeworkDomain"),
        .testTarget(name: "HomeworkDomainTests", dependencies: ["HomeworkDomain"])
    ]
)
