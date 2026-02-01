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

public final class MapViewModel {

  enum Input {
    case viewDidLoad
    case viewDidAppear
    case mapBoundsChanged(bounds: MapBounds)
    case storeTapped(store: LottoStore)
  }

  struct Output {
    let lottoStores = CurrentValueSubject<[LottoStore], Never>([])
    let isLoading = PassthroughSubject<Bool, Never>()
    let showError = PassthroughSubject<() -> Void, Never>()
    let locationAuthorizationStatus = PassthroughSubject<CLAuthorizationStatus, Never>()
    let currentLocation = PassthroughSubject<CLLocation?, Never>()
    let shouldShowLocationDeniedAlert = PassthroughSubject<Void, Never>()
    let selectedStore = PassthroughSubject<LottoStore?, Never>()
  }

  @Injected var locationService: LocationService
  @Injected var mapService: MapService

  let output = Output()
  private var cancellables = Set<AnyCancellable>()
  private var currentBounds: MapBounds?

  public init() {
    setupLocationBinding()
  }

  func send(input: Input) {
    switch input {
    case .viewDidLoad:
      break

    case .viewDidAppear:
      handleViewDidAppear()

    case .mapBoundsChanged(let bounds):
      handleMapBoundsChanged(bounds: bounds)

    case .storeTapped(let store):
      handleStoreTapped(store: store)
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

  private func handleMapBoundsChanged(bounds: MapBounds) {
    currentBounds = bounds
    fetchLottoStores(bounds: bounds)
  }

  private func handleStoreTapped(store: LottoStore) {
    output.selectedStore.send(store)
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
