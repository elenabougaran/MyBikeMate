//
//  CarCareAddMaintenanceVMTests.swift
//  CarCareTests
//
//  Created by Ordinateur elena on 19/09/2025.
//

import XCTest
@testable import CarCare

@MainActor
final class AddMaintenanceVMTests: XCTestCase {
	var addVM: AddMaintenanceVM!
		var maintenanceVM: FakeMaintenanceVM3!
		var store: FakeMaintenanceStore!
		var loader: FakeMaintenanceLoader!
		var notificationVM: FakeNotificationVM!

		override func setUp() {
			super.setUp()
			maintenanceVM = FakeMaintenanceVM3()
			store = FakeMaintenanceStore()
            maintenanceVM.store = store
			loader = FakeMaintenanceLoader(store: store)
			notificationVM = FakeNotificationVM(maintenanceVM: maintenanceVM)
			addVM = AddMaintenanceVM(maintenanceLoader: loader, maintenanceVM: maintenanceVM, notificationVM: notificationVM)
		}

		override func tearDown() {
			addVM = nil
			maintenanceVM = nil
			store = nil
			loader = nil
			notificationVM = nil
			super.tearDown()
		}

	func test_addMaintenance_savesMaintenanceAndFetchesAll() {
		// Given
		addVM.selectedMaintenanceType = .BleedHydraulicBrakes
		let bikeType: BikeType = .Manual
		let selectedDate = Date()
		addVM.selectedMaintenanceDate = selectedDate
		
		// When
		addVM.addMaintenance(bikeType: bikeType)
		
		// Then
		let expectation = XCTestExpectation(description: "Wait for fetchAllMaintenance")
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			XCTAssertFalse(self.maintenanceVM.maintenances.isEmpty)
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1.0)
		XCTAssertEqual(store.maintenances.count, 1)
	}
	
	func test_addMaintenance_handlesStoreError() {
		// Given
		store.shouldThrowStoreError = true
		addVM.selectedMaintenanceType = .BleedHydraulicBrakes
		addVM.selectedMaintenanceDate = Date()

		let expectation = XCTestExpectation(description: "Wait for addMaintenance error handling")

		// When
		addVM.addMaintenance(bikeType: .Manual)

		// Then
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			XCTAssertNotNil(self.addVM.error)
			if case .dataUnavailable(let error) = self.addVM.error {
				// On vérifie que l'erreur correspond bien au type StoreError simulé
				if case .modelNotFound = error {
					// succès
				} else {
					XCTFail("Expected StoreError.modelNotFound")
				}
			} else {
				XCTFail("Expected dataUnavailable error")
			}
			XCTAssertTrue(self.addVM.showAlert)
			expectation.fulfill()
		}

		wait(for: [expectation], timeout: 1.0)
	}
	
	func test_filteredMaintenanceTypes_excludesRunSoftwareAndBatteryDiagnosticsForManual() {
		// When
		let types = addVM.filteredMaintenanceTypes(for: .Manual)
		// Then
		XCTAssertFalse(types.contains(.RunSoftwareAndBatteryDiagnostics))
	}
	
	func test_filteredMaintenanceTypes_includesRunSoftwareAndBatteryDiagnosticsForElectric() {
		// When
		let types = addVM.filteredMaintenanceTypes(for: .Electric)
		// Then
		XCTAssertTrue(types.contains(.RunSoftwareAndBatteryDiagnostics))
	}
	
	func test_nextMaintenanceDate_returnsCorrectDate() {
		// Given
		let lastDate = Date()
		let maintenance = Maintenance(id: UUID(), maintenanceType: .BleedHydraulicBrakes, date: lastDate, reminder: true)
		maintenanceVM.maintenances = [maintenance]
		
		// When
		let nextDate = addVM.calculateNextMaintenanceDate(for: .BleedHydraulicBrakes)
		
		// Then
		let expected = Calendar.current.date(byAdding: .day, value: MaintenanceType.BleedHydraulicBrakes.frequencyInDays, to: lastDate)
		XCTAssertEqual(nextDate, expected)
	}
}
