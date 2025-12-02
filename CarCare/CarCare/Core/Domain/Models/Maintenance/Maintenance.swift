//
//  Maintenance.swift
//  CarCare
//
//  Created by Ordinateur elena on 15/07/2025.
//

import Foundation

struct Maintenance: Equatable, Identifiable, Hashable {
	let id: UUID
	let maintenanceType : MaintenanceType
	let date : Date
	var reminder: Bool
    var customFrequencyInDays: Int?
    var effectiveFrequencyInDays: Int {
        customFrequencyInDays ?? maintenanceType.frequencyInDays //si pas de freq entrée par l'utilisateur -> on prend celle de l'énum
    }
    
    init(
        id: UUID = UUID(),
        maintenanceType: MaintenanceType,
        date: Date,
        reminder: Bool = false,
        customFrequencyInDays: Int? = nil
    ) {
        self.id = id
        self.maintenanceType = maintenanceType
        self.date = date
        self.reminder = reminder
        self.customFrequencyInDays = customFrequencyInDays
    }
}
