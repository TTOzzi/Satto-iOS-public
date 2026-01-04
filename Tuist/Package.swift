// swift-tools-version: 6.0
import PackageDescription

#if TUIST
  import struct ProjectDescription.PackageSettings

  let packageSettings = PackageSettings(
    productTypes: [
      "Moya": .staticFramework,
      "Then": .staticFramework,
      "SnapKit": .staticFramework,
      "Swinject": .staticFramework,
      "SwiftRichString": .staticFramework,
      "Kingfisher": .staticFramework,
      "Lottie": .staticFramework,
      "spm-nmapsmap": .staticFramework
    ]
  )
#endif

let package = Package(
  name: "Satto",
  dependencies: [
    .package(url: "https://github.com/Moya/Moya.git", from: "15.0.3"),
    .package(url: "https://github.com/devxoul/Then.git", from: "3.0.0"),
    .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.1"),
    .package(url: "https://github.com/Swinject/Swinject.git", from: "2.9.1"),
    .package(url: "https://github.com/malcommac/SwiftRichString.git", from: "3.7.2"),
    .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.5.0"),
    .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.5.2"),
    .package(url: "https://github.com/navermaps/SPM-NMapsMap", from: "3.23.0"),
  ]
)
