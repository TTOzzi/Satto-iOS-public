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
  private var markers: [NMFMarker] = []
  private var lottoMarker: LottoMarker?
  private var atmMarker: ATMMarker?
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
      $0.edges.equalTo(view.safeAreaLayoutGuide)
    }
    
    view.addSubview(myLocationButton)
    myLocationButton.snp.makeConstraints {
      $0.width.height.equalTo(48)
      $0.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
      $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
    }
    
    let cameraPosition = NMFCameraPosition(
      NMGLatLng(lat: Constant.defaultLatitude, lng: Constant.defaultLongitude),
      zoom: Constant.defaultZoom
    )
    mapView.moveCamera(NMFCameraUpdate(position: cameraPosition))

    addSampleMarkers()
  }

  private func addSampleMarkers() {
    // Lotto marker
    let lotto = LottoMarker()
    lotto.position = NMGLatLng(lat: Constant.defaultLatitude + 0.002, lng: Constant.defaultLongitude - 0.002)
    lotto.captionText = "복권 판매점"
    lotto.touchHandler = { [weak self] _ in
      self?.selectMarker(type: .lotto)
      return true
    }
    lotto.mapView = mapView
    lottoMarker = lotto

    // ATM marker
    let atm = ATMMarker()
    atm.position = NMGLatLng(lat: Constant.defaultLatitude - 0.002, lng: Constant.defaultLongitude + 0.002)
    atm.captionText = "ATM"
    atm.touchHandler = { [weak self] _ in
      self?.selectMarker(type: .atm)
      return true
    }
    atm.mapView = mapView
    atmMarker = atm
  }

  private enum MarkerType {
    case lotto
    case atm
  }

  private func selectMarker(type: MarkerType) {
    lottoMarker?.isSelected = (type == .lotto)
    atmMarker?.isSelected = (type == .atm)
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

    viewModel.output.places
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.updateMapAnnotations()
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
  }
  
  private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
      // 권한 승인 - 위치 모드 활성화
      mapView.positionMode = .direction
      updateMyLocationButtonAppearance(for: mapView.positionMode)
    default:
      break
    }
  }
  
  private func handleLocationUpdate(_ location: CLLocation) {
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

  private func updateMapAnnotations() {
    markers.forEach { $0.mapView = nil }
    markers.removeAll()
    
    let places = viewModel.output.places.value
    
    for place in places {
      let marker = NMFMarker()
      marker.position = NMGLatLng(lat: place.latitude, lng: place.longitude)
      marker.captionText = place.name
      marker.iconTintColor = STColors.primary1.color
      marker.mapView = mapView
      
      marker.touchHandler = { [weak self] (overlay) -> Bool in
        self?.viewModel.send(input: .placeTapped(place: place))
        
        let cameraPosition = NMFCameraPosition(
          NMGLatLng(lat: place.latitude, lng: place.longitude),
          zoom: 17.0
        )
        let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
        cameraUpdate.animation = .easeIn
        self?.mapView.moveCamera(cameraUpdate)
        
        return true
      }
      
      markers.append(marker)
    }
    
    if let firstPlace = places.first {
      let cameraPosition = NMFCameraPosition(
        NMGLatLng(lat: firstPlace.latitude, lng: firstPlace.longitude),
        zoom: Constant.defaultZoom
      )
      let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
      cameraUpdate.animation = .easeIn
      mapView.moveCamera(cameraUpdate)
    }
  }
}

@available(iOS 17.0, *)
#Preview {
  MapViewController(viewModel: MapViewModel())
}

