//
//  NotificationViewModel.swift
//  CarCare
//
//  Created by Ordinateur elena on 25/08/2025.
//

import Foundation
import UserNotifications
import Combine
import UIKit

protocol NotificationCenterProtocol {
	func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?)
	func removePendingNotificationRequests(withIdentifiers identifiers: [String])
	func removeAllPendingNotificationRequests()
	func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func getPendingNotificationRequests(completionHandler: @Sendable @escaping ([UNNotificationRequest]) -> Void)
    func notificationSettings() async -> UNNotificationSettings
}

@MainActor
class NotificationViewModel: ObservableObject {
	@Published var error: AppError?
	@Published var isAuthorized = false
    @Published var showSettingsAlert: Bool = false
	var maintenanceVM: MaintenanceVM
	var notificationCenter: NotificationCenterProtocol

	// Initialisation avec injection de dépendances (pour les tests)
	init(maintenanceVM: MaintenanceVM, notificationCenter: NotificationCenterProtocol = UNUserNotificationCenter.current()) {
		self.maintenanceVM = maintenanceVM
		self.notificationCenter = notificationCenter
        Task {
            await checkAuthorizationStatus()
        }
	}
    
    //Vérifier l'état actuel des autorisations
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            self.isAuthorized = true
            self.error = nil
            
        case .denied:
            self.isAuthorized = false
            self.error = .notificationPermissionDenied
            cancelAllNotifications()
        case .notDetermined:
            self.isAuthorized = false
            self.error = nil
        case .ephemeral:
            // Cas spécifique aux App Clips
            self.isAuthorized = false
            
        @unknown default:
            // Gestion des futurs cas ajoutés par Apple
            self.isAuthorized = false
        }
    }
	
    func requestAndScheduleNotifications() async {
        // D'abord vérifier l'état actuel
        let settings = await notificationCenter.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            // Déjà autorisé, rien à faire
            self.isAuthorized = true
            self.error = nil
            return
            
        case .denied:
            // L'utilisateur a déjà refusé
            self.isAuthorized = false
            self.error = .notificationPermissionDenied
            cancelAllNotifications()
            return
            
        case .notDetermined:
            break
            
        case .ephemeral:
            self.isAuthorized = false
            self.error = .notificationPermissionDenied
            return
            
        @unknown default:
            self.isAuthorized = false
            return
        }
        
        // Demander l'autorisation (seulement si notDetermined)
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            
            if granted {
                self.isAuthorized = true
                self.error = nil
            } else {
                //  L'utilisateur vient de refuser
                self.isAuthorized = false
                self.error = .notificationPermissionDenied
                cancelAllNotifications()
            }
            
        } catch {
            self.isAuthorized = false
            self.error = .notificationAuthorizationFailed
        }
    }
    
    func scheduleNotifications(for type: MaintenanceType, until endDate: Date) {
        guard isAuthorized else {
            return
        }

        // Annule les notifications existantes pour ce type
        cancelNotifications(for: type)
        
        let calendar = Calendar.current
        var notificationCount = 0
        
        let frequencyInDays = type.frequencyInDays
        // Obtenir les paliers de rappel adaptés à cette fréquence
            let schedules = ReminderSchedule.schedules(for: frequencyInDays)
        
        // Pour chaque palier de rappel (J-30 et J-7)
        for schedule in schedules {
            // Calculer la date de notification
            guard let notificationDate = calendar.date(
                byAdding: .day,
                value: -schedule.daysBeforeMaintenance,
                to: endDate
            ) else { continue }
            
            // Vérifier si cette date est dans le futur
            if notificationDate > Date() {
                scheduleNotification(
                    for: type,
                    on: notificationDate,
                    schedule: schedule
                )
                notificationCount += 1
            }
        }
    }
    
    private func scheduleNotification(
        for type: MaintenanceType,
        on date: Date,
        schedule: ReminderSchedule
    ) {
        let content = UNMutableNotificationContent()
        content.title = schedule.title
        content.body = schedule.body(for: type)
        content.sound = schedule.sound
        content.categoryIdentifier = "MAINTENANCE_REMINDER"
        
        // Badge et criticité pour J-7
        if schedule == .finalWeek {
            content.badge = 1
            content.sound = .default // iOS 15+
        }
        
        // Métadonnées utiles si quand on clique sur la notif on va direct sur la page associée à la maintenance
        /*content.userInfo = [
            "maintenanceType": type.id,
            "schedule": schedule.daysBeforeMaintenance,
            "maintenanceDate": date.timeIntervalSince1970
        ]*/
        
        // Fixer l'heure à 9h00
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        components.minute = 0
        components.second = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        
        // Identifiant unique
        let identifier = "\(type.id)-\(schedule.daysBeforeMaintenance)-\(Int(date.timeIntervalSince1970))"
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                let appError = AppError.notificationSchedulingFailed(error)
            }
        }
    }

    
    func cancelNotifications(for type: MaintenanceType) {
        let center = notificationCenter
        center.getPendingNotificationRequests { requests in
            // Filtrer toutes les notifications qui commencent par le type.id
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix("\(type.id)-") }
                .map { $0.identifier }
            
            center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
        
    func cancelAllNotifications() {
        // D'abord annuler les notifications système
        notificationCenter.removeAllPendingNotificationRequests()

        // Ensuite désactiver UNIQUEMENT les rappels actifs dans CoreData
        for maintenance in maintenanceVM.maintenances where maintenance.reminder {
            maintenanceVM.toggleReminder(for: maintenance.id, value: false)
        }
    }
	
    func updateReminder(for maintenanceID: UUID, value: Bool) {
        guard let maintenance = maintenanceVM.maintenances.first(where: { $0.id == maintenanceID }) else {
            return
        }
        let type = maintenance.maintenanceType
        if value {
            guard isAuthorized else {
                self.showSettingsAlert = true
                maintenanceVM.toggleReminder(for: maintenanceID, value: false)
                self.error = .notificationPermissionDenied
                return
            }
            
            guard let nextDate = maintenanceVM.nextMaintenanceDate(for: type) else {
                return
            }
            
            let calendar = Calendar.current
            let daysRemaining = calendar.dateComponents([.day], from: Date(), to: nextDate).day ?? 0
            
            if daysRemaining > 0 {
                scheduleNotifications(for: type, until: nextDate)
            }
            
        } else {
            cancelNotifications(for: type)
        }
    }
    
//ouvre les reglages de l'iphone quand l'utilisateur veut mettre sur on le toggle alors qu'il n'a pas accepté les notifs
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

extension UNUserNotificationCenter: NotificationCenterProtocol {}
