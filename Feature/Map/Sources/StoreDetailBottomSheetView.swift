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
    $0.font = .systemFont(ofSize: 18, weight: .bold)
    $0.textColor = .black
  }

  private lazy var closeButton = UIButton(type: .system).then {
    $0.setImage(STImages.xMark.image.withRenderingMode(.alwaysTemplate), for: .normal)
    $0.tintColor = STColors.gray5.color
    $0.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
  }

  private let addressIconView = UIImageView().then {
    $0.image = UIImage(systemName: "location.fill")
    $0.tintColor = STColors.primary1.color
    $0.contentMode = .scaleAspectFit
  }

  private let addressLabel = UILabel().then {
    $0.font = .systemFont(ofSize: 14, weight: .regular)
    $0.textColor = .black
    $0.numberOfLines = 0
  }

  private let phoneIconView = UIImageView().then {
    $0.image = UIImage(systemName: "phone.fill")
    $0.tintColor = STColors.primary1.color
    $0.contentMode = .scaleAspectFit
  }

  private let phoneLabel = UILabel().then {
    $0.font = .systemFont(ofSize: 14, weight: .regular)
    $0.textColor = .black
  }

  private let phoneStackView = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 8
    $0.alignment = .center
  }

  private let contentContainerView = UIView().then {
    $0.layer.borderColor = STColors.gray3.color.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 8
  }

  private let dividerView = UIView().then {
    $0.backgroundColor = .clear
  }

  private let phoneContainerView = UIView()

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

    containerView.addSubview(nameLabel)
    nameLabel.snp.makeConstraints {
      $0.top.equalToSuperview().offset(20)
      $0.leading.equalToSuperview().offset(20)
    }

    containerView.addSubview(closeButton)
    closeButton.snp.makeConstraints {
      $0.centerY.equalTo(nameLabel)
      $0.trailing.equalToSuperview().inset(20)
      $0.leading.greaterThanOrEqualTo(nameLabel.snp.trailing).offset(12)
      $0.width.height.equalTo(24)
    }

    let addressStackView = UIStackView(arrangedSubviews: [addressIconView, addressLabel])
    addressStackView.axis = .horizontal
    addressStackView.spacing = 8
    addressStackView.alignment = .center

    addressIconView.snp.makeConstraints {
      $0.width.height.equalTo(18)
    }

    phoneStackView.addArrangedSubview(phoneIconView)
    phoneStackView.addArrangedSubview(phoneLabel)

    phoneIconView.snp.makeConstraints {
      $0.width.height.equalTo(18)
    }

    let addressContainerView = UIView()
    addressContainerView.addSubview(addressStackView)
    addressStackView.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview().inset(16)
      $0.top.bottom.equalToSuperview().inset(14)
    }

    phoneContainerView.addSubview(phoneStackView)
    phoneStackView.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview().inset(16)
      $0.top.bottom.equalToSuperview().inset(14)
    }

    contentStackView.addArrangedSubview(addressContainerView)
    contentStackView.addArrangedSubview(dividerView)
    contentStackView.addArrangedSubview(phoneContainerView)

    dividerView.snp.makeConstraints {
      $0.height.equalTo(1)
    }

    containerView.addSubview(contentContainerView)
    contentContainerView.snp.makeConstraints {
      $0.top.equalTo(nameLabel.snp.bottom).offset(16)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalToSuperview().inset(20)
    }

    contentContainerView.addSubview(contentStackView)
    contentStackView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    updateDividerDash()
  }

  private func updateDividerDash() {
    dividerView.layer.sublayers?.removeAll(where: { $0 is CAShapeLayer })

    let shapeLayer = CAShapeLayer()
    shapeLayer.strokeColor = STColors.gray3.color.cgColor
    shapeLayer.lineWidth = 1
    shapeLayer.lineDashPattern = [4, 4]

    let path = CGMutablePath()
    path.addLines(between: [
      CGPoint(x: 16, y: 0),
      CGPoint(x: dividerView.bounds.width - 16, y: 0)
    ])
    shapeLayer.path = path
    dividerView.layer.addSublayer(shapeLayer)
  }

  func configure(with store: MapPOIDetail) {
    nameLabel.text = store.name
    addressLabel.text = store.address

    if let phone = store.phone, !phone.isEmpty {
      phoneLabel.text = phone
      dividerView.isHidden = false
      phoneContainerView.isHidden = false
    } else {
      dividerView.isHidden = true
      phoneContainerView.isHidden = true
    }
  }

  @objc private func didTapCloseButton() {
    onCloseButtonTapped?()
  }
}
