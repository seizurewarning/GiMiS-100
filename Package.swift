// swift-tools-version: 6.0
import PackageDescription

let package = Package(
	name: "SwiftGmic",
	platforms: [
		.macOS(.v15),
	],
	products: [
		.library(
			name: "SwiftGmic",
			targets: ["SwiftGmic"]
		),
	],
	targets: [
		.binaryTarget(
			name: "SwiftGmicFramework",
			path: "libs/libgmic.xcframework"
		),
		.target(
			name: "SwiftGmic",
			dependencies: ["SwiftGmicFramework"],
			cSettings: [
				.headerSearchPath("include")
			],
			linkerSettings: [
				.linkedFramework("Foundation")
			]
		)
	]
)
