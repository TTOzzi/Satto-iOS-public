//
//  MapPOI.swift
//  Map
//
//  Created by ttozzi on 2/15/26.
//

import Foundation

enum MapPOIType: String {
  case lottoStore = "lotto-store"
  case atm = "atm"
}

enum MapPOIFilter: Equatable {
  case all
  case lottoStore
  case atm
}

extension MapPOIFilter {
  func includes(_ type: MapPOIType) -> Bool {
    switch self {
    case .all:
      return true
    case .lottoStore:
      return type == .lottoStore
    case .atm:
      return type == .atm
    }
  }
}

struct MapPOI {
  let id: String
  let name: String
  let latitude: Double
  let longitude: Double
  let type: MapPOIType

  var uniqueId: String {
    "\(type.rawValue):\(id)"
  }
}

struct MapPOIDetail {
  let id: String
  let name: String
  let address: String
  let phone: String?
  let type: MapPOIType
}

struct MapPOIFetchResult {
  let lottoStores: [MapPOI]
  let atms: [MapPOI]
}
