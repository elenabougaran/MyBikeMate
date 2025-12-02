//
//  MaintenanceDetailsVM.swift
//  CarCare
//
//  Created by Ordinateur elena on 02/09/2025.
//

import Foundation

final class MaintenanceDetailsVM: ObservableObject {
	private let maintenanceVM: MaintenanceVM
	private let maintenanceLoader: LocalMaintenanceLoader
	@Published var error: AppError?
	@Published var showAlert: Bool = false
	@Published var daysUntilNextMaintenance: Int?
	@Published var maintenancesForOneType: [Maintenance] = []
	
	init(maintenanceLoader: LocalMaintenanceLoader = DependencyContainer.shared.MaintenanceLoader, maintenanceVM: MaintenanceVM) {
		self.maintenanceLoader = maintenanceLoader
		self.maintenanceVM = maintenanceVM
	}
	
	/*func calculateDaysUntilNextMaintenance(type: MaintenanceType) -> Int? {
		guard let nextDate = calculateNextMaintenanceDate(for: type) else { return nil}
		return Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day
	}*/
    func calculateDaysUntilNextMaintenance(type: MaintenanceType) -> Int? {
        guard let nextDate = calculateNextMaintenanceDate(for: type) else { return nil }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextDay = calendar.startOfDay(for: nextDate)
        
        return calendar.dateComponents([.day], from: today, to: nextDay).day
    }
	
	func calculateNextMaintenanceDate(for type: MaintenanceType) -> Date? {
		guard let lastMaintenance = getLastMaintenance(of: type) else { return nil }
		guard type.frequencyInDays > 0 else { return nil} // Pas de prochaine date pour Unknown
		return Calendar.current.date(byAdding: .day, value: type.frequencyInDays, to: lastMaintenance.date)
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

