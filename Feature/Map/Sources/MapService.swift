//
//  MapService.swift
//  Map
//
//  Created by ttozzi on 2/1/26.
//

import DIInjector
import Foundation
import NetworkCore

final class MapService {

  @Injected private var networkProvider: NetworkProvider

  func fetchLottoStores(
    minLat: Double,
    maxLat: Double,
    minLng: Double,
    maxLng: Double
  ) async throws -> [LottoStore] {
    let target = MapTarget.GetLottoStores(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng
    )
    let response = try await networkProvider.request(target: target)
    return response.markers.map { $0.toDomain() }
  }

  func fetchStoreDetail(storeId: String) async throws -> LottoStoreDetail {
    let target = MapTarget.GetLottoStoreDetail(storeId: storeId)
    let response = try await networkProvider.request(target: target)
    return response.toDomain()
  }
}
