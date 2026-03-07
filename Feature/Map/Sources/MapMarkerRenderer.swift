//
//  MapMarkerRenderer.swift
//  Map
//
//  Created by Codex on 3/7/26.
//

import Foundation
import NMapsMap

final class MapMarkerRenderer {

  private let mapView: NMFMapView
  private let markerLabelHideThreshold: Int
  private let onPOITapped: (MapPOI) -> Void

  private var lottoMarkers: [String: LottoMarker] = [:]
  private var atmMarkers: [String: ATMMarker] = [:]
  private var lottoMarkerNames: [String: String] = [:]
  private var atmMarkerNames: [String: String] = [:]

  init(
    mapView: NMFMapView,
    markerLabelHideThreshold: Int,
    onPOITapped: @escaping (MapPOI) -> Void
  ) {
    self.mapView = mapView
    self.markerLabelHideThreshold = markerLabelHideThreshold
    self.onPOITapped = onPOITapped
  }

  func updateLottoMarkers(stores: [MapPOI], selectedPOIUniqueId: String?) {
    let newStoreIds = Set(stores.map { $0.id })
    let existingIds = Set(lottoMarkers.keys)

    let removedIds = existingIds.subtracting(newStoreIds)
    for id in removedIds {
      lottoMarkers[id]?.mapView = nil
      lottoMarkers.removeValue(forKey: id)
      lottoMarkerNames.removeValue(forKey: id)
    }

    for store in stores {
      lottoMarkerNames[store.id] = store.name
      if lottoMarkers[store.id] == nil {
        let marker = LottoMarker()
        marker.position = NMGLatLng(lat: store.latitude, lng: store.longitude)
        marker.captionText = store.name
        marker.touchHandler = { [weak self] _ in
          self?.onPOITapped(store)
          return true
        }
        marker.mapView = mapView
        lottoMarkers[store.id] = marker
      }
      lottoMarkers[store.id]?.isSelected = selectedPOIUniqueId == store.uniqueId
    }

    updateMarkerCaptionVisibility()
  }

  func updateATMMarkers(stores: [MapPOI], selectedPOIUniqueId: String?) {
    let newStoreIds = Set(stores.map { $0.id })
    let existingIds = Set(atmMarkers.keys)

    let removedIds = existingIds.subtracting(newStoreIds)
    for id in removedIds {
      atmMarkers[id]?.mapView = nil
      atmMarkers.removeValue(forKey: id)
      atmMarkerNames.removeValue(forKey: id)
    }

    for store in stores {
      atmMarkerNames[store.id] = store.name
      if atmMarkers[store.id] == nil {
        let marker = ATMMarker()
        marker.position = NMGLatLng(lat: store.latitude, lng: store.longitude)
        marker.captionText = store.name
        marker.touchHandler = { [weak self] _ in
          self?.onPOITapped(store)
          return true
        }
        marker.mapView = mapView
        atmMarkers[store.id] = marker
      }
      atmMarkers[store.id]?.isSelected = selectedPOIUniqueId == store.uniqueId
    }

    updateMarkerCaptionVisibility()
  }

  func updateSelection(from previousPOI: MapPOI?, to currentPOI: MapPOI?) {
    if let previousPOI {
      switch previousPOI.type {
      case .lottoStore:
        lottoMarkers[previousPOI.id]?.isSelected = false
      case .atm:
        atmMarkers[previousPOI.id]?.isSelected = false
      }
    }

    if let currentPOI {
      switch currentPOI.type {
      case .lottoStore:
        lottoMarkers[currentPOI.id]?.isSelected = true
      case .atm:
        atmMarkers[currentPOI.id]?.isSelected = true
      }
    }
  }

  private func updateMarkerCaptionVisibility() {
    let totalMarkerCount = lottoMarkers.count + atmMarkers.count
    let shouldHideCaption = totalMarkerCount > markerLabelHideThreshold

    for (id, marker) in lottoMarkers {
      marker.captionText = shouldHideCaption ? "" : (lottoMarkerNames[id] ?? "")
    }

    for (id, marker) in atmMarkers {
      marker.captionText = shouldHideCaption ? "" : (atmMarkerNames[id] ?? "")
    }
  }
}
