//
//  DoneMaintenanceRow.swift
//  CarCare
//
//  Created by Ordinateur elena on 30/08/2025.
//

import SwiftUI

struct DoneMaintenanceRow: View {
	let maintenance: Maintenance
	let formatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .medium
		df.timeStyle = .none
		df.locale = Locale.current  
		return df
	}()
	
    var body: some View {
		HStack {
			Text("\(maintenance.maintenanceType.localizedName)")
				.bold()
			Spacer()
			Text("\(formatter.string(from: maintenance.date))")
		}
		.padding(.trailing, 20)
		.foregroundColor(Color("TextColor"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(maintenance.maintenanceType.localizedName)")
        .accessibilityValue("Completed on \(formatter.string(from: maintenance.date))")
    }
}

struct DoneMaintenanceRow_Previews: PreviewProvider {
    static var previews: some View {
        DoneMaintenanceRow(
            maintenance: Maintenance(
                id: UUID(),
                maintenanceType: .BleedHydraulicBrakes,
                date: Date(),
                customFrequencyInDays: nil
            )
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
