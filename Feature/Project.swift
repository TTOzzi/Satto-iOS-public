import ProjectDescription
import ProjectDescriptionHelpers

let project = FeatureLayer().project

struct FeatureLayer: Layer {

  var targets: [Target] {
    [
      .createTarget(
        name: name,
        sources: .empty,
        dependencies: [
          .target(name: "Onboarding"),
          .target(name: "Home"),
          .target(name: "Setting"),
          .target(name: "History"),
          .target(name: "Fortune"),
          .target(name: "Map"),
        ],
        settings: .settings(
          base: [
            "DEFINES_MODULE": "NO",
            "SWIFT_INSTALL_OBJC_HEADER": "NO",
          ]
        )
      ),
      .createTarget(
        name: "Onboarding",
        dependencies: [
          .project(target: "CommonLayer", path: "../Common")
        ]
      ),
      .createTarget(
        name: "Home",
        dependencies: [
          .project(target: "CommonLayer", path: "../Common")
        ]
      ),
      .createTarget(
        name: "Setting",
        dependencies: [
          .project(target: "CommonLayer", path: "../Common")
        ]
      ),
      .createTarget(
        name: "History",
        dependencies: [
          .project(target: "CommonLayer", path: "../Common")
        ]
      ),
      .createTarget(
        name: "Fortune",
        dependencies: [
          .project(target: "CommonLayer", path: "../Common")
        ]
      ),
      .createTarget(
        name: "Map",
        dependencies: [
          .project(target: "CommonLayer", path: "../Common"),
          .external(name: "NMapsMap")
        ]
      ),
    ]
  }
}
