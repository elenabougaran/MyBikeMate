//
//  MaintenanceType.swift
//  CarCare
//
//  Created by Ordinateur elena on 20/08/2025.
//
import Foundation

enum MaintenanceType: String, CaseIterable, Identifiable {
	var id: String { rawValue }
	
	case CheckTirePressure = "check_tire_pressure"
	case ReplaceTires = "replace_tires"
	case CleanAndLubricateChain = "clean_and_lubricate_chain"
	case TightenMainScrewsAndBolts = "tighten_main_screws_and_bolts"
	case CleanDrivetrain = "clean_drivetrain"
	case LubricateCablesAndHousings = "lubricate_cables_and_housings"
	case GreaseBottomBracket = "grease_bottom_bracket"
	case ReplaceCablesAndHousings = "replace_cables_and_housings"
	case BleedHydraulicBrakes = "bleed_hydraulic_brakes"
	case ServiceBearings = "service_bearings"
	case ReplaceChain = "replace_chain"
	case RunSoftwareAndBatteryDiagnostics = "run_software_and_battery_diagnostics"
	case Unknown = "unknown"
	
	var frequencyInDays: Int {
		switch self {
		case .CheckTirePressure: return 7
		case .ReplaceTires: return 180
		case .CleanAndLubricateChain: return 30
		case .TightenMainScrewsAndBolts: return 30
		case .CleanDrivetrain: return 90
		case .LubricateCablesAndHousings: return 180
		case .GreaseBottomBracket: return 180
		case .ReplaceCablesAndHousings: return 365
		case .BleedHydraulicBrakes: return 365
		case .ServiceBearings: return 365
		case .ReplaceChain: return 365
		case .RunSoftwareAndBatteryDiagnostics: return 365
		case .Unknown: return 0
		}
	}
	
	var iconName: String {
		switch self {
		case .CheckTirePressure: return "wheels"
		case .ReplaceTires: return "wheels"
		case .CleanAndLubricateChain: return "chain"
		case .TightenMainScrewsAndBolts: return "screw"
		case .CleanDrivetrain: return "derailleur"
		case .LubricateCablesAndHousings: return "cables"
		case .GreaseBottomBracket: return "bracket"
		case .ReplaceCablesAndHousings: return "cables"
		case .BleedHydraulicBrakes: return "braking-system"
		case .ServiceBearings: return "bearing"
		case .ReplaceChain: return "chain"
		case .RunSoftwareAndBatteryDiagnostics: return "battery" 
		case .Unknown: return "questionmark.circle"
		}
	}
}

extension MaintenanceType: Hashable {
    /*var readableFrequency: String {
        if frequencyInDays < 30 {
            return String(format: NSLocalizedString("every_x_days", comment: ""), frequencyInDays)
        } else if frequencyInDays > 364 {
            let years = frequencyInDays / 365
            if years == 1 {
                return NSLocalizedString("every_1_year", comment: "")
            }
            return String(format: NSLocalizedString("every_x_years", comment: ""), years)
        } else {
            let months = frequencyInDays / 30
            return String(format: NSLocalizedString("every_x_months", comment: ""), months)
        }
    }*/

	
	var localizedName: String {
		NSLocalizedString(rawValue, comment: "")
	}
	
	var localizedDescription: String {
		return MaintenanceDescription.mapping[self] ?? NSLocalizedString(LocalizationKeys.unknownDescription, comment: "")
	}
}

extension MaintenanceType {
	init(fromCoreDataString string: String) {
		self = MaintenanceType(rawValue: string) ?? .Unknown
	}
}
