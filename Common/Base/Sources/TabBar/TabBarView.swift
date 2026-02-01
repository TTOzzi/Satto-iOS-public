//
//  TabBarView.swift
//  Base
//
//  Created by ttozzi on 8/14/25.
//

import Combine
import DesignSystem
import Extension
import SnapKit
import Then
import UIKit

public final class TabBarView: UIView {

  enum Constant {
    static let tabBarHeight: CGFloat = 72
  }

  private lazy var contentStackView = UIStackView().then {
    $0.axis = .horizontal
    $0.distribution = .fillEqually
    $0.alignment = .center
    $0.spacing = 5
  }
  private var tabBarItems: [TabBarItem] = []
  private var cancellables = Set<AnyCancellable>()
  let selectedIndexSubject = CurrentValueSubject<Int, Never>(.zero)

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
    setupBinding()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    addSubview(contentStackView)
    contentStackView.snp.makeConstraints { make in
      make.top.equalToSuperview()
      make.horizontalEdges.equalToSuperview().inset(4)
      make.height.equalTo(Constant.tabBarHeight)
    }

    Tab.allCases.enumerated().forEach { index, tab in
      let item = TabBarItem()
      item.image = tab.icon
      item.title = tab.title
      item.isSelected = index == selectedIndexSubject.value
      contentStackView.addArrangedSubview(item)
      tabBarItems.append(item)
    }
  }

  private func setupBinding() {
    tabBarItems.enumerated().forEach { index, item in
      item.gesturePublisher(gestureRecognizer: UITapGestureRecognizer())
        .sink { [weak self] _ in
          self?.selectedIndexSubject.send(index)
        }
        .store(in: &cancellables)

      selectedIndexSubject
        .map { $0 == index }
        .sink { isSelected in
          item.isSelected = isSelected
        }
        .store(in: &cancellables)
    }
  }
}

@available(iOS 17.0, *)
#Preview {
  let tabBarView = TabBarView()
  tabBarView.snp.makeConstraints { make in
    make.width.equalTo(300)
    make.height.equalTo(72)
  }
  return tabBarView
}
