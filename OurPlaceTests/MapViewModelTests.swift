//
//  MapViewModelTests.swift
//  OurPlaceTests
//
//  Created by Chaniru Sandive on 2025-08-18.
//

import XCTest
import CoreLocation
import MapKit
@testable import OurPlace

final class MapViewModelTests: XCTestCase {
    
    var viewModel: MapViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = MapViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Basic Property Tests
    
    func testInitialState() {
        // Test initial values
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertNil(viewModel.droppedPin)
        XCTAssertFalse(viewModel.showPinDetails)
        XCTAssertEqual(viewModel.reverseGeocodedAddress, "")
        XCTAssertTrue(viewModel.nearbyPlaces.isEmpty)
        XCTAssertFalse(viewModel.isLoadingNearbyPlaces)
    }
    
    func testSearchTextUpdate() {
        // Test search text binding
        viewModel.searchText = "Test Search"
        XCTAssertEqual(viewModel.searchText, "Test Search")
    }
    
    // MARK: - Pin Dropping Tests
    
    func testDropPinCreatesPin() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        // When
        viewModel.dropPinAtCoordinate(coordinate)
        
        // Then
        XCTAssertNotNil(viewModel.droppedPin)
        XCTAssertEqual(Double(viewModel.droppedPin?.coordinate.latitude ?? 0), Double(coordinate.latitude), accuracy: 0.0001)
        XCTAssertEqual(Double(viewModel.droppedPin?.coordinate.longitude ?? 0), Double(coordinate.longitude), accuracy: 0.0001)
        XCTAssertTrue(viewModel.showPinDetails)
        XCTAssertTrue(viewModel.isLoadingNearbyPlaces)
    }
    
    func testDropPinReplacesExistingPin() {
        // Given
        let firstCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let secondCoordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        
        // When
        viewModel.dropPinAtCoordinate(firstCoordinate)
        let firstPinId = viewModel.droppedPin?.id
        
        viewModel.dropPinAtCoordinate(secondCoordinate)
        let secondPinId = viewModel.droppedPin?.id
        
        // Then
        XCTAssertNotEqual(firstPinId, secondPinId)
        XCTAssertEqual(Double(viewModel.droppedPin?.coordinate.latitude ?? 0), Double(secondCoordinate.latitude), accuracy: 0.0001)
        XCTAssertEqual(Double(viewModel.droppedPin?.coordinate.longitude ?? 0), Double(secondCoordinate.longitude), accuracy: 0.0001)
    }
    
    // MARK: - Pin Management Tests
    
    func testSnapPinToPlace() {
        // Given
        let originalCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let placeCoordinate = CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        let place = NearbyPlace(
            id: UUID(),
            name: "Test Place",
            address: "123 Test St",
            coordinate: placeCoordinate
        )
        
        viewModel.dropPinAtCoordinate(originalCoordinate)
        
        // When
        viewModel.snapPinToPlace(place)
        
        // Then
        XCTAssertEqual(Double(viewModel.droppedPin?.coordinate.latitude ?? 0), Double(placeCoordinate.latitude), accuracy: 0.0001)
        XCTAssertEqual(Double(viewModel.droppedPin?.coordinate.longitude ?? 0), Double(placeCoordinate.longitude), accuracy: 0.0001)
        XCTAssertEqual(viewModel.reverseGeocodedAddress, place.address)
        XCTAssertFalse(viewModel.showPinDetails)
    }
    
    func testSavePinAsIs() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        viewModel.dropPinAtCoordinate(coordinate)
        
        // When
        viewModel.savePinAsIs()
        
        // Then
        XCTAssertFalse(viewModel.showPinDetails)
        
    }
    
    func testDismissPinDetails() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        viewModel.dropPinAtCoordinate(coordinate)
        viewModel.reverseGeocodedAddress = "Test Address"
        viewModel.nearbyPlaces = [
            NearbyPlace(id: UUID(), name: "Test", address: "Test", coordinate: coordinate)
        ]
        
        // When
        viewModel.dismissPinDetails()
        
        // Then
        XCTAssertFalse(viewModel.showPinDetails)
        XCTAssertNil(viewModel.droppedPin)
        XCTAssertTrue(viewModel.nearbyPlaces.isEmpty)
        XCTAssertEqual(viewModel.reverseGeocodedAddress, "")
    }
    
    // MARK: - Map Region Tests
    
    func testUpdateCurrentMapRegion() {
        // Given
        let newRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        // When
        viewModel.updateCurrentMapRegion(newRegion)
        
        // Then
        XCTAssertEqual(Double(viewModel.currentMapRegion.center.latitude), Double(newRegion.center.latitude), accuracy: 0.0001)
        XCTAssertEqual(Double(viewModel.currentMapRegion.center.longitude), Double(newRegion.center.longitude), accuracy: 0.0001)
        XCTAssertEqual(Double(viewModel.currentMapRegion.span.latitudeDelta), Double(newRegion.span.latitudeDelta), accuracy: 0.0001)
        XCTAssertEqual(Double(viewModel.currentMapRegion.span.longitudeDelta), Double(newRegion.span.longitudeDelta), accuracy: 0.0001)
    }
    
    // MARK: - Helper Functions Tests
    
    func testFormatAddressFromMKPlacemark() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let placemark = MKPlacemark(coordinate: coordinate)
        
        // When
        let address = formatAddress(from: placemark)
        
        // Then
        // Should fallback to coordinates when no address components
        XCTAssertTrue(address.contains("37.7749"))
        XCTAssertTrue(address.contains("-122.4194"))
    }
    
    // MARK: - Data Model Tests
    
    func testNearbyPlaceCreation() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let place = NearbyPlace(
            id: UUID(),
            name: "Test Place",
            address: "123 Test St",
            coordinate: coordinate
        )
        
        // Then
        XCTAssertEqual(place.name, "Test Place")
        XCTAssertEqual(place.address, "123 Test St")
        XCTAssertEqual(Double(place.coordinate.latitude), Double(coordinate.latitude), accuracy: 0.0001)
        XCTAssertEqual(Double(place.coordinate.longitude), Double(coordinate.longitude), accuracy: 0.0001)
    }
    
    func testDroppedPinCreation() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let pin = DroppedPin(
            id: UUID(),
            coordinate: coordinate,
            timestamp: Date()
        )
        
        // Then
        XCTAssertNotNil(pin.id)
        XCTAssertEqual(Double(pin.coordinate.latitude), Double(coordinate.latitude), accuracy: 0.0001)
        XCTAssertEqual(Double(pin.coordinate.longitude), Double(coordinate.longitude), accuracy: 0.0001)
        XCTAssertNotNil(pin.timestamp)
    }
}