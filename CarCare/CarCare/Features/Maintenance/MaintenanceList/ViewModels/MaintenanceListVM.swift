//
//  MaintenanceVM.swift
//  CarCare
//
//  Created by Ordinateur elena on 30/08/2025.
//

import Foundation

class MaintenanceListVM: ObservableObject {
	private let maintenanceVM: MaintenanceVM
	private let maintenanceLoader: LocalMaintenanceLoader
	@Published var error: AppError?
	@Published var showAlert: Bool = false
	
	init(maintenanceLoader: LocalMaintenanceLoader = DependencyContainer.shared.MaintenanceLoader, maintenanceVM: MaintenanceVM) {
		self.maintenanceLoader = maintenanceLoader
		self.maintenanceVM = maintenanceVM
	}
	
	func sortMaintenanceKeys(from maintenances: [Maintenance]) -> [MaintenanceType] {
		let lastByType = Dictionary(grouping: maintenances, by: { $0.maintenanceType })
			.compactMapValues { $0.max(by: { $0.date < $1.date }) }
			.filter { $0.key != .Unknown }

		return Array(lastByType.keys).sorted { $0.rawValue < $1.rawValue }
	}
	
	func calculateNumberOfMaintenance() -> Int {
		return maintenanceVM.maintenances.count
	}
	
	func calculateDaysUntilNextMaintenance(type: MaintenanceType) -> Int? {
		guard let nextDate = calculateNextMaintenanceDate(for: type) else { return nil}
		return Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day
	}
	
    func calculateNextMaintenanceDate(for type: MaintenanceType) -> Date? {
        guard let lastMaintenance = getLastMaintenance(of: type) else { return nil }
        
        let frequency = lastMaintenance.effectiveFrequencyInDays
        guard frequency > 0 else { return nil }
        
        return Calendar.current.date(byAdding: .day, value: frequency, to: lastMaintenance.date)
    }
    
    func getEffectiveFrequency(for type: MaintenanceType) -> Int {
        guard let lastMaintenance = getLastMaintenance(of: type) else {
            return type.frequencyInDays // Fallback sur la fréquence par défaut
        }
        return lastMaintenance.effectiveFrequencyInDays
    }
    
    func getLastMaintenance(of type: MaintenanceType) -> Maintenance? {
		let filtered = maintenanceVM.maintenances.filter { $0.maintenanceType == type }
		return filtered.max(by: { $0.date < $1.date })
	}
	
	func fetchAllMaintenanceForOneType(type: MaintenanceType) -> [Maintenance] {
		do {
			let allMaintenance = try maintenanceLoader.load()
			return allMaintenance.filter { $0.maintenanceType == type }
		} catch let error as LoadingCocoaError { //erreurs de load
			self.error = AppError.loadingDataFailed(error)
			showAlert = true
		} catch let error as StoreError { //erreurs de CoreDataManager
			self.error = AppError.dataUnavailable(error)
			showAlert = true
		} catch let error as FetchCocoaError {
			self.error = AppError.fetchDataFailed(error)
			showAlert = true
		} catch {
			self.error = AppError.unknown
			showAlert = true
		}
		return []
	}
	
}
