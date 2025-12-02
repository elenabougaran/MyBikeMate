//
//  ReminderSchedule.swift
//  CarCare
//
//  Created by Ordinateur elena on 01/12/2025.
//
import UserNotifications

enum ReminderSchedule: Equatable {
    case monthBefore    // J-30
    case twoWeeksBefore // J-14
    case finalWeek      // J-7
    case threeDays      // J-3
    case twoDays        // J-2
    
    var daysBeforeMaintenance: Int {
        switch self {
        case .monthBefore: return 30
        case .twoWeeksBefore: return 14
        case .finalWeek: return 7
        case .threeDays: return 3
        case .twoDays: return 2
        }
    }
    
    var title: String {
        switch self {
        case .monthBefore:
            return "📌 Maintenance à venir"
        case .twoWeeksBefore:
            return "📋 Maintenance dans 2 semaines"
        case .finalWeek:
            return "📅 Maintenance dans 1 semaine"
        case .threeDays:
            return "🔔 Rappel de maintenance"
        case .twoDays:
            return "⚠️ Maintenance imminente"
        }
    }
    
    func body(for type: MaintenanceType) -> String {
        switch self {
        case .monthBefore:
            return "\(type.localizedName) dans 30 jours"
        case .twoWeeksBefore:
            return "\(type.localizedName)"
        case .finalWeek:
            return "\(type.localizedName) prévu(e) dans 7 jours"
        case .threeDays:
            return "Dans 3 jours : \(type.localizedName)"
        case .twoDays:
            return "Dans 2 jours : \(type.localizedName)"
        }
    }
    
    var sound: UNNotificationSound {
        switch self {
        case .twoDays:
            return .defaultCritical  // Son critique pour J-2
        default:
            return .default
        }
    }
    
    /// ✅ Retourne les paliers de rappel selon la fréquence de la maintenance
    static func schedules(for frequencyInDays: Int) -> [ReminderSchedule] {
        switch frequencyInDays {
        case ...7:
            // Maintenance hebdomadaire ou moins → J-2 uniquement
            return [.twoDays]
            
        case 8...14:
            // Maintenance bi-hebdomadaire → J-3
            return [.threeDays]
            
        case 15...30:
            // Maintenance mensuelle → J-7 et J-3
            return [.finalWeek, .threeDays]
            
        case 31...90:
            // Maintenance trimestrielle → J-30 et J-7
            return [.monthBefore, .finalWeek]
            
        default:
            // Maintenance longue durée → J-30 et J-7
            return [.monthBefore, .finalWeek]
        }
    }
}
