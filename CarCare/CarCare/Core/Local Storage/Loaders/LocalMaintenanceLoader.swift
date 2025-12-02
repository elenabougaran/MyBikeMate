//
//  LocalMaintenanceLoader.swift
//  CarCare
//
//  Created by Ordinateur elena on 22/07/2025.
//

import Foundation

class LocalMaintenanceLoader {
	
	private let store: MaintenanceStore
	
	init(store: MaintenanceStore) {
		self.store = store
	}
	
	func load() throws -> [Maintenance] {
		try store.retrieve().toModels()
	}
	
	func save(_ maintenance: Maintenance) throws {
		try store.insert(maintenance.toLocal())
	}
	
	func update(_ maintenance: Maintenance) throws {
		try store.update(maintenance.toLocal())
	}
	
	func deleteAll() throws {
		try store.deleteAll()
	}
	
	func deleteOne(_ maintenance: Maintenance) throws {
		try store.deleteOne(maintenance.toLocal())
	}
}

extension Array where Element == LocalMaintenance {
	func toModels() -> [Maintenance] {
        map { Maintenance(id: $0.id, maintenanceType: MaintenanceType(fromCoreDataString: $0.maintenanceType), date: $0.date, reminder: $0.reminder, customFrequencyInDays: $0.frequencyInDays) }
	}
}

extension Maintenance {
	func toLocal() -> LocalMaintenance {
        LocalMaintenance(id: id, maintenanceType: maintenanceType.rawValue, date: date, reminder: reminder, frequencyInDays: customFrequencyInDays)
	}
}
