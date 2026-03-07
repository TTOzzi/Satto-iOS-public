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
    case poiTapped(poi: MapPOI)
    case filterChanged(filter: MapPOIFilter)
    case closeStoreDetail
  }

  struct Output {
    let lottoStores = CurrentValueSubject<[MapPOI], Never>([])
    let atmStores = CurrentValueSubject<[MapPOI], Never>([])
    let isLoading = PassthroughSubject<Bool, Never>()
    let showError = PassthroughSubject<() -> Void, Never>()
    let locationAuthorizationStatus = PassthroughSubject<CLAuthorizationStatus, Never>()
    let currentLocation = PassthroughSubject<CLLocation?, Never>()
    let shouldShowLocationDeniedAlert = PassthroughSubject<Void, Never>()
    let selectedPOI = PassthroughSubject<MapPOI?, Never>()
    let shouldShowSearchButton = CurrentValueSubject<Bool, Never>(false)
    let poiDetail = PassthroughSubject<MapPOIDetail?, Never>()
    let selectedFilter = CurrentValueSubject<MapPOIFilter, Never>(.all)
  }

  @Injected var locationService: LocationService
  @Injected var mapService: MapService

  let output = Output()
  private var cancellables = Set<AnyCancellable>()
  private var currentBounds: MapBounds?
  private var hasInitiallyLoaded = false
  private var selectedPOIUniqueId: String?
  private var currentFilter: MapPOIFilter = .all
  private var poiFetchTask: Task<Void, Never>?
  private var poiDetailFetchTask: Task<Void, Never>?

  public init() {
    setupLocationBinding()
  }

  deinit {
    poiFetchTask?.cancel()
    poiDetailFetchTask?.cancel()
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

    case .poiTapped(let poi):
      handlePOITapped(poi: poi)

    case .filterChanged(let filter):
      handleFilterChanged(filter: filter)

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
        fetchPOIs(bounds: bounds)
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
    fetchPOIs(bounds: bounds)
  }

  private func handlePOITapped(poi: MapPOI) {
    guard selectedPOIUniqueId != poi.uniqueId else { return }
    selectedPOIUniqueId = poi.uniqueId
    output.selectedPOI.send(poi)
    fetchPOIDetail(poi: poi)
  }

  private func handleFilterChanged(filter: MapPOIFilter) {
    guard currentFilter != filter else { return }

    currentFilter = filter
    output.selectedFilter.send(filter)
    handleCloseStoreDetail()
    output.shouldShowSearchButton.send(false)

    guard let bounds = currentBounds else { return }
    fetchPOIs(bounds: bounds)
  }

  private func handleCloseStoreDetail() {
    poiDetailFetchTask?.cancel()
    selectedPOIUniqueId = nil
    output.selectedPOI.send(nil)
    output.poiDetail.send(nil)
    output.isLoading.send(false)
  }

  private func fetchPOIDetail(poi: MapPOI) {
    poiDetailFetchTask?.cancel()
    output.isLoading.send(true)
    poiDetailFetchTask = Task { [weak self] in
      guard let self else { return }
      do {
        let detail = try await mapService.fetchPOIDetail(poi: poi)
        guard !Task.isCancelled else { return }
        output.poiDetail.send(detail)
        output.isLoading.send(false)
      } catch {
        guard !Task.isCancelled else { return }
        output.isLoading.send(false)
        output.showError.send { [weak self] in
          self?.fetchPOIDetail(poi: poi)
        }
      }
    }
  }

  private func fetchPOIs(bounds: MapBounds) {
    poiFetchTask?.cancel()
    output.isLoading.send(true)
    poiFetchTask = Task { [weak self] in
      guard let self else { return }
      do {
        let result = try await mapService.fetchPOIs(
          minLat: bounds.minLat,
          maxLat: bounds.maxLat,
          minLng: bounds.minLng,
          maxLng: bounds.maxLng,
          filter: currentFilter
        )
        guard !Task.isCancelled else { return }
        output.lottoStores.send(result.lottoStores)
        output.atmStores.send(result.atms)
        output.isLoading.send(false)
      } catch {
        guard !Task.isCancelled else { return }
        output.isLoading.send(false)
        output.showError.send { [weak self] in
          guard let self, let bounds = self.currentBounds else { return }
          self.fetchPOIs(bounds: bounds)
        }
      }
    }
  }
}
