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
  private var lottoMarkers: [String: LottoMarker] = [:]
  private var selectedStoreId: String?
  private var nextCameraMoveReason: CameraMoveReason = .initial
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
    title = "명소"
    view.backgroundColor = STColors.white.color

    view.addSubview(naverMapView)
    naverMapView.snp.makeConstraints {
      $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      $0.bottom.equalTo(view)
    }

    view.addSubview(searchButton)
    searchButton.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
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
        self?.updateLottoMarkers(stores: stores)
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

    viewModel.output.selectedStore
      .receive(on: DispatchQueue.main)
      .sink { [weak self] store in
        self?.handleStoreSelected(store: store)
      }
      .store(in: &cancellables)

    viewModel.output.shouldShowSearchButton
      .receive(on: DispatchQueue.main)
      .sink { [weak self] shouldShow in
        self?.updateSearchButtonVisibility(shouldShow: shouldShow)
      }
      .store(in: &cancellables)

    viewModel.output.storeDetail
      .receive(on: DispatchQueue.main)
      .sink { [weak self] detail in
        self?.handleStoreDetailUpdate(detail: detail)
      }
      .store(in: &cancellables)
  }

  private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
      mapView.positionMode = .direction
      updateMyLocationButtonAppearance(for: mapView.positionMode)
    default:
      break
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

  private func updateLottoMarkers(stores: [LottoStore]) {
    let newStoreIds = Set(stores.map { $0.id })
    let existingIds = Set(lottoMarkers.keys)

    // 삭제된 마커 제거
    let removedIds = existingIds.subtracting(newStoreIds)
    for id in removedIds {
      lottoMarkers[id]?.mapView = nil
      lottoMarkers.removeValue(forKey: id)
    }

    // 새로운 마커 추가
    for store in stores {
      if lottoMarkers[store.id] == nil {
        let marker = LottoMarker()
        marker.position = NMGLatLng(lat: store.latitude, lng: store.longitude)
        marker.captionText = store.name
        marker.touchHandler = { [weak self] _ in
          self?.viewModel.send(input: .storeTapped(store: store))
          return true
        }
        marker.mapView = mapView
        lottoMarkers[store.id] = marker
      }
    }
  }

  private func handleStoreSelected(store: LottoStore?) {
    // 이전 선택 해제
    if let previousId = selectedStoreId, let previousMarker = lottoMarkers[previousId] {
      previousMarker.isSelected = false
    }

    // 새로운 선택
    if let store = store, let marker = lottoMarkers[store.id] {
      marker.isSelected = true
      selectedStoreId = store.id
    } else {
      selectedStoreId = nil
    }
  }

  private func handleStoreDetailUpdate(detail: LottoStoreDetail?) {
    if let detail = detail {
      storeDetailBottomSheet.configure(with: detail)
      showStoreDetailBottomSheet()
    } else {
      hideStoreDetailBottomSheet()
    }
  }

  private func showStoreDetailBottomSheet() {
    storeDetailBottomSheet.isHidden = false
    storeDetailBottomSheet.transform = CGAffineTransform(translationX: 0, y: 200)

    myLocationButton.snp.remakeConstraints {
      $0.width.height.equalTo(48)
      $0.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
      $0.bottom.equalTo(storeDetailBottomSheet.snp.top).offset(-12)
    }

    UIView.animate(withDuration: 0.25) {
      self.storeDetailBottomSheet.alpha = 1
      self.storeDetailBottomSheet.transform = .identity
      self.view.layoutIfNeeded()
    }

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

    UIView.animate(withDuration: 0.25) {
      self.storeDetailBottomSheet.alpha = 0
      self.storeDetailBottomSheet.transform = CGAffineTransform(translationX: 0, y: 200)
      self.view.layoutIfNeeded()
    } completion: { _ in
      self.storeDetailBottomSheet.isHidden = true
    }
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
  MapViewController(viewModel: MapViewModel())
}
