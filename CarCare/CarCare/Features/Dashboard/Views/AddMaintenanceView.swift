//
//  AddMaintenanceView.swift
//  CarCare
//
//  Created by Ordinateur elena on 16/08/2025.
//

import SwiftUI

struct AddMaintenanceView: View {
	@Environment(\.dismiss) private var dismiss
	@ObservedObject var bikeVM: BikeVM
	@ObservedObject var maintenanceVM: MaintenanceVM
	@ObservedObject var notificationVM: NotificationViewModel
	@StateObject private var VM: AddMaintenanceVM
	@State private var showPaywall = false
	@AppStorage("isPremiumUser") private var isPremiumUser = false
	@State var showingDatePicker: Bool = false
	var onAdd: () -> Void
    let haptic = UIImpactFeedbackGenerator(style: .medium)
	
	let formatter: DateFormatter = {
		let df = DateFormatter()
		df.dateStyle = .medium   // format type "27 août 2025"
		df.timeStyle = .none     // on n'affiche pas l'heure
		df.locale = Locale.current
		return df
	}()
	
	init(bikeVM: BikeVM, maintenanceVM: MaintenanceVM, onAdd: @escaping () -> Void, notificationVM: NotificationViewModel) {
		self.bikeVM = bikeVM
		self.maintenanceVM = maintenanceVM
		self.onAdd = onAdd
		self.notificationVM = notificationVM
		_VM = StateObject(wrappedValue: AddMaintenanceVM(maintenanceVM: maintenanceVM, notificationVM: notificationVM))
	}
	
	var body: some View {
		VStack {
			VStack(spacing: 20) {
				VStack {
					Text(NSLocalizedString("maintenance_Type_key", comment: ""))
						.font(.system(size: 16, weight: .bold, design: .default))
						.foregroundColor(Color("TextColor"))
						.frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)
					
					Picker("Type", selection: $VM.selectedMaintenanceType) {
						ForEach(VM.filteredMaintenanceTypes(for: bikeVM.bikeType), id: \.self) { maintenanceType in
							Text(maintenanceType.localizedName).tag(maintenanceType)
								.font(.system(size: 16, weight: .regular, design: .default))
						}
					}
					.tint(Color("TextColor"))
					.pickerStyle(MenuPickerStyle())
					.frame(maxWidth: .infinity, alignment: .leading)
					.frame(height: 40)
					.background(Color("InputSurfaceColor"))
					.cornerRadius(10)
                    .accessibilityLabel("Maintenance Type")
                    .accessibilityValue(VM.selectedMaintenanceType.localizedName)
                    .accessibilityHint("Double tap to select the type of maintenance")
				}
				
				VStack {
					Text(NSLocalizedString("maintenance_date_key", comment: ""))
						.font(.system(size: 16, weight: .bold, design: .default))
						.foregroundColor(Color("TextColor"))
						.frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)
					
					Button(action: { showingDatePicker = true }) {
						HStack {
							Text(formatter.string(from: VM.selectedMaintenanceDate ?? Date()))
								.foregroundColor(Color("TextColor"))
								.font(.system(size: 16, weight: .regular, design: .default))

							Spacer()
							
							Image(systemName: "calendar")
								.foregroundColor(.gray)
						}
						.padding(.horizontal, 10)
						.frame(height: 40)
						.background(Color("InputSurfaceColor"))
						.cornerRadius(10)
					}
                    .accessibilityLabel("Maintenance Date")
                    .accessibilityValue(formatter.string(from: VM.selectedMaintenanceDate ?? Date()))
                    .accessibilityHint("Double tap to choose a date for the maintenance")
				}
			}
			
			Spacer()
			
			PrimaryButton(title: NSLocalizedString("button_Add_Maintenance", comment: ""), foregroundColor: .white, backgroundColor: Color("AppPrimaryColor")) {
                haptic.impactOccurred()
				//if isPremiumUser || maintenanceVM.maintenances.count < 3 {
					VM.addMaintenance(bikeType: bikeVM.bikeType)
					onAdd() //pour recharger la dernière maintenance dans Dashboard
					dismiss()
				/*} else {
					showPaywall = true // Afficher un sheet ou alert
				}*/
			}
            .accessibilityLabel(NSLocalizedString("button_Add_Maintenance", comment: "Add Maintenance button"))
            .accessibilityHint("Double tap to save this maintenance record")
        }
        .padding(.bottom, 60)
		.toolbar {
			ToolbarItem(placement: .principal) {
				Text(NSLocalizedString("navigation_title_add_maintenance_key", comment: ""))
					.font(.system(size: 22, weight: .bold, design: .default))
					.foregroundColor(Color("TextColor"))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel(NSLocalizedString("navigation_title_add_maintenance_key", comment: "Add Maintenance screen"))
            }
		}
		.sheet(isPresented: $showingDatePicker) {
			DatePicker(
				"Sélectionnez la date",
				selection: Binding(
					get: { VM.selectedMaintenanceDate ?? Date() },   // valeur par défaut si nil
					set: { VM.selectedMaintenanceDate = $0 }
				),
                in: ...Date(),
				displayedComponents: [.date]
			)
			.datePickerStyle(.wheel)
			.labelsHidden()
			.padding()
            .accessibilityLabel("Done")
            .accessibilityHint("Double tap to confirm the selected date")
            
			Button(NSLocalizedString("done_key", comment: "")) {
				showingDatePicker = false   // ferme la sheet
			}
			.padding()
		}
		/*.sheet(isPresented: $showPaywall) {
			PaywallView()
                .accessibilityLabel("Paywall")
                .accessibilityHint("Upgrade to premium to add more maintenance records")
		}*/
		.padding(.horizontal, 10)
		.padding(.top, 20)
		.navigationBarBackButtonHidden(true)
		.toolbar {
			ToolbarItem(placement: .navigationBarLeading) {
				Button(action: {
					dismiss()
				}) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color("TextColor"))
                        .accessibilityLabel("Return")
                        .accessibilityHint("Double tap to go back")
				}
                .accessibilityLabel("Return")
                .accessibilityHint("Double tap to go back")
			}
		}
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color("BackgroundColor"), Color("BackgroundColor2")]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
		.alert(
			isPresented: Binding(
				get: { maintenanceVM.showAlert || bikeVM.showAlert },
				set: { newValue in
					if !newValue {
						maintenanceVM.showAlert = false
						bikeVM.showAlert = false
					}
				}
			)
		) {
			if maintenanceVM.showAlert {
				return Alert(
					title: Text(NSLocalizedString("alert_error_title", comment: "Title of the error alert")),
					message: Text(maintenanceVM.error?.errorDescription ?? NSLocalizedString("alert_unknown_error", comment: "Unknown error")),
					dismissButton: .default(Text("OK")) {
						maintenanceVM.showAlert = false
						maintenanceVM.error = nil
					}
				)
			} else {
				return Alert(
					title: Text(NSLocalizedString("error_title", comment: "Title for error alert")),
					message: Text(bikeVM.error?.localizedDescription ?? NSLocalizedString("unknown_error", comment: "Fallback unknown error")),
					dismissButton: .default(Text("OK")) {
						bikeVM.showAlert = false
						bikeVM.error = nil
					}
				)
			}
		}
	}
}

