//
//  LocationService.swift
//  Map
//
//  Created by ttozzi on 1/11/26.
//

import Combine
import CoreLocation
import Foundation

final class LocationService: NSObject {
  
  static let shared = LocationService()
  
  private let locationManager: CLLocationManager
  private var isAuthorized: Bool {
    let status = locationManager.authorizationStatus
    return status == .authorizedWhenInUse || status == .authorizedAlways
  }
  private let authorizationStatusSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.notDetermined)
  private let currentLocationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
  private let locationErrorSubject = PassthroughSubject<Error, Never>()
  var authorizationStatus: AnyPublisher<CLAuthorizationStatus, Never> {
    return authorizationStatusSubject.eraseToAnyPublisher()
  }
  var currentLocation: AnyPublisher<CLLocation?, Never> {
    return currentLocationSubject.eraseToAnyPublisher()
  }
  var locationError: AnyPublisher<Error, Never> {
    return locationErrorSubject.eraseToAnyPublisher()
  }

  private override init() {
    self.locationManager = CLLocationManager()
    super.init()
    setupLocationManager()
  }
  
  private func setupLocationManager() {
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.distanceFilter = 10
    authorizationStatusSubject.send(locationManager.authorizationStatus)
  }
  
  func requestAuthorization() {
    let status = locationManager.authorizationStatus
    
    switch status {
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    case .denied, .restricted:
      break
    case .authorizedWhenInUse, .authorizedAlways:
      startUpdatingLocation()
    @unknown default:
      break
    }
  }
  
  func startUpdatingLocation() {
    guard isAuthorized else { return }
    locationManager.startUpdatingLocation()
  }
  
  func stopUpdatingLocation() {
    locationManager.stopUpdatingLocation()
  }
  
  func getCurrentLocation() {
    guard isAuthorized else {
      requestAuthorization()
      return
    }
    
    locationManager.requestLocation()
  }
}

extension LocationService: CLLocationManagerDelegate {
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus
    authorizationStatusSubject.send(status)
    if status == .authorizedWhenInUse || status == .authorizedAlways {
      startUpdatingLocation()
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    currentLocationSubject.send(location)
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    locationErrorSubject.send(error)
  }
}
