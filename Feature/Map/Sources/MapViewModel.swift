//
//  MapViewModel.swift
//  Map
//
//  Created by ttozzi on 1/11/26.
//

import Combine
import CoreLocation
import DIInjector
import Foundation

public struct MapBounds {
  let minLat: Double
  let maxLat: Double
  let minLng: Double
  let maxLng: Double

  public init(minLat: Double, maxLat: Double, minLng: Double, maxLng: Double) {
    self.minLat = minLat
    self.maxLat = maxLat
    self.minLng = minLng
    self.maxLng = maxLng
  }
}

public enum CameraMoveReason {
  case initial
  case userInteraction
  case moveToCurrentLocation
}

public final class MapViewModel {

  enum Input {
    case viewDidLoad
    case viewDidAppear
    case cameraIdle(bounds: MapBounds, reason: CameraMoveReason)
    case searchButtonTapped
    case storeTapped(store: LottoStore)
    case closeStoreDetail
  }

  struct Output {
    let lottoStores = CurrentValueSubject<[LottoStore], Never>([])
    let isLoading = PassthroughSubject<Bool, Never>()
    let showError = PassthroughSubject<() -> Void, Never>()
    let locationAuthorizationStatus = PassthroughSubject<CLAuthorizationStatus, Never>()
    let currentLocation = PassthroughSubject<CLLocation?, Never>()
    let shouldShowLocationDeniedAlert = PassthroughSubject<Void, Never>()
    let selectedStore = PassthroughSubject<LottoStore?, Never>()
    let shouldShowSearchButton = CurrentValueSubject<Bool, Never>(false)
    let storeDetail = PassthroughSubject<LottoStoreDetail?, Never>()
  }

  @Injected var locationService: LocationService
  @Injected var mapService: MapService

  let output = Output()
  private var cancellables = Set<AnyCancellable>()
  private var currentBounds: MapBounds?
  private var hasInitiallyLoaded = false
  private var selectedStoreId: String?

  public init() {
    setupLocationBinding()
  }

  func send(input: Input) {
    switch input {
    case .viewDidLoad:
      break

    case .viewDidAppear:
      handleViewDidAppear()

    case .cameraIdle(let bounds, let reason):
      handleCameraIdle(bounds: bounds, reason: reason)

    case .searchButtonTapped:
      handleSearchButtonTapped()

    case .storeTapped(let store):
      handleStoreTapped(store: store)

    case .closeStoreDetail:
      handleCloseStoreDetail()
    }
  }

  private func setupLocationBinding() {
    locationService.authorizationStatus
      .sink { [weak self] status in
        self?.output.locationAuthorizationStatus.send(status)
        self?.handleAuthorizationStatus(status)
      }
      .store(in: &cancellables)

    locationService.currentLocation
      .sink { [weak self] location in
        self?.output.currentLocation.send(location)

        if location != nil {
          self?.locationService.stopUpdatingLocation()
        }
      }
      .store(in: &cancellables)

    locationService.locationError
      .sink { error in
        // TODO: 에러
      }
      .store(in: &cancellables)
  }

  private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
    switch status {
    case .restricted, .denied:
      output.shouldShowLocationDeniedAlert.send(())
    case .authorizedWhenInUse, .authorizedAlways:
      break
    case .notDetermined:
      break
    @unknown default:
      break
    }
  }

  private func handleViewDidAppear() {
    locationService.requestAuthorization()
  }

  private func handleCameraIdle(bounds: MapBounds, reason: CameraMoveReason) {
    currentBounds = bounds

    switch reason {
    case .initial:
      // 최초 진입 시 자동 조회
      if !hasInitiallyLoaded {
        fetchLottoStores(bounds: bounds)
        hasInitiallyLoaded = true
      }

    case .userInteraction:
      // 사용자 지도 이동 시 버튼 표시
      if hasInitiallyLoaded {
        output.shouldShowSearchButton.send(true)
      }

    case .moveToCurrentLocation:
      // 현재 위치로 이동 시 무시
      break
    }
  }

  private func handleSearchButtonTapped() {
    guard let bounds = currentBounds else { return }
    output.shouldShowSearchButton.send(false)
    fetchLottoStores(bounds: bounds)
  }

  private func handleStoreTapped(store: LottoStore) {
    guard selectedStoreId != store.id else { return }
    selectedStoreId = store.id
    output.selectedStore.send(store)
    fetchStoreDetail(storeId: store.id)
  }

  private func handleCloseStoreDetail() {
    selectedStoreId = nil
    output.selectedStore.send(nil)
    output.storeDetail.send(nil)
  }

  private func fetchStoreDetail(storeId: String) {
    output.isLoading.send(true)
    Task {
      do {
        let detail = try await mapService.fetchStoreDetail(storeId: storeId)
        output.storeDetail.send(detail)
        output.isLoading.send(false)
      } catch {
        output.isLoading.send(false)
        output.showError.send { [weak self] in
          self?.fetchStoreDetail(storeId: storeId)
        }
      }
    }
  }

  private func fetchLottoStores(bounds: MapBounds) {
    output.isLoading.send(true)
    Task {
      do {
        let stores = try await mapService.fetchLottoStores(
          minLat: bounds.minLat,
          maxLat: bounds.maxLat,
          minLng: bounds.minLng,
          maxLng: bounds.maxLng
        )
        output.lottoStores.send(stores)
        output.isLoading.send(false)
      } catch {
        output.isLoading.send(false)
        output.showError.send { [weak self] in
          guard let self, let bounds = self.currentBounds else { return }
          self.fetchLottoStores(bounds: bounds)
        }
      }
    }
  }
}
