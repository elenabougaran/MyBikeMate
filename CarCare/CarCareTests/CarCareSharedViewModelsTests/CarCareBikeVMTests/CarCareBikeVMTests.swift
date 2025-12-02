//
//  CarCareBikeVMTests.swift
//  CarCareTests
//
//  Created by Ordinateur elena on 15/07/2025.
//

import XCTest
@testable import CarCare

@MainActor
final class CarCareBikeVMTests: XCTestCase {
	
	var store: FakeBikeStore!
	var notificationVM: NotificationVMFake!
	var loader: LocalBikeLoader!
	var vm: BikeVM!
	
	override func setUp() {
		super.setUp()
		store = FakeBikeStore()
		notificationVM = NotificationVMFake()
		loader = LocalBikeLoader(store: store)
		vm = BikeVM(bikeLoader: loader, notificationVM: notificationVM)
	}
	
	override func tearDown() {
		store = nil
		loader = nil
		notificationVM = nil
		vm = nil
		super.tearDown()
	}
	
	// MARK: - XCTest Case
	
	func test_fetchBikeData_setsPublishedProperties_whenBikeExists() {
		// Given
		let bike = Bike(id: UUID(), brand: "Decathlon", model: "Riverside 500", year: 2022, bikeType: .Manual, identificationNumber: "VIN123")
        try? store.insert(LocalBike(id: bike.id, year: bike.year, model: bike.model, brand: bike.brand, bikeType: bike.bikeType, identificationNumber: bike.identificationNumber, imageData: "fakeImageData".data(using: .utf8)))
		
		let exp = expectation(description: "completion called")
		
		// When
		vm.fetchBikeData {
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1.0)
		
		// Then
		XCTAssertNotNil(vm.bike)
		XCTAssertEqual(vm.model, "Riverside 500")
		XCTAssertEqual(vm.brand, "Decathlon")
		XCTAssertEqual(vm.year, 2022)
		XCTAssertEqual(vm.bikeType, .Manual)
		XCTAssertEqual(vm.identificationNumber, "VIN123")
		XCTAssertNil(vm.error)
		XCTAssertFalse(vm.showAlert)
	}
	
	func test_fetchBikeData_setsError_whenNoBikeFound() {
		// Given
		// When
		vm.fetchBikeData()
		// Give time for async dispatch to main to set error
		let exp = expectation(description: "wait main updates")
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
			exp.fulfill()
		}
		wait(for: [exp], timeout: 1.0)
		
		// Then
		XCTAssertNil(vm.bike)
		XCTAssertNotNil(vm.error)
		XCTAssertTrue(vm.showAlert)
	}
	
	func test_addBike_savesAndReturnsTrue() throws {
		// Given
		// When
        let result = vm.addBike(brand: "Decathlon", model: "Riverside 500", year: 2020, type: .Manual, identificationNumber: "VINH1", image: nil)
		
		// Then
		XCTAssertTrue(result)
		let loaded = try loader.load()
		XCTAssertEqual(loaded?.model, "Riverside 500")
	}
	
	func test_modifyBikeInformations_updatesAndPersists() throws {
		// Given
		let bike = Bike(id: UUID(), brand: "Decathlon", model: "Riverside 500", year: 2018, bikeType: .Manual, identificationNumber: "VIN0")
		try store.insert(bike.toLocal())
		
		let exp = expectation(description: "fetchBikeData completion")
		
		vm.fetchBikeData() {
			exp.fulfill()
		}
		wait(for: [exp], timeout: 2.0)
		
		// When
        vm.modifyBikeInformations(brand: "Decathlon", model: "Elops 520", year: 2023, type: .Manual, identificationNumber: "VINNEW", image: nil)
		
		// Then
		XCTAssertEqual(vm.brand, "Decathlon")
		XCTAssertEqual(vm.model, "Elops 520")
		XCTAssertEqual(vm.year, 2023)
		XCTAssertEqual(vm.identificationNumber, "VINNEW")
		
		let reloaded = try loader.load()
		XCTAssertEqual(reloaded?.brand, "Decathlon")
		XCTAssertEqual(reloaded?.model, "Elops 520")
		XCTAssertEqual(reloaded?.year, 2023)
		XCTAssertEqual(reloaded?.identificationNumber, "VINNEW")
	}
	
	func test_deleteCurrentBike_removesStoredBike_andClearsVM() throws {
		// Given
		let initial = Bike(id: UUID(), brand: "Decathlon", model: "Riverside 500", year: 2021, bikeType: .Manual, identificationNumber: "VINY9")
		try store.insert(initial.toLocal())
		
		let exp = expectation(description: "completion called")
		vm.fetchBikeData { exp.fulfill() }
		wait(for: [exp], timeout: 1.0)
		
		// When
		vm.deleteCurrentBike()
		
		// Then
		XCTAssertNil(vm.bike)
		let reloaded = try loader.load()
		XCTAssertNil(reloaded)
	}
}
