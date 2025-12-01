//
//  AuthorizationStatus.swift
//  CarCare
//
//  Created by Ordinateur elena on 01/12/2025.
//

import UserNotifications

// enum native iOS - pas besoin de le créer
public enum UNAuthorizationStatus : Int, Sendable {
    case notDetermined = 0  // L'utilisateur n'a pas encore été sollicité
    case denied = 1          // L'utilisateur a refusé
    case authorized = 2      // Autorisé
    case provisional = 3     // Autorisation provisoire (iOS 12+)
    case ephemeral = 4       // Notifications éphémères (App Clips, iOS 14+)
}
