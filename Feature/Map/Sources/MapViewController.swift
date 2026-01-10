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
    static let defaultLatitude: Double = 37.5665 // 서울 기본 좌표
    static let defaultLongitude: Double = 126.9780
    static let defaultZoom: Double = 15.0
  }

  private lazy var naverMapView = NMFNaverMapView().then {
    $0.showLocationButton = true
    $0.showZoomControls = true
    $0.showCompass = true
    $0.showScaleBar = true
  }
  
  private var mapView: NMFMapView {
    return naverMapView.mapView
  }
  
  private var markers: [NMFMarker] = []

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
    setupBinding()
    viewModel.send(input: .viewDidLoad)
  }

  private func setupUI() {
    title = "명소"
    view.backgroundColor = STColors.white.color

    view.addSubview(naverMapView)
    naverMapView.snp.makeConstraints {
      $0.edges.equalTo(view.safeAreaLayoutGuide)
    }
    
    // 초기 카메라 위치 설정
    let cameraPosition = NMFCameraPosition(
      NMGLatLng(lat: Constant.defaultLatitude, lng: Constant.defaultLongitude),
      zoom: Constant.defaultZoom
    )
    mapView.moveCamera(NMFCameraUpdate(position: cameraPosition))
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
  }

  private func updateMapAnnotations() {
    // 기존 마커 제거
    markers.forEach { $0.mapView = nil }
    markers.removeAll()
    
    // 새로운 마커 추가
    let places = viewModel.output.places.value
    
    for place in places {
      let marker = NMFMarker()
      marker.position = NMGLatLng(lat: place.latitude, lng: place.longitude)
      marker.captionText = place.name
      marker.iconTintColor = STColors.primary1.color
      marker.mapView = mapView
      
      // 마커 탭 이벤트
      marker.touchHandler = { [weak self] (overlay) -> Bool in
        self?.viewModel.send(input: .placeTapped(place: place))
        
        // 마커 선택 시 해당 위치로 카메라 이동
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
    
    // 첫 번째 장소로 카메라 이동
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
