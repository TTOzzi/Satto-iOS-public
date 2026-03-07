import ProjectDescription
import ProjectDescriptionHelpers

let project = AppLayer().project

struct AppLayer: Layer {

  var name: String { "Satto" }
  var options: Project.Options { .options(automaticSchemesOptions: .disabled) }
  var targets: [Target] {
    [
      .createTarget(
        name: name,
        product: .app,
        bundleId: "com.hanbang.satto",
        infoPlist: .extendingDefault(
          with: [
            "CFBundleDisplayName": "$(APP_NAME)",
            "CFBundleShortVersionString": "$(MARKETING_VERSION)",
            "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
            "ITSAppUsesNonExemptEncryption": false,
            "NAVER_MAP_CLIENT_ID": "$(NAVER_MAP_CLIENT_ID)",
            "NSLocationWhenInUseUsageDescription": "위치 정보를 기반으로 현재 위치, 주변 검색, 길찾기 정보, 컨텐츠 추천 및 광고를 제공합니다",
            "UILaunchStoryboardName": "LaunchScreen",
            "UIUserInterfaceStyle": "Light",
            "UISupportedInterfaceOrientations": [
              "UIInterfaceOrientationPortrait"
            ],
            "UIApplicationSceneManifest": [
              "UIApplicationSupportsMultipleScenes": false,
              "UISceneConfigurations": [
                "UIWindowSceneSessionRoleApplication": [
                  [
                    "UISceneConfigurationName": "Default Configuration",
                    "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate",
                  ]
                ]
              ],
            ],
          ]
        ),
        sources: ["Sources/**"],
        resources: ["Resources/**"],
        dependencies: [.project(target: "FeatureLayer", path: "../Feature")],
        settings: .settings(
          base: [
            "PRODUCT_BUNDLE_IDENTIFIER": "$(APP_IDENTIFIER)",
            "TARGETED_DEVICE_FAMILY": "1",
            "MARKETING_VERSION": "1.0.1",
            "CURRENT_PROJECT_VERSION": "0",
          ],
          configurations: [
            .debug(
              name: .debug,
              settings: [
                "APP_IDENTIFIER": "com.hanbang.satto.debug",
                "APP_NAME": "사또 Debug",
                "OTHER_SWIFT_FLAGS": "$(inherited) -DDEBUG",
              ],
              xcconfig: "Configs/Debug.xcconfig"
            ),
            .release(
              name: .release,
              settings: [
                "APP_IDENTIFIER": "com.hanbang.satto",
                "APP_NAME": "사또",
                "OTHER_SWIFT_FLAGS": "$(inherited) -DRELEASE",
              ],
              xcconfig: "Configs/Release.xcconfig"
            ),
          ]
        )
      )
    ]
  }
  var schemes: [Scheme] {
    [
      .scheme(
        name: "\(name)-debug",
        buildAction: .buildAction(targets: [.project(path: "./", target: name)]),
        runAction: .runAction(configuration: .debug),
        archiveAction: .archiveAction(configuration: .debug),
        profileAction: .profileAction(configuration: .debug),
        analyzeAction: .analyzeAction(configuration: .debug)
      ),
      .scheme(
        name: "\(name)-release",
        buildAction: .buildAction(targets: [.project(path: "./", target: name)]),
        runAction: .runAction(configuration: .release),
        archiveAction: .archiveAction(configuration: .release),
        profileAction: .profileAction(configuration: .release),
        analyzeAction: .analyzeAction(configuration: .release)
      ),
    ]
  }
}
