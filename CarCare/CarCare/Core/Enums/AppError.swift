//
//  AppError.swift
//  CarCare
//
//  Created by Ordinateur elena on 25/08/2025.
//

import Foundation

enum AppError: Error, LocalizedError {
	// Erreurs liées aux données
	case bikeLoadFailed(Error) // erreur du AppState
	case dataUnavailable(StoreError) //mapping des erreurs StoreError pour que les erreurs soient compréhensibles par l'utilisateur
	case loadingDataFailed(LoadingCocoaError) //mapping des erreurs CocoaError pour que les erreurs soient compréhensibles par l'utilisateur
	case fetchDataFailed(FetchCocoaError)
	case saveDataFailed(SaveCocoaError)
	
	//Erreurs liées aux notifications
    case notificationPermissionDenied //Utilisateur a refusé les notifs
    case notificationAuthorizationFailed //Erreur systeme lors de la demande d'autorisation
    case notificationSchedulingFailed(Error) //Erreur lors de la planificiation d'une notif
	case notificationError(Error) //Erreur générique de notif
    
	//case notificationNotAuthorized
    case notificationFailed(String)
	
	case bikeNotFound
    
    case pdfError(PDFError)
    
	case unknown
	
}

extension AppError {
	var localizedDescription: String {
		switch self {
		case .bikeLoadFailed(_):
			return NSLocalizedString("bike_load_failed", comment: "Error occurred while loading the bike") //fait appel à la trad en plsrs langues
		case .dataUnavailable(_):
			return NSLocalizedString("data_unavailable", comment: "Data unavailable")
		case .loadingDataFailed(let cocoaError):
			let format = NSLocalizedString("loading_data_failed", comment: "Error occurred while loading data")
			return String(format: format, cocoaError.localizedDescription)
		case .fetchDataFailed(let fetchCocoaError):
			let format = NSLocalizedString("fetch_data_failed", comment: "Error occurred while fetching data")
			return String(format: format, fetchCocoaError.localizedDescription)
		case .saveDataFailed(let saveCocoaError):
			let format = NSLocalizedString("save_data_failed", comment: "Error occurred while saving data")
			return String(format: format, saveCocoaError.localizedDescription)
        case .notificationPermissionDenied:
            return NSLocalizedString("notification_permission_denied", comment: "User denied notification permissions")
            
        case .notificationAuthorizationFailed:
            return NSLocalizedString("notification_authorization_failed", comment: "Failed to request notification authorization")
            
        case .notificationSchedulingFailed(let error):
            let format = NSLocalizedString("notification_scheduling_failed", comment: "Failed to schedule notification")
            return String(format: format, error.localizedDescription)
            
        case .notificationError(let error):
            let format = NSLocalizedString("notification_error", comment: "Notification error occurred")
            return String(format: format, error.localizedDescription)
            //case .notificationNotAuthorized:
            //return NSLocalizedString("notification_not_authorized", comment: "Notifications not authorized")
        case .notificationFailed(let message):
            return message.isEmpty ? NSLocalizedString("notification_failed", comment: "") : message
        case .bikeNotFound:
            return NSLocalizedString("bike_not_found", comment: "")
        case .pdfError(let pdfError):
            switch pdfError {
            case .writingFailed:
                return NSLocalizedString("pdf_writing_failed", comment: "")
            }
		case .unknown:
			return NSLocalizedString("unknown_error_message", comment: "Unexpected error occurred")
		}
	}
}

enum StoreError: Error, Equatable { //CoreData
	case modelNotFound
	case failedToLoadPersistentContainer(Error)
	
	static func == (lhs: StoreError, rhs: StoreError) -> Bool {
		switch (lhs, rhs) {
		case (.modelNotFound, .modelNotFound):
			return true
		case (.failedToLoadPersistentContainer, .failedToLoadPersistentContainer):
			return true // on ignore l'Error associé
		default:
			return false
		}
	}
}

enum LoadingCocoaError: Error {
	case migrationNeeded       // persistentStoreIncompatibleVersionHash / persistentStoreIncompatibleSchema
	case storeOpenFailed       // persistentStoreOpen, persistentStoreTimeout
	case saveFailed            // persistentStoreSave, persistentStoreSaveConflicts
	case validationFailed      // validationMissingMandatoryProperty, validationNumberTooLarge, etc.
	case unknown               // toutes les autres erreurs
}

enum FetchCocoaError: Error {
	case storeOpenFailed       // persistentStoreOpen, persistentStoreTimeout
	case unknown
}

enum SaveCocoaError: Error {
	case saveFailed            // persistentStoreSave, persistentStoreSaveConflicts
	case validationFailed      // validationMissingMandatoryProperty, validationNumberTooLarge/TooSmall, validationStringTooLong/TooShort
	case unknown               // toutes les autres erreurs liées au save
}

enum PDFError: Error {
    case writingFailed(String)
}
