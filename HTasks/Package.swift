// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HTasks",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "HTasks",
            targets: ["HTasks"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
    ],
    targets: [
        .target(
            name: "HTasks",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
            ]),
        .testTarget(
            name: "HTasksTests",
            dependencies: ["HTasks"]),
    ]
) 