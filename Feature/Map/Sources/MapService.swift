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

  func fetchPOIs(
    bounds: MapBounds,
    filter: MapPOIFilter
  ) async throws -> MapPOIFetchResult {
    switch filter {
    case .all:
      async let lottoStoresRequest = fetchLottoStores(bounds: bounds)
      async let atmsRequest = fetchATMs(bounds: bounds)
      let (lottoStores, atms) = try await (lottoStoresRequest, atmsRequest)
      return MapPOIFetchResult(lottoStores: lottoStores, atms: atms)
    case .lottoStore:
      let lottoStores = try await fetchLottoStores(bounds: bounds)
      return MapPOIFetchResult(lottoStores: lottoStores, atms: [])
    case .atm:
      let atms = try await fetchATMs(bounds: bounds)
      return MapPOIFetchResult(lottoStores: [], atms: atms)
    }
  }

  func fetchPOIDetail(poi: MapPOI) async throws -> MapPOIDetail {
    switch poi.type {
    case .lottoStore:
      return try await fetchLottoStoreDetail(storeId: poi.id)
    case .atm:
      return try await fetchATMDetail(atmId: poi.id)
    }
  }

  private func fetchLottoStores(bounds: MapBounds) async throws -> [MapPOI] {
    let target = MapTarget.GetLottoStores(
      minLat: bounds.minLat,
      maxLat: bounds.maxLat,
      minLng: bounds.minLng,
      maxLng: bounds.maxLng
    )
    let response = try await networkProvider.request(target: target)
    return response.markers.compactMap { $0.toDomain(type: .lottoStore) }
  }

  private func fetchATMs(bounds: MapBounds) async throws -> [MapPOI] {
    let target = MapTarget.GetATMs(
      minLat: bounds.minLat,
      maxLat: bounds.maxLat,
      minLng: bounds.minLng,
      maxLng: bounds.maxLng
    )
    let response = try await networkProvider.request(target: target)
    return response.markers.compactMap { $0.toDomain(type: .atm) }
  }

  private func fetchLottoStoreDetail(storeId: String) async throws -> MapPOIDetail {
    let target = MapTarget.GetLottoStoreDetail(storeId: storeId)
    let response = try await networkProvider.request(target: target)
    return response.toDomain(type: .lottoStore)
  }

  private func fetchATMDetail(atmId: String) async throws -> MapPOIDetail {
    let target = MapTarget.GetATMDetail(atmId: atmId)
    let response = try await networkProvider.request(target: target)
    return response.toDomain(type: .atm)
  }
}
