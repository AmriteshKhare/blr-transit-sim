// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BLRTransitApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "BLRTransitApp",
            targets: ["BLRTransitApp"]
        )
    ],
    targets: [
        .target(
            name: "BLRTransitApp",
            path: "BLRTransitApp"
        )
    ]
)
