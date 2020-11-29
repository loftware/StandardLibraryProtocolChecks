// swift-tools-version:5.1
import PackageDescription

let auxilliaryFiles = ["README.md", "LICENSE"]
let package = Package(
  name: "LoftTest_StandardLibraryProtocolChecks",
  dependencies: [
    .package(
      name: "LoftTest_CheckXCAssertionFailure",
      url: "https://github.com/loftware/CheckXCAssertionFailure",
      from: "0.9.0"),
  ],
  targets: [
    .target(
      name: "LoftTest_StandardLibraryProtocolChecks",
      path: ".",
      exclude: auxilliaryFiles + ["Tests.swift"],
      sources: ["StandardLibraryProtocolChecks.swift"]),
    .testTarget(
      name: "Test",
      dependencies: [
        "LoftTest_StandardLibraryProtocolChecks",
        "LoftTest_CheckXCAssertionFailure"],
      path: ".",
      exclude: auxilliaryFiles + ["StandardLibraryProtocolChecks.swift"],
      sources: ["Tests.swift"]
    ),
  ]
)
