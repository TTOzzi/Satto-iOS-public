//
//  SearchViewController.swift
//  FeatureLayer
//
//  Created by 최재혁 on 12/28/25.
//

import Base
import Combine
import DesignSystem
import Foundation
import UIKit

public final class SearchViewController: BaseViewController {

  enum Constant {
    static let searchViewPlaceHolder = "우리 지역 명소 찾기"
  }

  private let viewModel: SearchViewModel

  private var searchViewArea = UIView()
  private var resultViewArea = UIView()

  private lazy var searchView = InputSearch().then {
    $0.setPlaceholder(Constant.searchViewPlaceHolder)
    $0.delegate = self
  }

  private lazy var searchImageView = UIImageView().then {
    $0.image = STImages.imageMoreLuckInfo.image
    $0.contentMode = .center
  }

  private lazy var searchTitle = UILabel().then {
    $0.style = Typography.Body_16_SB
    $0.textColor = STColors.gray4.color
  }

  private lazy var searchSubTitle = UILabel().then {
    $0.style = Typography.Body_14_R
    $0.textColor = STColors.gray4.color
    $0.numberOfLines = 2
  }

  private lazy var collectionView = UICollectionView(
    frame: .zero, collectionViewLayout: createLayout()
  ).then {
    $0.dataSource = self
    $0.register(
      SearchResultCell.self,
      forCellWithReuseIdentifier: SearchResultCell.typeName
    )
  }

  public init(viewModel: SearchViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    setNavigationBarHidden(true)
    setupUI()
    setupBinding()
    viewModel.send(input: .viewDidLoad)
  }
}

extension SearchViewController {
  private func setupUI() {
    view.backgroundColor = .systemBackground

    view.addSubview(searchViewArea)
    view.addSubview(resultViewArea)
    searchViewArea.addSubview(searchView)
    resultViewArea.addSubview(searchImageView)
    resultViewArea.addSubview(searchTitle)
    resultViewArea.addSubview(searchSubTitle)
    resultViewArea.addSubview(collectionView)

    searchViewArea.snp.makeConstraints { make in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      make.height.equalTo(56)
    }

    searchView.snp.makeConstraints { make in
      make.leading.trailing.equalToSuperview().inset(16)
      make.centerY.equalToSuperview()
      make.height.equalTo(43)
    }

    resultViewArea.snp.makeConstraints { make in
      make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      make.bottom.equalToSuperview()
      make.top.equalTo(searchViewArea.snp.bottom)
    }

    searchImageView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalToSuperview().offset(180)
      make.width.height.equalTo(100)
    }

    searchTitle.snp.makeConstraints { make in
      make.top.equalTo(searchImageView.snp.bottom)
      make.centerX.equalToSuperview()
    }

    searchSubTitle.snp.makeConstraints { make in
      make.top.equalTo(searchTitle.snp.bottom).offset(8)
      make.centerX.equalToSuperview()
    }

    collectionView.snp.makeConstraints { make in
      make.top.leading.trailing.bottom.equalToSuperview()
    }
  }

  private func setupBinding() {
    viewModel.output.isLoading
      .receive(on: RunLoop.main)
      .sink { [weak self] isLoading in
        guard let self else { return }
        if isLoading {
          self.showLoading()
        } else {
          self.hideLoading()
        }
      }
      .store(in: &cancellables)

    viewModel.output.showError
      .receive(on: RunLoop.main)
      .sink { [weak self] error in
        guard let self else { return }
        self.showErrorPopup {}
      }
      .store(in: &cancellables)

    viewModel.output.changeBasicView
      .receive(on: RunLoop.main)
      .sink { [weak self] emptyCase in
        guard let self else { return }
        if emptyCase == .filled {
          setBasicViewIsHidden(true)
          return
        }

        self.searchTitle.text = emptyCase.title
        self.searchSubTitle.text = emptyCase.subTitle
        setBasicViewIsHidden(false)
      }
      .store(in: &cancellables)

    viewModel.output.reloadData
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        guard let self else { return }
        self.collectionView.reloadData()
      }
      .store(in: &cancellables)

  }

  private func setBasicViewIsHidden(_ isHidden: Bool) {
    self.searchTitle.isHidden = isHidden
    self.searchSubTitle.isHidden = isHidden
    self.searchImageView.isHidden = isHidden
    self.collectionView.isHidden = !isHidden
  }

  private func createLayout() -> UICollectionViewCompositionalLayout {
    let layout = UICollectionViewCompositionalLayout { section, env in
      let item = NSCollectionLayoutItem(
        layoutSize: NSCollectionLayoutSize(
          widthDimension: .fractionalWidth(1.0),
          heightDimension: .estimated(78)
        )
      )

      let group = NSCollectionLayoutGroup.vertical(
        layoutSize: NSCollectionLayoutSize(
          widthDimension: .fractionalWidth(1.0),
          heightDimension: .estimated(78)
        ),
        subitems: [item]
      )

      let sectionLayout = NSCollectionLayoutSection(group: group)
      return sectionLayout
    }

    return layout
  }
}

extension SearchViewController: UICollectionViewDataSource {
  public func collectionView(
    _ collectionView: UICollectionView, numberOfItemsInSection section: Int
  ) -> Int {
    return viewModel.getSectionCount()
  }

  public func collectionView(
    _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    guard
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: SearchResultCell.typeName,
        for: indexPath
      ) as? SearchResultCell, let section = viewModel.getSection(at: indexPath.item)
    else {
      return UICollectionViewCell()
    }

    cell.delegate = self

    cell.update(with: section)
    return cell
  }
}

extension SearchViewController: SearchResultCellDelegate {
  func searchResultCell(_ id: String) {
    viewModel.send(input: .selectPlace(id: id))
  }
}

extension SearchViewController: InputSearchDelegate {
  public func inputSearchDidChange(_ inputSearch: InputSearch, text: String) {
    self.viewModel.send(input: .searchPlace(query: text))
  }
}

#if targetEnvironment(simulator)
  @available(iOS 17.0, *)
  #Preview {
    let viewModel = SearchViewModel()
    let searchViewController = SearchViewController(viewModel: viewModel)

    return searchViewController
  }
#endif
