//
//  AppDependencyHandler.swift
//  Satto
//
//  Created by ttozzi on 8/16/25.
//

import Base
import Fortune
import Foundation
import History
import Home
import Lib
import Map
import Onboarding
import Setting
import UIKit

struct AppDependencyHandler: DependencyRegistrable {
  func register(to dependencyHandler: DependencyHandler) {
    dependencyHandler.register(key: DependencyKey.App.configureTabBarController) {
      Task { @MainActor in
        self.configureTabBarController()
      }
    }

    dependencyHandler.register(key: DependencyKey.App.moveToSplashViewController) {
      Task { @MainActor in
        self.moveToSplashViewController()
      }
    }
  }

  private func configureTabBarController() {
    // TODO: 이미 TabBarController 가 있는 경우에 대한 예외 처리
    let tabBarController = BaseTabBarController()
    tabBarController.viewControllers = [

      BaseNavigationController(rootViewController: HomeViewController(viewModel: HomeViewModel())),
      //      BaseNavigationController(
      //        rootViewController: FortuneViewController(viewModel: FortuneViewModel())),
      BaseNavigationController(
        rootViewController: HistoryWebViewController(viewModel: HistoryWebViewModel())),
      BaseNavigationController(
        rootViewController: MapViewController(viewModel: MapViewModel())),
      BaseNavigationController(
        rootViewController: MyPageViewController(viewModel: MyPageViewModel())),
    ]
    UIApplication.shared.activeWindow?.rootViewController = tabBarController
  }

  private func moveToSplashViewController() {
    let router = OnboardingRouter()
    let splashViewController = SplashViewcontroller(viewModel: SplashViewModel(), router: router)

    let navigationController = UINavigationController(rootViewController: splashViewController)

    UIApplication.shared.activeWindow?.rootViewController = navigationController
  }
}

extension UIApplication {
  fileprivate var activeWindow: UIWindow? {
    return
      connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }
}
