//
//  MapFilterChipButton.swift
//  Map
//
//  Created by ttozzi on 2/15/26.
//

import DesignSystem
import SnapKit
import Then
import UIKit

final class MapFilterChipButton: UIControl {

  enum Kind {
    case lottoStore
    case atm

    var title: String {
      switch self {
      case .lottoStore:
        return "로또 판매점"
      case .atm:
        return "ATM"
      }
    }

    var iconName: String {
      switch self {
      case .lottoStore:
        return "storefront.fill"
      case .atm:
        return "banknote.fill"
      }
    }

    var selectedBackgroundColor: UIColor {
      switch self {
      case .lottoStore:
        return STColors.red3.color
      case .atm:
        return STColors.green3.color
      }
    }

    var iconTintColor: UIColor {
      switch self {
      case .lottoStore:
        return STColors.red3.color
      case .atm:
        return STColors.green3.color
      }
    }
  }

  var isChipSelected: Bool = false {
    didSet {
      updateAppearance()
    }
  }

  private let kind: Kind
  private let contentStackView = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.alignment = .center
  }
  private let iconImageView = UIImageView().then {
    $0.contentMode = .scaleAspectFit
    $0.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
  }
  private let titleLabel = UILabel().then {
    $0.style = Typography.Body_14_SB
  }

  init(kind: Kind) {
    self.kind = kind
    super.init(frame: .zero)
    setupUI()
    updateAppearance()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    // UIControl이 터치를 일관되게 받도록 내부 서브뷰 터치를 비활성화한다.
    contentStackView.isUserInteractionEnabled = false
    iconImageView.isUserInteractionEnabled = false
    titleLabel.isUserInteractionEnabled = false

    addSubview(contentStackView)
    contentStackView.snp.makeConstraints {
      $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10))
    }

    contentStackView.addArrangedSubview(iconImageView)
    contentStackView.addArrangedSubview(titleLabel)

    iconImageView.snp.makeConstraints {
      $0.width.height.equalTo(16)
    }
    iconImageView.image = UIImage(systemName: kind.iconName)

    titleLabel.styledText = kind.title

    layer.cornerRadius = 14
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.1
    layer.shadowRadius = 6
    layer.shadowOffset = CGSize(width: 0, height: 2)
  }

  override var intrinsicContentSize: CGSize {
    let labelSize = titleLabel.intrinsicContentSize
    let width = 10 + 16 + 4 + labelSize.width + 10
    return CGSize(width: ceil(width), height: 28)
  }

  private func updateAppearance() {
    backgroundColor = isChipSelected ? kind.selectedBackgroundColor : STColors.white.color
    titleLabel.textColor = isChipSelected ? STColors.white.color : STColors.gray1.color
    iconImageView.tintColor = isChipSelected ? STColors.white.color : kind.iconTintColor
  }
}
