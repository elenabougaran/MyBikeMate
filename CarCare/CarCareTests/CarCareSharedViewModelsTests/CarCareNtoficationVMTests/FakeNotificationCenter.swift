//
//  MockNotificationCenter.swift
//  CarCareTests
//
//  Created by Ordinateur elena on 19/09/2025.
//

import XCTest
import UserNotifications
@testable import CarCare

final class FakeNotificationCenter: NotificationCenterProtocol {
	var addedRequests: [UNNotificationRequest] = []
	var removedIdentifiers: [String] = []
	var removeAllCalled = false
	var requestAuthorizationCalled = false
    var granted: Bool = true
    var fakeSettings = FakeNotificationSettings(authorizationStatus: .authorized)

	func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?) {
		addedRequests.append(request)
		completionHandler?(nil)
	}
	
	func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
		removedIdentifiers.append(contentsOf: identifiers)
	}
	
	func removeAllPendingNotificationRequests() {
		removeAllCalled = true
	}
	
	func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
		requestAuthorizationCalled = true
		return granted
	}
    
    func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void) {
           // Renvoie simplement les notifications ajoutées qui n'ont pas été supprimées
           let pending = addedRequests.filter { request in
               !removedIdentifiers.contains(request.identifier)
           }
           completionHandler(pending)
       }
    
    func notificationSettings() async -> UNNotificationSettings {
            // On récupère les vrais settings, mais pour le fake on ne peut que créer un objet vide
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            return settings
        }
}

struct FakeNotificationSettings {
    var authorizationStatus: UserNotifications.UNAuthorizationStatus
}

