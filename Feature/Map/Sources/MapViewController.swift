//
//  MapViewController.swift
//  Map
//
//  Created by ttozzi on 1/11/26.
//

import Base
import Combine
import DesignSystem
import NMapsMap
import SnapKit
import Then
import UIKit

public final class MapViewController: BaseViewController {

  private enum Constant {
    static let defaultLatitude: Double = 37.5665
    static let defaultLongitude: Double = 126.9780
    static let defaultZoom: Double = 15.0
    static let markerLabelHideThreshold: Int = 10
  }

  private lazy var naverMapView = NMFNaverMapView().then {
    $0.showLocationButton = false
    $0.showZoomControls = false
    $0.showCompass = false
    $0.showScaleBar = false
  }
  private var mapView: NMFMapView {
    return naverMapView.mapView
  }
  private lazy var filterStackView = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 8
    $0.alignment = .center
  }
  private lazy var lottoFilterButton = MapFilterChipButton(kind: .lottoStore).then {
    $0.addTarget(self, action: #selector(didTapLottoFilterButton), for: .touchUpInside)
  }
  private lazy var atmFilterButton = MapFilterChipButton(kind: .atm).then {
    $0.addTarget(self, action: #selector(didTapATMFilterButton), for: .touchUpInside)
  }
  private var selectedPOI: MapPOI?
  private var selectedFilter: MapPOIFilter = .all
  private var nextCameraMoveReason: CameraMoveReason = .initial
  private lazy var markerRenderer = MapMarkerRenderer(
    mapView: mapView,
    markerLabelHideThreshold: Constant.markerLabelHideThreshold
  ) { [weak self] poi in
    self?.viewModel.send(input: .poiTapped(poi: poi))
  }
  private let bottomSheetAnimator = BottomSheetAnimator()
  private lazy var searchButton = UIButton(type: .system).then {
    $0.setTitle("현 지도에서 검색", for: .normal)
    $0.setTitleColor(STColors.primary1.color, for: .normal)
    $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
    $0.backgroundColor = .white
    $0.layer.cornerRadius = 16
    $0.layer.shadowColor = UIColor.black.cgColor
    $0.layer.shadowOpacity = 0.1
    $0.layer.shadowRadius = 6
    $0.layer.shadowOffset = CGSize(width: 0, height: 2)
    $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    $0.isHidden = true
    $0.alpha = 0
    $0.addTarget(self, action: #selector(didTapSearchButton), for: .touchUpInside)
  }
  private lazy var myLocationButton = UIButton(type: .system).then {
    $0.backgroundColor = .white
    $0.layer.cornerRadius = 24
    $0.layer.shadowColor = UIColor.black.cgColor
    $0.layer.shadowOpacity = 0.1
    $0.layer.shadowRadius = 6
    $0.layer.shadowOffset = CGSize(width: 0, height: 2)
    $0.tintColor = STColors.gray5.color
    $0.setImage(UIImage(systemName: "crosshair"), for: .normal)
    $0.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    $0.addTarget(self, action: #selector(didTapMyLocation), for: .touchUpInside)
    $0.accessibilityLabel = "현재 위치로 이동"
    $0.isHidden = true
  }
  private lazy var storeDetailBottomSheet = StoreDetailBottomSheetView().then {
    $0.isHidden = true
    $0.alpha = 0
    $0.onCloseButtonTapped = { [weak self] in
      self?.viewModel.send(input: .closeStoreDetail)
    }
  }
  private let viewModel: MapViewModel

  public init(viewModel: MapViewModel) {
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
    updateMyLocationButtonAppearance(for: mapView.positionMode)
    setupBinding()
    viewModel.send(input: .viewDidLoad)
  }

  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewModel.send(input: .viewDidAppear)
  }

  private func setupUI() {
    view.backgroundColor = STColors.white.color

    view.addSubview(naverMapView)
    naverMapView.snp.makeConstraints {
      $0.top.leading.trailing.equalToSuperview()
      $0.bottom.equalTo(view)
    }

    view.addSubview(filterStackView)
    filterStackView.snp.makeConstraints {
      $0.leading.equalTo(view.safeAreaLayoutGuide).inset(16)
      $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
    }
    filterStackView.addArrangedSubview(lottoFilterButton)
    filterStackView.addArrangedSubview(atmFilterButton)

    view.addSubview(searchButton)
    searchButton.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalTo(filterStackView.snp.bottom).offset(10)
    }

    view.addSubview(myLocationButton)
    myLocationButton.snp.makeConstraints {
      $0.width.height.equalTo(48)
      $0.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
      $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
    }

    view.addSubview(storeDetailBottomSheet)
    storeDetailBottomSheet.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview().inset(16)
      $0.bottom.equalToSuperview().inset(24)
    }

    let cameraPosition = NMFCameraPosition(
      NMGLatLng(lat: Constant.defaultLatitude, lng: Constant.defaultLongitude),
      zoom: Constant.defaultZoom
    )
    mapView.moveCamera(NMFCameraUpdate(position: cameraPosition))
    mapView.addCameraDelegate(delegate: self)
  }

  private func setupBinding() {
    viewModel.output.isLoading
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isLoading in
        if isLoading {
          self?.showLoading()
        } else {
          self?.hideLoading()
        }
      }
      .store(in: &cancellables)

    viewModel.output.lottoStores
      .receive(on: DispatchQueue.main)
      .sink { [weak self] stores in
        guard let self else { return }
        markerRenderer.updateLottoMarkers(stores: stores, selectedPOIUniqueId: selectedPOI?.uniqueId)
      }
      .store(in: &cancellables)

    viewModel.output.atmStores
      .receive(on: DispatchQueue.main)
      .sink { [weak self] stores in
        guard let self else { return }
        markerRenderer.updateATMMarkers(stores: stores, selectedPOIUniqueId: selectedPOI?.uniqueId)
      }
      .store(in: &cancellables)

    viewModel.output.showError
      .receive(on: DispatchQueue.main)
      .sink { [weak self] retryAction in
        guard let self else { return }
        self.showErrorPopup(action: retryAction)
      }
      .store(in: &cancellables)

    viewModel.output.locationAuthorizationStatus
      .receive(on: DispatchQueue.main)
      .sink { [weak self] status in
        self?.handleAuthorizationStatus(status)
      }
      .store(in: &cancellables)

    viewModel.output.currentLocation
      .compactMap { $0 }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] location in
        self?.handleLocationUpdate(location)
      }
      .store(in: &cancellables)

    viewModel.output.shouldShowLocationDeniedAlert
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        self?.showLocationPermissionDeniedAlert()
      }
      .store(in: &cancellables)

    viewModel.output.selectedPOI
      .receive(on: DispatchQueue.main)
      .sink { [weak self] poi in
        self?.handlePOISelected(poi: poi)
      }
      .store(in: &cancellables)

    viewModel.output.shouldShowSearchButton
      .receive(on: DispatchQueue.main)
      .sink { [weak self] shouldShow in
        self?.updateSearchButtonVisibility(shouldShow: shouldShow)
      }
      .store(in: &cancellables)

    viewModel.output.poiDetail
      .receive(on: DispatchQueue.main)
      .sink { [weak self] detail in
        self?.handlePOIDetailUpdate(detail: detail)
      }
      .store(in: &cancellables)

    viewModel.output.selectedFilter
      .receive(on: DispatchQueue.main)
      .sink { [weak self] filter in
        self?.applyFilterUI(filter: filter)
      }
      .store(in: &cancellables)
  }

  private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
    let isAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
    myLocationButton.isHidden = !isAuthorized

    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
      mapView.positionMode = .direction
      updateMyLocationButtonAppearance(for: mapView.positionMode)
    default:
      mapView.positionMode = .disabled
      updateMyLocationButtonAppearance(for: mapView.positionMode)
    }
  }

  private func handleLocationUpdate(_ location: CLLocation) {
    nextCameraMoveReason = .moveToCurrentLocation
    let cameraPosition = NMFCameraPosition(
      NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude),
      zoom: Constant.defaultZoom
    )
    let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
    cameraUpdate.animation = .easeIn
    mapView.moveCamera(cameraUpdate)
  }

  private func showLocationPermissionDeniedAlert() {
    let alert = UIAlertController(
      title: "위치 서비스 사용 권한 확인",
      message: "서비스 이용을 위해 위치 서비스 사용 설정이 필요합니다.\n기기 또는 시뮬레이터에서 위치 사용 권한을 켜주세요.",
      preferredStyle: .alert
    )

    let settingsAction = UIAlertAction(title: "설정", style: .default) { _ in
      if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(settingsURL)
      }
    }

    let cancelAction = UIAlertAction(title: "취소", style: .cancel)

    alert.addAction(cancelAction)
    alert.addAction(settingsAction)

    present(alert, animated: true)
  }

  private func nextPositionMode(from current: NMFMyPositionMode) -> NMFMyPositionMode {
    switch current {
    case .normal:
      return .direction
    case .direction:
      return .compass
    case .compass:
      return .disabled
    case .disabled:
      return .normal
    @unknown default:
      return .normal
    }
  }

  private func updateMyLocationButtonAppearance(for mode: NMFMyPositionMode) {
    switch mode {
    case .disabled:
      myLocationButton.setImage(STImages.crosshair.image, for: .normal)
      myLocationButton.tintColor = STColors.gray5.color
    case .normal:
      myLocationButton.setImage(STImages.crosshair.image, for: .normal)
      myLocationButton.tintColor = STColors.primary2.color
    case .direction, .compass:
      myLocationButton.setImage(STImages.crosshair2.image, for: .normal)
      myLocationButton.tintColor = STColors.primary2.color
    @unknown default:
      myLocationButton.setImage(STImages.crosshair.image, for: .normal)
      myLocationButton.tintColor = STColors.primary2.color
    }
  }

  @objc private func didTapMyLocation() {
    let newMode = nextPositionMode(from: mapView.positionMode)
    mapView.positionMode = newMode
    updateMyLocationButtonAppearance(for: newMode)
  }

  @objc private func didTapSearchButton() {
    viewModel.send(input: .searchButtonTapped)
  }

  @objc private func didTapLottoFilterButton() {
    let nextFilter: MapPOIFilter = selectedFilter == .lottoStore ? .all : .lottoStore
    viewModel.send(input: .filterChanged(filter: nextFilter))
  }

  @objc private func didTapATMFilterButton() {
    let nextFilter: MapPOIFilter = selectedFilter == .atm ? .all : .atm
    viewModel.send(input: .filterChanged(filter: nextFilter))
  }

  private func currentMapBounds() -> MapBounds {
    let bounds = mapView.contentBounds
    return MapBounds(
      minLat: bounds.southWestLat,
      maxLat: bounds.northEastLat,
      minLng: bounds.southWestLng,
      maxLng: bounds.northEastLng
    )
  }

  private func updateSearchButtonVisibility(shouldShow: Bool) {
    if shouldShow {
      searchButton.isHidden = false
      UIView.animate(withDuration: 0.25) {
        self.searchButton.alpha = 1
      }
    } else {
      UIView.animate(withDuration: 0.25) {
        self.searchButton.alpha = 0
      } completion: { _ in
        self.searchButton.isHidden = true
      }
    }
  }

  private func handlePOISelected(poi: MapPOI?) {
    markerRenderer.updateSelection(from: selectedPOI, to: poi)
    selectedPOI = poi
  }

  private func handlePOIDetailUpdate(detail: MapPOIDetail?) {
    if let detail = detail {
      storeDetailBottomSheet.configure(with: detail)
      showStoreDetailBottomSheet()
    } else {
      hideStoreDetailBottomSheet()
    }
  }

  private func applyFilterUI(filter: MapPOIFilter) {
    selectedFilter = filter
    lottoFilterButton.isChipSelected = filter == .lottoStore
    atmFilterButton.isChipSelected = filter == .atm
  }

  private func showStoreDetailBottomSheet() {
    myLocationButton.snp.remakeConstraints {
      $0.width.height.equalTo(48)
      $0.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
      $0.bottom.equalTo(storeDetailBottomSheet.snp.top).offset(-12)
    }

    bottomSheetAnimator.show(
      sheetView: storeDetailBottomSheet,
      in: view
    )

    if let tabBarController = tabBarController as? BaseTabBarController {
      tabBarController.customTabBar.isHidden = true
    }
  }

  private func hideStoreDetailBottomSheet() {
    if let tabBarController = tabBarController as? BaseTabBarController {
      tabBarController.customTabBar.isHidden = false
    }

    myLocationButton.snp.remakeConstraints {
      $0.width.height.equalTo(48)
      $0.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
      $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
    }

    bottomSheetAnimator.hide(
      sheetView: storeDetailBottomSheet,
      in: view
    )
  }
}

// MARK: - NMFMapViewCameraDelegate
extension MapViewController: NMFMapViewCameraDelegate {
  public func mapViewCameraIdle(_ mapView: NMFMapView) {
    let reason = nextCameraMoveReason
    nextCameraMoveReason = .userInteraction
    viewModel.send(input: .cameraIdle(bounds: currentMapBounds(), reason: reason))
  }
}

@available(iOS 17.0, *)
#Preview {
  @MainActor in
  MapViewController(viewModel: MapViewModel())
}
