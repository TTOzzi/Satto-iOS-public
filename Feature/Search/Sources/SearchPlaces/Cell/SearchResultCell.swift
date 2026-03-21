//
//  SearchResultCell.swift
//  FeatureLayer
//
//  Created by 최재혁 on 1/13/26.
//

import Base
import DesignSystem
import Foundation
import SnapKit
import Then
import UIKit

struct SearchResultCellModel {
  let id: String
  let title: String
  let address: String
  let isMatched: Bool
}

protocol SearchResultCellDelegate: AnyObject {
  func searchResultCell(_ placeId: String)
}

final class SearchResultCell: BaseCollectionViewCell {

  weak var delegate: SearchResultCellDelegate?

  private var model: SearchResultCellModel?

  private lazy var contentStackView = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 0
    $0.alignment = .center
    $0.isLayoutMarginsRelativeArrangement = true
    $0.layoutMargins = UIEdgeInsets(top: 16, left: 24, bottom: 16, right: 24)
  }

  private lazy var cellTouchButton = UIButton().then {
    $0.addTarget(self, action: #selector(cellTapped), for: .touchUpInside)
  }

  private lazy var imageBackgroundView = UIView().then {
    $0.backgroundColor = STColors.primary8.color
    $0.layer.cornerRadius = 16
  }

  private lazy var pinImageView = UIImageView().then {
    $0.image = STImages.mapPin.image.withRenderingMode(.alwaysTemplate)
    $0.contentMode = .scaleAspectFit
    $0.tintColor = STColors.primary2.color
  }

  private lazy var textStackView = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 4
    $0.alignment = .leading
  }

  private lazy var titleLabel = UILabel().then {
    $0.style = Typography.Body_16_SB
    $0.textColor = STColors.gray1.color
  }

  private lazy var descriptionLabel = UILabel().then {
    $0.style = Typography.Caption_12_M
    $0.textColor = STColors.gray3.color
  }

  private lazy var chevronImageView = UIImageView().then {
    $0.image = STImages.chevronRightM.image
    $0.contentMode = .scaleAspectFit
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension SearchResultCell {
  private func setupUI() {
    backgroundColor = .clear
    contentView.layer.borderWidth = 1
    contentView.layer.borderColor = STColors.gray8.color.cgColor
    contentView.clipsToBounds = true

    contentView.addSubview(contentStackView)
    contentView.addSubview(cellTouchButton)
    contentStackView.addArrangedSubview(imageBackgroundView)
    contentStackView.addArrangedSubview(textStackView)
    contentStackView.addArrangedSubview(chevronImageView)
    imageBackgroundView.addSubview(pinImageView)
    textStackView.addArrangedSubview(titleLabel)
    textStackView.addArrangedSubview(descriptionLabel)

    cellTouchButton.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }

    contentStackView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }

    imageBackgroundView.snp.makeConstraints {
      $0.width.height.equalTo(32)
      $0.centerY.equalToSuperview()
    }

    pinImageView.snp.makeConstraints {
      $0.center.equalToSuperview()
      $0.width.height.equalTo(16)
    }

    contentStackView.setCustomSpacing(16, after: imageBackgroundView)

    textStackView.snp.makeConstraints {
      $0.centerY.equalToSuperview()
    }

    contentStackView.setCustomSpacing(16, after: textStackView)

    chevronImageView.snp.makeConstraints {
      $0.width.height.equalTo(24)
    }

    textStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    chevronImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
  }

  func update(with cellModel: SearchResultCellModel) {
    titleLabel.text = cellModel.title
    descriptionLabel.text = cellModel.address
    model = cellModel

    if cellModel.isMatched {
      titleLabel.textColor = STColors.primary2.color
    } else {
      titleLabel.textColor = STColors.gray1.color
    }
  }

  @objc private func cellTapped() {
    if let model = model {
      delegate?.searchResultCell(model.id)
    }
  }
}

@available(iOS 17.0, *)
#Preview {
  let cellModel = SearchResultCellModel(
    id: "1",
    title: "서울숲",
    address: "서울 성동구 뚝섬로 273 (성수동1가)",
    isMatched: true
  )

  let cell = SearchResultCell()
  cell.update(with: cellModel)

  return cell
}
