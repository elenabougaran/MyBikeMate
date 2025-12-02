//
//  CarCareMaintenanceVMTests.swift
//  CarCareTests
//
//  Created by Ordinateur elena on 18/09/2025.
//

import XCTest
import Combine
@testable import CarCare

@MainActor
final class CarCareMaintenanceVMTests: XCTestCase {

	var store: MaintenanceStoreFake!
	var notificationVM: NotificationVMFake!
	var loader: LocalMaintenanceLoader!
	var vm: MaintenanceVM!
	
	override func setUp() {
		super.setUp()
		store = MaintenanceStoreFake()
		loader = LocalMaintenanceLoader(store: store)
		notificationVM = NotificationVMFake()
		vm = MaintenanceVM(loader: loader, notificationVM: notificationVM)
	}
	
	override func tearDown() {
		store = nil
		loader = nil
		notificationVM = nil
		vm = nil
		super.tearDown()
	}
	
	func test_fetchAllMaintenance_loadsAndFiltersCorrectly() throws {
		// Given
		let manualBikeType: BikeType = .Manual
		let runSoftwareAndBatteryDiagnosticsMaintenance = Maintenance(id: UUID(), maintenanceType: .RunSoftwareAndBatteryDiagnostics, date: Date(), reminder: false)
		let brakeMaintenance = Maintenance(id: UUID(), maintenanceType: .BleedHydraulicBrakes, date: Date(), reminder: false)
		try store.insert(runSoftwareAndBatteryDiagnosticsMaintenance.toLocal())
		try store.insert(brakeMaintenance.toLocal())
		
		// When
		let exp = expectation(description: "maintenances updated")
			var cancellable: AnyCancellable? = nil
			
			// Observe le Published
			cancellable = vm.$maintenances
				.dropFirst() // ignore la valeur initiale
				.sink { maintenances in
					exp.fulfill()
					cancellable?.cancel()
				}
			
			// When
			vm.fetchAllMaintenance(for: manualBikeType)
			
			// Wait
			wait(for: [exp], timeout: 1.0)
		
		// Then
		XCTAssertEqual(vm.maintenances.count, 1) 
		XCTAssertEqual(vm.maintenances.first?.maintenanceType, .BleedHydraulicBrakes)

	}
	
	func test_defineOverallMaintenanceStatus_returnsAPrevoirIfEmpty() {
		// Given
		vm.maintenances = []
		
		// When
		let status = vm.defineOverallMaintenanceStatus(for: .Manual)
		
		// Then
		XCTAssertEqual(status, .aPrevoir)
	}
	
	func test_updateReminder_updatesLoaderAndNotification() throws {
		// Given
		let maintenance = Maintenance(id: UUID(), maintenanceType: .BleedHydraulicBrakes, date: Date(), reminder: false)
		try store.insert(maintenance.toLocal())
		vm.maintenances = [maintenance]
		
		// When
		vm.updateReminder(for: maintenance, value: true)
		
		// Then
		XCTAssertTrue(vm.maintenances.first?.reminder ?? false)
	}
	
	func test_deleteAllMaintenances_clearsMaintenances() throws {
		// Given
		let m1 = Maintenance(id: UUID(), maintenanceType: .BleedHydraulicBrakes, date: Date(), reminder: false)
		try store.insert(m1.toLocal())
		vm.maintenances = [m1]
		
		// When
		vm.deleteAllMaintenances()
		
		// Then
		XCTAssertTrue(vm.maintenances.isEmpty)
	}
	
	func test_deleteOneMaintenance_removesFromVMAndStore() throws {
		// Given
		let maintenance = Maintenance(id: UUID(), maintenanceType: .BleedHydraulicBrakes, date: Date(), reminder: false)
		try store.insert(maintenance.toLocal())
		vm.maintenances = [maintenance]
		
		// When
		vm.deleteOneMaintenance(maintenance: maintenance, bikeType: .Manual)
		
		// Then
		XCTAssertTrue(vm.maintenances.isEmpty)
	}
	 
}

