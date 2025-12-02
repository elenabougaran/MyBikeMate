//
//  LocalMaintenance.swift
//  CarCare
//
//  Created by Ordinateur elena on 15/07/2025.
//

import Foundation

struct LocalMaintenance {
	let id: UUID
	let maintenanceType: String
	let date: Date
	let reminder: Bool
    let frequencyInDays: Int?
}
