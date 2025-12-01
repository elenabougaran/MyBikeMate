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
        // ✅ Utilisez votre protocol
        let settings = await notificationCenter.notificationSettings()
        
        // ✅ UNAuthorizationStatus est l'enum natif d'iOS
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            self.isAuthorized = true
            self.error = nil
            
        case .denied:
            self.isAuthorized = false
            self.error = .notificationPermissionDenied
            cancelAllNotifications()
            
            #if DEBUG
            print("❌ Notifications refusées par l'utilisateur")
            #endif
            
        case .notDetermined:
            self.isAuthorized = false
            self.error = nil
            
            #if DEBUG
            print("⏳ Notifications non encore demandées")
            #endif
            
        case .ephemeral:
            // Cas spécifique aux App Clips
            self.isAuthorized = false
            
        @unknown default:
            // Gestion des futurs cas ajoutés par Apple
            self.isAuthorized = false
            
            #if DEBUG
            print("⚠️ Statut de notification inconnu")
            #endif
        }
    }
	
    func requestAndScheduleNotifications() async {
        // 1️⃣ D'abord vérifier l'état actuel
        let settings = await notificationCenter.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            // ✅ Déjà autorisé, rien à faire
            self.isAuthorized = true
            self.error = nil
            
            #if DEBUG
            print("✅ Notifications déjà autorisées")
            #endif
            return
            
        case .denied:
            // ❌ L'utilisateur a déjà refusé
            self.isAuthorized = false
            //self.showSettingsAlert = true
            self.error = .notificationPermissionDenied
            cancelAllNotifications()
            
            #if DEBUG
            print("❌ Notifications déjà refusées - impossible de redemander")
            #endif
            return
            
        case .notDetermined:
            // ⏳ Pas encore demandé, on peut demander
            break
            
        case .ephemeral:
            self.isAuthorized = false
           // self.showSettingsAlert = true
            self.error = .notificationPermissionDenied
            return
            
        @unknown default:
            self.isAuthorized = false
            return
        }
        
        // 2️⃣ Demander l'autorisation (seulement si notDetermined)
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            
            if granted {
                self.isAuthorized = true
                self.error = nil
                
                #if DEBUG
                print("✅ Autorisation accordée")
                #endif
                
            } else {
                // ❌ L'utilisateur vient de refuser
                self.isAuthorized = false
                //self.showSettingsAlert = true 
                self.error = .notificationPermissionDenied
                cancelAllNotifications()
                
                #if DEBUG
                print("❌ Autorisation refusée par l'utilisateur")
                #endif
            }
            
        } catch {
            // ⚠️ Erreur système lors de la demande
            self.isAuthorized = false
            self.error = .notificationAuthorizationFailed
            
            #if DEBUG
            print("❌ Erreur lors de la demande d'autorisation : \(error.localizedDescription)")
            #endif
        }
    }
    
    func scheduleNotifications(for type: MaintenanceType, until endDate: Date) {
        guard isAuthorized else {
            print("❌ Notifications non autorisées")
            return
        }

        // Annule les notifications existantes pour ce type
        cancelNotifications(for: type)
        
        let calendar = Calendar.current
        var notificationCount = 0
        
        let frequencyInDays = type.frequencyInDays
        // ✅ Obtenir les paliers de rappel adaptés à cette fréquence
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
                
                #if DEBUG
                let daysUntilNotif = calendar.dateComponents([.day], from: Date(), to: notificationDate).day ?? 0
                print("📅 Notification J-\(schedule.daysBeforeMaintenance) planifiée")
                print("   Date : \(notificationDate.formatted(date: .abbreviated, time: .shortened))")
                print("   Dans : \(daysUntilNotif) jours")
                #endif
            } else {
                #if DEBUG
                print("⏭️ Notification J-\(schedule.daysBeforeMaintenance) déjà passée")
                #endif
            }
        }
        
        print("✅ \(notificationCount) notification(s) planifiée(s) pour \(type.localizedName)")
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
                print("❌ Erreur planification : \(error.localizedDescription)")
            } else {
                #if DEBUG
                print("✅ Notification ajoutée : \(identifier)")
                #endif
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
            
            print("🗑️ Suppression de \(identifiersToRemove.count) notifications pour \(type.localizedName)")
            center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            //notificationCenter.removePendingNotificationRequests(withIdentifiers: [type.id])
        }
    }
        
    func cancelAllNotifications() {
        // 1️⃣ D'abord annuler les notifications système
        notificationCenter.removeAllPendingNotificationRequests()
#if DEBUG
        print("🗑️ Toutes les notifications système annulées")
#endif
        // 2️⃣ Ensuite désactiver UNIQUEMENT les rappels actifs dans CoreData
        for maintenance in maintenanceVM.maintenances where maintenance.reminder {
            maintenanceVM.toggleReminder(for: maintenance.id, value: false)
            
#if DEBUG
            print("🔕 Rappel désactivé pour \(maintenance.maintenanceType.localizedName)")
#endif
        }
        
#if DEBUG
        print("✅ Tous les rappels désactivés")
#endif
    }
	
    func updateReminder(for maintenanceID: UUID, value: Bool) {
        guard let maintenance = maintenanceVM.maintenances.first(where: { $0.id == maintenanceID }) else {
            print("⚠️ Maintenance introuvable")
            return
        }
        
        let type = maintenance.maintenanceType

        if value {
            guard isAuthorized else {
                print("⚠️ Notifications non autorisées")
                self.showSettingsAlert = true
                maintenanceVM.toggleReminder(for: maintenanceID, value: false)
                self.error = .notificationPermissionDenied
                return
            }
            
            guard let nextDate = maintenanceVM.nextMaintenanceDate(for: type) else {
                print("⚠️ Aucune date de maintenance trouvée")
                return
            }
            
            let calendar = Calendar.current
            let daysRemaining = calendar.dateComponents([.day], from: Date(), to: nextDate).day ?? 0
            
            if daysRemaining > 0 {
                print("✅ Activation des rappels pour \(type.localizedName)")
                print("📅 Maintenance le : \(nextDate.formatted(date: .long, time: .omitted))")
                print("⏱️ Dans \(daysRemaining) jours")
                
                scheduleNotifications(for: type, until: nextDate)
            } else {
                print("⚠️ La maintenance est déjà passée")
            }
            
        } else {
            print("🔕 Désactivation des rappels pour \(type.localizedName)")
            cancelNotifications(for: type)
        }
    }
    
//ouvre les reglages de l'iphone quand l'utilisateur veut mettre sur on le toggle alors qu'il n'a pas accepté les notifs
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            #if DEBUG
            print("❌ Impossible d'ouvrir les Réglages")
            #endif
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
            
            #if DEBUG
            print("📱 Ouverture des Réglages iOS")
            #endif
        }
    }
}

extension UNUserNotificationCenter: NotificationCenterProtocol {}
