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

public final class MapViewModel {

  enum Input {
    case viewDidLoad
    case viewDidAppear
    case placeTapped(place: Place)
    case refresh
  }

  struct Output {
    let places = CurrentValueSubject<[Place], Never>([])
    let isLoading = PassthroughSubject<Bool, Never>()
    let showError = PassthroughSubject<() -> Void, Never>()
    let locationAuthorizationStatus = PassthroughSubject<CLAuthorizationStatus, Never>()
    let currentLocation = PassthroughSubject<CLLocation?, Never>()
    let shouldShowLocationDeniedAlert = PassthroughSubject<Void, Never>()
  }

  @Injected var locationService: LocationService
  
  let output = Output()
  private var cancellables = Set<AnyCancellable>()

  public init() {
    setupLocationBinding()
  }

  func send(input: Input) {
    switch input {
    case .viewDidLoad:
      handleViewDidLoad()
      
    case .viewDidAppear:
      handleViewDidAppear()

    case .placeTapped(let place):
      handlePlaceTapped(place: place)

    case .refresh:
      handleRefresh()
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

  private func handleViewDidLoad() {
    output.isLoading.send(true)
    
    // TODO: 실제 데이터 로딩 로직 구현
    // mapRepository.fetchPlaces()
    //   .sink(
    //     receiveCompletion: { [weak self] completion in
    //       self?.output.isLoading.send(false)
    //       if case .failure = completion {
    //         self?.output.showError.send({ [weak self] in
    //           self?.handleViewDidLoad()
    //         })
    //       }
    //     },
    //     receiveValue: { [weak self] places in
    //       self?.output.places.send(places)
    //     }
    //   )
    //   .store(in: &cancellables)

    // 임시 데이터
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      self?.output.isLoading.send(false)
      self?.output.places.send([
        Place(id: "1", name: "명소 1", latitude: 37.5665, longitude: 126.9780),
        Place(id: "2", name: "명소 2", latitude: 37.5651, longitude: 126.9770),
      ])
    }
  }

  private func handlePlaceTapped(place: Place) {
    // 명소 선택 시 처리 로직
    print("Place tapped: \(place.name)")
  }

  private func handleRefresh() {
    handleViewDidLoad()
  }
}

// MARK: - Models
public struct Place {
  let id: String
  let name: String
  let latitude: Double
  let longitude: Double
  
  public init(id: String, name: String, latitude: Double, longitude: Double) {
    self.id = id
    self.name = name
    self.latitude = latitude
    self.longitude = longitude
  }
}
