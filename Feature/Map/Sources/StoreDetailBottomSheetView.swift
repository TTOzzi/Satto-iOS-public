//
//  StoreDetailBottomSheetView.swift
//  Map
//
//  Created by ttozzi on 2/1/26.
//

import DesignSystem
import SnapKit
import Then
import UIKit

final class StoreDetailBottomSheetView: UIView {

  var onCloseButtonTapped: (() -> Void)?

  private let containerView = UIView().then {
    $0.backgroundColor = STColors.white.color
    $0.layer.cornerRadius = 16
    $0.layer.shadowColor = UIColor.black.cgColor
    $0.layer.shadowOpacity = 0.1
    $0.layer.shadowRadius = 10
    $0.layer.shadowOffset = CGSize(width: 0, height: 2)
  }

  private let nameLabel = UILabel().then {
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

  private lazy var headerStackView = UIStackView(arrangedSubviews: [nameLabel, closeButton]).then {
    $0.axis = .horizontal
    $0.spacing = 20
    $0.alignment = .center
    $0.distribution = .fill
  }

  private let addressIconView = UIImageView().then {
    $0.image = STImages.navigation.image
    $0.contentMode = .scaleAspectFit
  }

  private let addressLabel = UILabel().then {
    $0.style = Typography.Body_14_M
    $0.textColor = STColors.gray3.color
    $0.numberOfLines = 1
    $0.lineBreakMode = .byTruncatingTail
  }

  private let phoneIconView = UIImageView().then {
    $0.image = STImages.phone.image
    $0.contentMode = .scaleAspectFit
  }

  private let phoneLabel = UILabel().then {
    $0.style = Typography.Body_14_M
    $0.textColor = STColors.gray3.color
  }

  private let phoneStackView = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 8
    $0.alignment = .center
  }

  private let contentContainerView = UIView().then {
    $0.layer.borderColor = STColors.gray8.color.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 6
  }

  private let dividerView = UIView().then {
    $0.backgroundColor = .clear
  }

  private let contentStackView = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 0
  }

  override init(frame: CGRect) {
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

    nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
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

    let addressStackView = UIStackView(arrangedSubviews: [addressIconView, addressLabel])
    addressStackView.axis = .horizontal
    addressStackView.spacing = 8
    addressStackView.alignment = .center

    addressIconView.snp.makeConstraints {
      $0.width.height.equalTo(12)
    }

    phoneStackView.addArrangedSubview(phoneIconView)
    phoneStackView.addArrangedSubview(phoneLabel)

    phoneIconView.snp.makeConstraints {
      $0.width.height.equalTo(12)
    }

    contentStackView.addArrangedSubview(addressStackView)
    contentStackView.addArrangedSubview(dividerView)
    contentStackView.addArrangedSubview(phoneStackView)
    contentStackView.setCustomSpacing(10, after: addressStackView)
    contentStackView.setCustomSpacing(10, after: dividerView)

    dividerView.snp.makeConstraints {
      $0.height.equalTo(1)
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

  override func layoutSubviews() {
    super.layoutSubviews()
    updateDividerDash()
  }

  private func updateDividerDash() {
    dividerView.layer.sublayers?.removeAll(where: { $0 is CAShapeLayer })

    let shapeLayer = CAShapeLayer()
    shapeLayer.strokeColor = STColors.gray8.color.cgColor
    shapeLayer.lineWidth = 1
    shapeLayer.lineDashPattern = [4, 4]

    let path = CGMutablePath()
    path.addLines(between: [
      CGPoint(x: 0, y: 0),
      CGPoint(x: dividerView.bounds.width, y: 0)
    ])
    shapeLayer.path = path
    dividerView.layer.addSublayer(shapeLayer)
  }

  func configure(with store: MapPOIDetail) {
    nameLabel.styledText = store.name
    addressLabel.styledText = store.address

    if let phone = store.phone, !phone.isEmpty {
      phoneLabel.styledText = phone
      dividerView.isHidden = false
      phoneStackView.isHidden = false
    } else {
      phoneLabel.styledText = nil
      dividerView.isHidden = true
      phoneStackView.isHidden = true
    }
  }

  @objc private func didTapCloseButton() {
    onCloseButtonTapped?()
  }
}
