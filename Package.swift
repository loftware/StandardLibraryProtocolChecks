// swift-tools-version:5.1
import PackageDescription

let auxilliaryFiles = ["README.md", "LICENSE"]
let package = Package(
  name: "LoftTest_StandardLibraryProtocolChecks",
  products: [
    .library(
      name: "LoftTest_StandardLibraryProtocolChecks",
      targets: ["LoftTest_StandardLibraryProtocolChecks"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/loftware/CheckXCAssertionFailure",
      from: "0.9.6"),
  ],
  targets: [
    .target(
      name: "LoftTest_StandardLibraryProtocolChecks",
      path: ".",
      exclude: auxilliaryFiles + ["Tests.swift"],
      sources: ["StandardLibraryProtocolChecks.swift"]),
    .testTarget(
      name: "Test_StandardLibraryProtocolChecks",
      dependencies: [
        "LoftTest_StandardLibraryProtocolChecks",
        "LoftTest_CheckXCAssertionFailure"
      ],
      path: ".",
      exclude: auxilliaryFiles + ["StandardLibraryProtocolChecks.swift"],
      sources: ["Tests.swift"]),
  ]
)
