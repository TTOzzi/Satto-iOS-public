import Auth
import Fortune
import Lib
import Onboarding
import Setting
import UIKit
import NMapsMap

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    setupDependencyInjector()
    setupDependencyHandler()
    configureNaverMapAuth()
    return true
  }

  private func configureNaverMapAuth() {
    guard
      let keyId = Bundle.main.object(forInfoDictionaryKey: "NAVER_MAP_CLIENT_ID") as? String,
      !keyId.isEmpty
    else {
      assertionFailure("NAVER_MAP_CLIENT_ID is missing. Set it in App/Configs/*.xcconfig.local")
      return
    }

    NMFAuthManager.shared().ncpKeyId = keyId
  }

  // MARK: UISceneSession Lifecycle

  func application(
    _ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {

    return UISceneConfiguration(
      name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(
    _ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>
  ) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }
}
