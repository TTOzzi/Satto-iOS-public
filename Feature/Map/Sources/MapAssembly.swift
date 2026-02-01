//
//  MapAssembly.swift
//  Map
//
//  Created by ttozzi on 1/19/26.
//

import DIInjector
import Foundation

public final class MapAssembly: Assembly {
  public func assemble(container: Container) {
    container.register(LocationService.self) { _ in
      return LocationService.shared
    }

    container.register(MapService.self) { _ in
      return MapService()
    }
  }

  public init() {}
}
