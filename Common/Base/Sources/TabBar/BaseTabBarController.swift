//
//  BaseTabBarController.swift
//  Base
//
//  Created by ttozzi on 8/10/25.
//

import Combine
import DesignSystem
import SnapKit
import Then
import UIKit

public final class BaseTabBarController: UITabBarController {

  public private(set) lazy var customTabBar = TabBarView().then {
    $0.backgroundColor = STColors.white.color
  }
  private var cancellables = Set<AnyCancellable>()

  public override func viewDidLoad() {
    super.viewDidLoad()
    setupTabBar()
    setupBindings()
  }

  public override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    tabBar.isHidden = true
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    if let window = view.window {
      customTabBar.snp.updateConstraints { make in
        make.height.equalTo(TabBarView.Constant.tabBarHeight + window.safeAreaInsets.bottom)
      }
    }
  }

  override public func setTabBarHidden(_ hidden: Bool, animated: Bool) {
    customTabBar.isHidden = hidden
  }

  private func setupTabBar() {
    tabBar.isHidden = true

    view.addSubview(customTabBar)
    customTabBar.snp.makeConstraints { make in
      make.height.equalTo(TabBarView.Constant.tabBarHeight)
      make.leading.trailing.bottom.equalToSuperview()
    }
  }

  private func setupBindings() {
    customTabBar.selectedIndexSubject
      .sink { [weak self] selectedIndex in
        self?.selectedIndex = selectedIndex
      }
      .store(in: &cancellables)
  }
}

@available(iOS 17.0, *)
#Preview {
  let tabBarController = BaseTabBarController()
  return tabBarController
}
