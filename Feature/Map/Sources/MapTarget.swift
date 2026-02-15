//
//  MapTarget.swift
//  Map
//
//  Created by ttozzi on 2/1/26.
//

import Foundation
import Moya
import NetworkCore

enum MapTarget {

  struct GetLottoStores: BaseTargetType {

    typealias Response = MapMarkerListDTO

    var path: String { "lotto-stores/map" }
    var httpTask: HTTPTask {
      .requestParameters(
        parameters: [
          "min_lat": minLat,
          "max_lat": maxLat,
          "min_lng": minLng,
          "max_lng": maxLng
        ],
        encoding: URLEncoding.queryString
      )
    }
    var httpMethod: HTTPMethod { .get }
    var headers: [String: String]? { nil }

    let minLat: Double
    let maxLat: Double
    let minLng: Double
    let maxLng: Double
  }

  struct GetLottoStoreDetail: BaseTargetType {

    typealias Response = MapDetailDTO

    var path: String { "lotto-stores/\(storeId)" }
    var httpTask: HTTPTask { .requestPlain }
    var httpMethod: HTTPMethod { .get }
    var headers: [String: String]? { nil }

    let storeId: String
  }

  struct GetATMs: BaseTargetType {

    typealias Response = MapMarkerListDTO

    var path: String { "atm/map" }
    var httpTask: HTTPTask {
      .requestParameters(
        parameters: [
          "min_lat": minLat,
          "max_lat": maxLat,
          "min_lng": minLng,
          "max_lng": maxLng
        ],
        encoding: URLEncoding.queryString
      )
    }
    var httpMethod: HTTPMethod { .get }
    var headers: [String: String]? { nil }

    let minLat: Double
    let maxLat: Double
    let minLng: Double
    let maxLng: Double
  }

  struct GetATMDetail: BaseTargetType {

    typealias Response = MapDetailDTO

    var path: String { "atm/\(atmId)" }
    var httpTask: HTTPTask { .requestPlain }
    var httpMethod: HTTPMethod { .get }
    var headers: [String: String]? { nil }

    let atmId: String
  }
}
