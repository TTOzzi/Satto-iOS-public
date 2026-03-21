//
//  CardFloatingView.swift
//  DesignSystem
//
//  Created by Codex on 3/21/26.
//

import SnapKit
import Then
import UIKit

public struct CardFloatingInfoItem {
  public let icon: UIImage
  public let text: String

  public init(icon: UIImage, text: String) {
    self.icon = icon
    self.text = text
  }
}

public final class CardFloatingView: UIView {

  public var onCloseButtonTapped: (() -> Void)?

  private let containerView = UIView().then {
    $0.backgroundColor = STColors.white.color
    $0.layer.cornerRadius = 16
    $0.layer.shadowColor = UIColor.black.cgColor
    $0.layer.shadowOpacity = 0.1
    $0.layer.shadowRadius = 10
    $0.layer.shadowOffset = CGSize(width: 0, height: 2)
  }

  private let titleLabel = UILabel().then {
    $0.style = Typography.Body_18_B
    $0.textColor = STColors.gray1.color
    $0.numberOfLines = 1
    $0.lineBreakMode = .byTruncatingTail
  }

  private lazy var closeButton = UIButton(type: .system).then {
    $0.setImage(STImages.xMark.image.withRenderingMode(.alwaysTemplate), for: .normal)
    $0.tintColor = STColors.gray4.color
    $0.backgroundColor = STColors.gray8.color
    $0.layer.cornerRadius = 12
    $0.clipsToBounds = true
    $0.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
  }

  private lazy var headerStackView = UIStackView(arrangedSubviews: [titleLabel, closeButton]).then {
    $0.axis = .horizontal
    $0.spacing = 20
    $0.alignment = .center
    $0.distribution = .fill
  }

  private let contentContainerView = UIView().then {
    $0.layer.borderColor = STColors.gray8.color.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 6
  }

  private let contentStackView = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 0
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    addSubview(containerView)
    containerView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }

    titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    closeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    closeButton.setContentHuggingPriority(.required, for: .horizontal)

    containerView.addSubview(headerStackView)
    headerStackView.snp.makeConstraints {
      $0.top.equalToSuperview().offset(20)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    closeButton.snp.makeConstraints {
      $0.width.height.equalTo(24)
    }

    containerView.addSubview(contentContainerView)
    contentContainerView.snp.makeConstraints {
      $0.top.equalTo(headerStackView.snp.bottom).offset(12)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalToSuperview().inset(40)
    }

    contentContainerView.addSubview(contentStackView)
    contentStackView.snp.makeConstraints {
      $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14))
    }
  }

  public func configure(title: String, items: [CardFloatingInfoItem]) {
    titleLabel.styledText = title
    updateInfoItems(items)
  }

  private func updateInfoItems(_ items: [CardFloatingInfoItem]) {
    contentStackView.arrangedSubviews.forEach {
      contentStackView.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }

    for (index, item) in items.enumerated() {
      let rowView = IconTextRowView()
      rowView.configure(with: item)
      contentStackView.addArrangedSubview(rowView)

      guard index < items.count - 1 else { continue }

      let dividerView = DashedLineView(color: STColors.gray8.color)
      contentStackView.addArrangedSubview(dividerView)
      dividerView.snp.makeConstraints {
        $0.height.equalTo(1)
      }
      contentStackView.setCustomSpacing(10, after: rowView)
      contentStackView.setCustomSpacing(10, after: dividerView)
    }
  }

  @objc private func didTapCloseButton() {
    onCloseButtonTapped?()
  }
}

private final class IconTextRowView: UIStackView {

  private let iconView = UIImageView().then {
    $0.contentMode = .scaleAspectFit
  }

  private let textLabel = UILabel().then {
    $0.style = Typography.Body_14_M
    $0.textColor = STColors.gray3.color
    $0.numberOfLines = 1
    $0.lineBreakMode = .byTruncatingTail
  }

  init() {
    super.init(frame: .zero)
    axis = .horizontal
    spacing = 8
    alignment = .center

    addArrangedSubview(iconView)
    iconView.snp.makeConstraints {
      $0.width.height.equalTo(12)
    }
    addArrangedSubview(textLabel)
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with item: CardFloatingInfoItem) {
    iconView.image = item.icon
    textLabel.styledText = item.text
  }
}
