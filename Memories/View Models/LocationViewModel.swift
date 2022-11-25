//
//  LocationViewModel.swift
//  No Mask
//
//  Created by Fadey Notchenko on 20.11.2022.
//

import Foundation
import SwiftUI
import CoreLocation

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var location: CLLocation?
    
    @Published var placemark: CLPlacemark? {
        willSet { objectWillChange.send() }
      }
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        
        self.manager.delegate = self
        self.manager.startUpdatingLocation()
    }
    
    func requestPermission() {
        self.manager.requestWhenInUseAuthorization()
    }
    
    func stopUpdateLocation() {
        self.manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        
        self.location = latest
        
        geocode()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    private func geocode() {
        guard let location = self.location else { return }
        geocoder.reverseGeocodeLocation(location, completionHandler: { (places, error) in
            if error == nil {
                self.placemark = places?[0]
            } else {
                self.placemark = nil
            }
        })
    }
}
