//
//  LottoStoreDTO.swift
//  Map
//
//  Created by ttozzi on 2/1/26.
//

import Foundation

struct LottoStoreListDTO: Decodable {
  let markers: [LottoStoreDTO]
}

struct LottoStoreDTO: Decodable {
  let id: String
  let name: String
  let latitude: String
  let longitude: String
}

extension LottoStoreDTO {
  func toDomain() -> LottoStore {
    LottoStore(
      id: id,
      name: name,
      latitude: Double(latitude) ?? 0,
      longitude: Double(longitude) ?? 0
    )
  }
}

struct LottoStore {
  let id: String
  let name: String
  let latitude: Double
  let longitude: Double
}

struct LottoStoreDetailDTO: Decodable {
  let id: String
  let name: String
  let address: String
  let phone: String?
}

extension LottoStoreDetailDTO {
  func toDomain() -> LottoStoreDetail {
    LottoStoreDetail(
      id: id,
      name: name,
      address: address,
      phone: phone
    )
  }
}

struct LottoStoreDetail {
  let id: String
  let name: String
  let address: String
  let phone: String?
}
