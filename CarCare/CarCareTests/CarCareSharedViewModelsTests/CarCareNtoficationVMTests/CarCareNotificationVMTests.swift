//
//  CarCareNotificationVMTests.swift
//  CarCareTests
//
//  Created by Ordinateur elena on 19/09/2025.
//

import XCTest
@testable import CarCare

@MainActor
final class CarCareNotificationVMTests: XCTestCase {
	var notificationCenter: FakeNotificationCenter!
	var maintenanceVM: FakeMaintenanceVM2!
	
	override func setUp() {
		super.setUp()
		notificationCenter = FakeNotificationCenter()
		maintenanceVM = FakeMaintenanceVM2()
	}
	
	override func tearDown() {
		notificationCenter = nil
		maintenanceVM = nil
		super.tearDown()
	}
	
    func test_updateReminder_schedulesNotification_ifAuthorizedAndNextDateWithin30Days() {
        // Given
        let maintenance = Maintenance(
            id: UUID(),
            maintenanceType: .BleedHydraulicBrakes,
            date: Date().addingTimeInterval(-10*24*3600), // 10 jours avant
            reminder: false
        )
        maintenanceVM.maintenances = [maintenance]

        // Simuler la prochaine maintenance dans 40 jours
        maintenanceVM.nextMaintenanceDateReturn = Date().addingTimeInterval(40*24*3600)

        let vm = NotificationViewModel(
            maintenanceVM: maintenanceVM,
            notificationCenter: notificationCenter
        )
        vm.isAuthorized = true
        //When
        vm.updateReminder(for: maintenance.id, value: true)
        //Then
        // Maintenant J-30 = 10 jours avant = dans le futur → ajouté
        XCTAssertEqual(notificationCenter.addedRequests.count, 2)
    }
	
    func test_updateReminder_cancelsNotification_ifValueIsFalse() {
		// Given
        let maintenance = Maintenance(id: UUID(), maintenanceType: .BleedHydraulicBrakes, date: Date(), reminder: false)
        maintenanceVM.maintenances = [maintenance]

        // Simuler qu'une notification existait déjà
        let request = UNNotificationRequest(
            identifier: "\(maintenance.maintenanceType.id)-1",
            content: UNMutableNotificationContent(),
            trigger: nil
        )
        notificationCenter.addedRequests.append(request)

        let vm = NotificationViewModel(maintenanceVM: maintenanceVM, notificationCenter: notificationCenter)

        // When
        vm.updateReminder(for: maintenance.id, value: false)

        // Then
        XCTAssertTrue(notificationCenter.removedIdentifiers.contains { $0.hasPrefix(maintenance.maintenanceType.id) })
	}
    
	func test_requestAndScheduleNotifications_setsIsAuthorizedFalse_whenDenied() async {
		// Given
		notificationCenter.granted = false
		
        let vm = NotificationViewModel(maintenanceVM: maintenanceVM, notificationCenter: notificationCenter)
		
		// When
		await vm.requestAndScheduleNotifications()
		
		// Then
		XCTAssertFalse(vm.isAuthorized)
	}
	
}
