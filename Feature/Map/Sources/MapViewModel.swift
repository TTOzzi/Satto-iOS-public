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

@MainActor
public final class MapViewModel {

  enum Input {
    case viewDidLoad
    case viewDidAppear
    case cameraIdle(bounds: MapBounds, reason: CameraMoveReason)
    case searchButtonTapped
    case poiTapped(poi: MapPOI)
    case lottoFilterTapped
    case atmFilterTapped
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
    let selectedPOI = CurrentValueSubject<MapPOI?, Never>(nil)
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
  private var poiFetchTask: Task<Void, Never>?
  private var poiDetailFetchTask: Task<Void, Never>?
  private var isTabEntryAuthorizationCheckPending = false
  private var hasShownDeniedAlert = false
  private var loadingCount = 0

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

    case .lottoFilterTapped:
      handleFilterTapped(targetFilter: .lottoStore)

    case .atmFilterTapped:
      handleFilterTapped(targetFilter: .atm)

    case .closeStoreDetail:
      handleCloseStoreDetail()
    }
  }

  private func setupLocationBinding() {
    locationService.authorizationStatus
      .sink { [weak self] status in
        Task { @MainActor in
          guard let self else { return }
          self.output.locationAuthorizationStatus.send(status)
          self.handleAuthorizationStatus(status)
        }
      }
      .store(in: &cancellables)

    locationService.currentLocation
      .sink { [weak self] location in
        Task { @MainActor in
          guard let self else { return }
          self.output.currentLocation.send(location)
          if location != nil {
            self.locationService.stopUpdatingLocation()
          }
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
    guard isTabEntryAuthorizationCheckPending else { return }

    switch status {
    case .restricted, .denied:
      if !hasShownDeniedAlert {
        output.shouldShowLocationDeniedAlert.send(())
        hasShownDeniedAlert = true
      }
      isTabEntryAuthorizationCheckPending = false
    case .authorizedWhenInUse, .authorizedAlways:
      isTabEntryAuthorizationCheckPending = false
    case .notDetermined:
      break
    @unknown default:
      isTabEntryAuthorizationCheckPending = false
    }
  }

  private func handleViewDidAppear() {
    isTabEntryAuthorizationCheckPending = true
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
      // 위치 권한 허용 후 현재 위치로 포커싱된 경우 자동 재검색
      output.shouldShowSearchButton.send(false)
      fetchPOIs(bounds: bounds)
      hasInitiallyLoaded = true
    }
  }

  private func handleSearchButtonTapped() {
    guard let bounds = currentBounds else { return }
    output.shouldShowSearchButton.send(false)
    fetchPOIs(bounds: bounds)
  }

  private func handlePOITapped(poi: MapPOI) {
    guard output.selectedPOI.value?.uniqueId != poi.uniqueId else { return }
    output.selectedPOI.send(poi)
    fetchPOIDetail(poi: poi)
  }

  private func handleFilterTapped(targetFilter: MapPOIFilter) {
    let filter: MapPOIFilter = output.selectedFilter.value == targetFilter ? .all : targetFilter
    applyFilter(filter)
  }

  private func applyFilter(_ filter: MapPOIFilter) {
    guard output.selectedFilter.value != filter else { return }

    output.selectedFilter.send(filter)
    handleCloseStoreDetail()
    output.shouldShowSearchButton.send(false)

    guard let bounds = currentBounds else { return }
    fetchPOIs(bounds: bounds)
  }

  private func handleCloseStoreDetail() {
    poiDetailFetchTask?.cancel()
    output.selectedPOI.send(nil)
    output.poiDetail.send(nil)
  }

  private func fetchPOIDetail(poi: MapPOI) {
    poiDetailFetchTask?.cancel()
    beginLoading()
    poiDetailFetchTask = Task { @MainActor [weak self] in
      guard let self else { return }
      defer { self.endLoading() }

      do {
        let detail = try await mapService.fetchPOIDetail(poi: poi)
        guard !Task.isCancelled else { return }
        output.poiDetail.send(detail)
      } catch {
        guard !Task.isCancelled else { return }
        output.showError.send { [weak self] in
          self?.fetchPOIDetail(poi: poi)
        }
      }
    }
  }

  private func fetchPOIs(bounds: MapBounds) {
    poiFetchTask?.cancel()
    beginLoading()
    poiFetchTask = Task { @MainActor [weak self] in
      guard let self else { return }
      defer { self.endLoading() }

      do {
        let result = try await mapService.fetchPOIs(
          minLat: bounds.minLat,
          maxLat: bounds.maxLat,
          minLng: bounds.minLng,
          maxLng: bounds.maxLng,
          filter: output.selectedFilter.value
        )
        guard !Task.isCancelled else { return }
        output.lottoStores.send(result.lottoStores)
        output.atmStores.send(result.atms)
      } catch {
        guard !Task.isCancelled else { return }
        output.showError.send { [weak self] in
          guard let self, let bounds = self.currentBounds else { return }
          self.fetchPOIs(bounds: bounds)
        }
      }
    }
  }

  private func beginLoading() {
    loadingCount += 1
    if loadingCount == 1 {
      output.isLoading.send(true)
    }
  }

  private func endLoading() {
    if loadingCount > 0 {
      loadingCount -= 1
    }
    if loadingCount == 0 {
      output.isLoading.send(false)
    }
  }
}
