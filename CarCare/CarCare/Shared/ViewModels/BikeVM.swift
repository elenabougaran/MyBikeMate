//
//  BikeVM.swift
//  CarCare
//
//  Created by Ordinateur elena on 20/08/2025.
//

import Foundation
import UIKit

class BikeVM: ObservableObject {
	//MARK: -Public properties
	@Published var model: String = ""
	@Published var brand: String = ""
	@Published var mileage: Int = 0
	@Published var year: Int = 0
	@Published var bike: Bike? = nil 
	@Published var bikeType: BikeType = .Manual
	@Published var identificationNumber: String = ""
	@Published var error: AppError?
	@Published var showAlert: Bool = false

	//MARK: -Private properties
	private let bikeLoader: LocalBikeLoader
	private let notificationVM: NotificationViewModel
	
	//MARK: -Initialization
	init(bikeLoader: LocalBikeLoader = DependencyContainer.shared.BikeLoader, notificationVM: NotificationViewModel) {
		self.bikeLoader = bikeLoader
		self.notificationVM = notificationVM
	}
	
	//MARK: -Methods
	//synchronise bike et les published
	func fetchBikeData(completion: (() -> Void)? = nil) {
		DispatchQueue.global(qos: .userInitiated).async { //charge en arrière plan donc ne bloque pas l'UI
			do {
				guard let unwrappedBike = try self.bikeLoader.load() else {
					throw AppError.bikeNotFound
				}
				DispatchQueue.main.async { // tout mettre à jour en une fois pour éviter création de la vue plusieurs fois
					self.model = unwrappedBike.model
					self.brand = unwrappedBike.brand
					self.year = unwrappedBike.year
					self.bikeType = unwrappedBike.bikeType
					self.identificationNumber = unwrappedBike.identificationNumber
					self.bike = unwrappedBike
                    
                    if unwrappedBike.imageData != nil {
                    } else {
                    }
					completion?()
				}
			} catch let error as LoadingCocoaError { //erreurs de load
				DispatchQueue.main.async {
					self.error = AppError.loadingDataFailed(error)
					self.showAlert = true
				}
			} catch let error as StoreError { //erreurs de CoreDataManager
				DispatchQueue.main.async {
					self.error = AppError.dataUnavailable(error)
					self.showAlert = true
				}
			} catch let error as FetchCocoaError {
				DispatchQueue.main.async {
					self.error = AppError.fetchDataFailed(error)
					self.showAlert = true
				}
			} catch {
				DispatchQueue.main.async {
					self.error = AppError.unknown
					self.showAlert = true
				}
			}
		}
	}
	
    func modifyBikeInformations(brand: String, model: String, year: Int, type: BikeType, identificationNumber: String, image: UIImage?) {
		guard bike != nil else { return }
			bike!.brand = brand
			bike!.model = model
			bike!.year = year
			bike!.bikeType = type
			bike!.identificationNumber = identificationNumber
        // Convertir UIImage en Data
           if let image = image {
               bike!.imageData = image.jpegData(compressionQuality: 0.8)
           } else {
               bike!.imageData = nil
           }
		//met à jour les published après modif
		self.brand = brand
		self.model = model
		self.year = year
		self.bikeType = type
		self.identificationNumber = identificationNumber
		
		do {
			try bikeLoader.save(bike!)
		} catch let error as LoadingCocoaError { //erreurs de load
			self.error = AppError.loadingDataFailed(error)
			showAlert = true
		} catch let error as StoreError { //erreurs de CoreDataManager
			self.error = AppError.dataUnavailable(error)
			showAlert = true
		} catch let error as SaveCocoaError {
			self.error = AppError.saveDataFailed(error)
			showAlert = true
		} catch {
			self.error = AppError.unknown
			showAlert = true
		}
	}
	
    func addBike(brand: String, model: String, year: Int, type: BikeType, identificationNumber: String, image: UIImage?) -> Bool {
		var bike = Bike(id: UUID(), brand: brand, model: model, year: year, bikeType: type, identificationNumber: identificationNumber)

        if let img = image {
               bike.imageData = img.jpegData(compressionQuality: 0.8)
           }
        
		do {
			try bikeLoader.save(bike)
			return true
		} catch let error as LoadingCocoaError { //erreurs de load
			self.error = AppError.loadingDataFailed(error)
			showAlert = true
			return false
		} catch let error as StoreError { //erreurs de CoreDataManager
			self.error = AppError.dataUnavailable(error)
			showAlert = true
			return false
		} catch let error as SaveCocoaError {
			self.error = AppError.saveDataFailed(error)
			showAlert = true
			return false
		} catch {
			self.error = AppError.unknown
			showAlert = true
			return false
		}
	}
	
	func deleteCurrentBike() {
		do {
			guard let bike = bike else { return }
			try bikeLoader.delete(bike)
			self.bike = nil
		} catch let error as SaveCocoaError {
			self.error = AppError.saveDataFailed(error)
			showAlert = true
		} catch {
			self.error = AppError.unknown
			showAlert = true
		}
	}
}
