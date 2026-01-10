//
//  MapViewModel.swift
//  Map
//
//  Created by ttozzi on 1/11/26.
//

import Combine
import Foundation

public final class MapViewModel {

  // MARK: - Input
  public enum Input {
    case viewDidLoad
    case placeTapped(place: Place)
    case refresh
  }

  // MARK: - Output
  public struct Output {
    let places = CurrentValueSubject<[Place], Never>([])
    let isLoading = PassthroughSubject<Bool, Never>()
    let showError = PassthroughSubject<() -> Void, Never>()
  }

  public let output = Output()
  private var cancellables = Set<AnyCancellable>()

  // Dependencies
  // private let mapRepository: MapRepositoryProtocol

  public init() {
    // self.mapRepository = DIContainer.shared.resolve(MapRepositoryProtocol.self)
  }

  public func send(input: Input) {
    switch input {
    case .viewDidLoad:
      handleViewDidLoad()

    case .placeTapped(let place):
      handlePlaceTapped(place: place)

    case .refresh:
      handleRefresh()
    }
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
