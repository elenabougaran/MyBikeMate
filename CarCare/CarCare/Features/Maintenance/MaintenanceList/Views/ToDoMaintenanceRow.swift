//
//  MaintenanceRow.swift
//  CarCare
//
//  Created by Ordinateur elena on 19/08/2025.
//

import SwiftUI

struct ToDoMaintenanceRow: View {
	@ObservedObject var VM: MaintenanceListVM
	let maintenanceType: MaintenanceType?
	let formatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .medium
		df.timeStyle = .none
		df.locale = Locale.current  
		return df
	}()
	
	var body: some View {
		if let maintenanceType = maintenanceType {
			let daysRemaining = VM.calculateDaysUntilNextMaintenance(type: maintenanceType)
			let nextDate = VM.calculateNextMaintenanceDate(for: maintenanceType)
            let effectiveFrequency = VM.getEffectiveFrequency(for: maintenanceType)
			
			HStack {
				VStack(alignment: .leading, spacing: 3) {
					Text("\(maintenanceType.localizedName)")
						.foregroundColor(Color("TextColor"))
						.font(.system(size: 18, weight: .bold, design: .default))
					
					VStack {
						if let daysRemaining = daysRemaining, daysRemaining >= 0 {
							   Text(String(format: NSLocalizedString("days_remaining_key", comment: "days remaining"), daysRemaining))
						   } else if let daysRemaining = daysRemaining, daysRemaining < 0 {
							   Text(String(format: NSLocalizedString("days_remaining_key", comment: "days remaining"), 0))
						   } else {
							   Text(NSLocalizedString("unknown_days_remaining_key", comment: "days remaining unknown"))
						   }
					}
					.foregroundColor(Color("TextColor"))
                    .font(.system(size: 18, weight: .regular, design: .default))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(maintenanceType.localizedName)
				
				Spacer()
				
				VStack(alignment: .trailing) {
					DaysIndicatorView(days: daysRemaining ?? 0, frequency: effectiveFrequency, rectangleWidth: 20, rectangleHeight: 10, triangleWidth: 5, triangleHeight: 5, spacing: 2)
					
					if let nextDate = nextDate {
						Text("\(formatter.string(from: nextDate))")
					} else {
						Text("Pas de date prévue")
					}
				}
				.foregroundColor(Color("TextColor"))
				.font(.system(size: 18, weight: .regular, design: .default))
			}
		}
	}
}

extension ToDoMaintenanceRow {
    private func accessibilityValue(daysRemaining: Int?, nextDate: Date?) -> String {
        var value = ""
        
        if let days = daysRemaining {
            value += String(format: NSLocalizedString("days_remaining_key", comment: "days remaining"), max(days, 0))
        } else {
            value += NSLocalizedString("unknown_days_remaining_key", comment: "days remaining unknown")
        }
        
        if let next = nextDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            value += ", " + formatter.string(from: next)
        }
        
        return value
    }
}
	
struct ToDoMaintenanceRow_Previews: PreviewProvider {

    class MockVM: MaintenanceListVM {
        override func calculateDaysUntilNextMaintenance(type: MaintenanceType) -> Int? { 50 }
        override func calculateNextMaintenanceDate(for type: MaintenanceType) -> Date? {
            Calendar.current.date(byAdding: .day, value: 50, to: Date())
        }
        override func getEffectiveFrequency(for type: MaintenanceType) -> Int { 180 }
    }

    static var previews: some View {
        ToDoMaintenanceRow(
            VM: MockVM(maintenanceVM: MaintenanceVM()),
            maintenanceType: .BleedHydraulicBrakes
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
