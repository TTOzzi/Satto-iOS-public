//
//  LottoStoreDTO.swift
//  Map
//
//  Created by ttozzi on 2/1/26.
//

import Foundation

struct MapMarkerListDTO: Decodable {
  let markers: [MapMarkerDTO]
}

struct MapMarkerDTO: Decodable {
  let id: String
  let name: String
  let latitude: String
  let longitude: String
}

extension MapMarkerDTO {
  func toDomain(type: MapPOIType) -> MapPOI? {
    guard let latitude = Double(latitude), let longitude = Double(longitude) else {
      return nil
    }

    return MapPOI(
      id: id,
      name: name,
      latitude: latitude,
      longitude: longitude,
      type: type
    )
  }
}

struct MapDetailDTO: Decodable {
  let id: String
  let name: String
  let address: String
  let phone: String?
}

extension MapDetailDTO {
  func toDomain(type: MapPOIType) -> MapPOIDetail {
    MapPOIDetail(
      id: id,
      name: name,
      address: address,
      phone: phone,
      type: type
    )
  }
}
