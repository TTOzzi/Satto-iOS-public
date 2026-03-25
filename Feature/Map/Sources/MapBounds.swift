//
//  MapBounds.swift
//  Map
//
//  Created by ttozzi on 3/25/26.
//

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
