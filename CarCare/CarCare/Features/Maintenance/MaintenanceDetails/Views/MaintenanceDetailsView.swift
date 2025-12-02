//
//  MaintenanceDetailsView.swift
//  CarCare
//
//  Created by Ordinateur elena on 19/08/2025.
//

import SwiftUI

struct MaintenanceDetailsView: View {
	@AppStorage("isDarkMode") private var isDarkMode: Bool = false
	@Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
	@ObservedObject var bikeVM: BikeVM // utile pour l'injecter dans AddMaintenanceView
	@ObservedObject var maintenanceVM: MaintenanceVM
	@ObservedObject var notificationVM: NotificationViewModel
	@StateObject private var VM: MaintenanceDetailsVM
	let maintenanceID: UUID // on reçoit juste l'ID
	@State private var showAddMaintenance = false
	@State private var maintenancesForOneType: [Maintenance] = []
	@State private var daysRemaining: Int?
	@State private var hasTriggeredHaptic = false
	var onAdd: () -> Void
    let haptic = UIImpactFeedbackGenerator(style: .medium)
    @State private var frequencyText: String = ""
    @FocusState private var isFocused: Bool
	
	//MARK: -Initialization
	init(bikeVM: BikeVM, maintenanceVM: MaintenanceVM, maintenanceID: UUID, onAdd: @escaping () -> Void, notificationVM: NotificationViewModel) {
		self.bikeVM = bikeVM
		self.maintenanceVM = maintenanceVM
		self.notificationVM = notificationVM
		_VM = StateObject(wrappedValue: MaintenanceDetailsVM(maintenanceVM: maintenanceVM))
		self.maintenanceID = maintenanceID
		self.onAdd = onAdd
	}
	
	//MARK: -Body
	var body: some View {
		if let maintenance = maintenanceVM.maintenances.first(where: { $0.id == maintenanceID }) {
			ScrollView {
				VStack(spacing: 20) {
                    VStack {
                        ZStack {
                            if let daysRemaining = daysRemaining {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                color(for: daysRemaining, frequency: maintenance.effectiveFrequencyInDays).opacity(0.9),
                                                color(for: daysRemaining, frequency: maintenance.effectiveFrequencyInDays).opacity(0.25)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .background(
                                        .ultraThinMaterial,
                                        in: RoundedRectangle(cornerRadius: 15)
                                    )
                                    .accessibilityHidden(true)
                            }
                            VStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.white)
                                        .background(
                                            .ultraThinMaterial,
                                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        )
                                    
                                    Image(maintenance.maintenanceType.iconName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 32, height: 32)
                                        .scaleEffect(iconScale(for: maintenance.maintenanceType))
                                        .accessibilityHidden(true)
                                }
                                .frame(width: 60, height: 60)
                                
                                if let daysRemaining = daysRemaining {
                                    Text(
                                        NSLocalizedString(message(for: daysRemaining, frequency: maintenance.effectiveFrequencyInDays), comment: "")
                                    )
                                    .padding(.horizontal, 10)
                                    .padding(.top, 5)
                                    .font(.system(size: 16, weight: .bold, design: .default))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white)
                                    .accessibilityLabel("Maintenance status")
                                    .accessibilityValue(message(for: daysRemaining, frequency: maintenance.maintenanceType.frequencyInDays))
                                    .onAppear {
                                        triggerHaptic(maintenance: maintenance, for: daysRemaining)
                                    }
                                }
                            }
                            .padding(.vertical, 15)
                        }

                        HStack(spacing: 20) {
                            VStack {
                                VStack(spacing: 15) {
                                    if let daysSince = maintenanceVM.calculateDaysSinceLastMaintenance(
                                        for: maintenance.maintenanceType
                                    ) {
                                        let frequency = Double(maintenance.effectiveFrequencyInDays)
                                        let progress = min(Double(daysSince) / frequency, 1.0)
                                        
                                        CircularProgressView(targetProgress: progress, value: daysSince)
                                            .id(daysRemaining)
                                            .accessibilityElement(children: .combine)
                                            .accessibilityLabel("Progress since last maintenance")
                                            .accessibilityValue("\(daysSince) out of \(Int(frequency)) days")
                                        
                                        Text("\(daysSince)/ \(Int(frequency))j")
                                            .font(.system(size: 16, weight: .bold, design: .default))
                                            .foregroundStyle(Color("TextColor"))
                                        
                                    } else {
                                        CircularProgressView(
                                            targetProgress: 0.0,
                                            value: 0
                                        )
                                        .accessibilityHidden(true)
                                    }
                                }
                                .padding(.top, 5)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(15)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color("AdviceColor").opacity(0.9),
                                                Color("AdviceColor").opacity(0.15)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .background(
                                        .ultraThinMaterial,
                                        in: RoundedRectangle(cornerRadius: 15)
                                    )
                            )
                            .cornerRadius(15)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(NSLocalizedString("frequency_key", comment: ""))
                                    .bold()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.system(size: 14, weight: .bold, design: .default))
                                
                                    Text(NSLocalizedString("every", comment: ""))
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                            .frame(maxWidth: .infinity, alignment: .center)

                                HStack {
                                    TextField("", text: $frequencyText)
                                        .frame(width: 40, alignment: .center)
                                        .multilineTextAlignment(.center)
                                        .focused($isFocused)
                                        .keyboardType(.numberPad)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(7)
                                        .onChange(of: isFocused) { _, newValue in
                                            if !newValue { // Quand on perd le focus
                                                saveFrequency()
                                            }
                                        }
                                    
                                    Text(NSLocalizedString("days", comment: ""))
                                }
                                .font(.system(size: 16, weight: .regular, design: .default))
                                .frame(maxWidth: .infinity, alignment: .center)
                                
                                Toggle("", isOn: Binding(
                                    get: { maintenance.reminder }, //appelé lors du dessin de la vue (aussi après modif du toggle pour redessiner la vue)
                                    set: { newValue in //modification du toggle
                                        maintenanceVM.updateReminder(for: maintenance, value: newValue)
                                        notificationVM.updateReminder(for: maintenance.id, value: newValue)
                                    }
                                ))
                                .frame(maxWidth: .infinity)
                                .padding(.top, 5)
                                .tint(Color("DoneColor"))
                                .labelsHidden()
                                .accessibilityLabel("Reminder")
                                .accessibilityHint("Enable or disable notification for this maintenance")
                                .onChange(of: notificationVM.isAuthorized) { oldValue, newValue in
                                    if newValue {
                                        Task {
                                            await notificationVM.requestAndScheduleNotifications()
                                        }
                                    }
                                }
                                    Text("Fréquence conseillée : tous les \(maintenance.maintenanceType.frequencyInDays) jours")
                                        .font(.system(size: 10, weight: .regular, design: .default))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            .foregroundColor(Color("TextColor"))
                            .padding(15)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color("AdviceColor").opacity(0.9),
                                                Color("AdviceColor").opacity(0.15)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .background(
                                        .ultraThinMaterial,
                                        in: RoundedRectangle(cornerRadius: 15)
                                    )
                            )
                            .cornerRadius(15)
                        }
                        .padding(.top, 15)
                    }
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    VStack(spacing: 15) {
                        NavigationLink(
                            destination: AdviceView(maintenance: maintenance)
                        ) {
                            HStack {
                                VStack {
                                    Text(NSLocalizedString("advice_and_information_key", comment: ""))
                                        .font(.system(size: 25, weight: .bold, design: .default))
                                        .foregroundColor(Color("TextColor"))
                                        .offset(x: 15)
                                    
                                    Divider()
                                        .frame(width: 200)
                                        .offset(x: 15)
                                        .padding(.bottom, 10)
                                    
                                    Text("\(maintenance.maintenanceType.localizedDescription)")
                                        .font(.system(size: 16, weight: .regular, design: .default))
                                        .foregroundColor(Color("TextColor"))
                                        .padding(.leading, 15)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                        .lineLimit(3)
                                }
                                Image(systemName: "chevron.right")
                                    .padding(.top, 65)
                            }
                        }
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                haptic.impactOccurred()
                            }
                        )
                        .accessibilityLabel("Advice and information")
                        .accessibilityHint("Shows detailed advice for this maintenance type")
                    }
                    .padding(.vertical, 20)
                    .padding(.bottom, 10)
                    .padding(.trailing, 10)
                    .background(Color("AdviceColor"))
                    .cornerRadius(15)
                    
                    VStack {
                        Text(NSLocalizedString("maintenance_history_key", comment: ""))
                            .font(.system(size: 25, weight: .bold, design: .default))
                            .foregroundColor(Color("TextColor"))
                            .drawingGroup()
                        
                        Divider()
                            .frame(width: 200)
                        
                        VStack(alignment: .center, spacing: 0) {
                            ForEach(Array(maintenancesForOneType.enumerated()), id: \.element.id) { index, item in
                                MaintenanceDetailsBackgroundView(
                                    formattedDate: formattedDate(item.date),
                                    isLast: index == maintenancesForOneType.count - 1
                                )
                                .accessibilityLabel("Maintenance on \(formattedDate(item.date))")
                                .accessibilityHint(index == maintenancesForOneType.count - 1 ? "Most recent maintenance" : "")
                            }
                           
                            
                            NavigationLink(
                                destination: AddMaintenanceView(bikeVM: bikeVM, maintenanceVM: maintenanceVM,  onAdd: onAdd, notificationVM: notificationVM)
                            ) {
                                Text(NSLocalizedString("button_update_key", comment: ""))
                                    .font(.system(size: 16, weight: .bold, design: .default))
                                    .foregroundColor(Color(.white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color("AppPrimaryColor"))
                                    .cornerRadius(10)
                            }
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    haptic.impactOccurred()
                                }
                            )
                            .padding(.horizontal, 15)
                            .padding(.top, 15)
                            .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 2)
                            .accessibilityLabel("Update maintenance")
                            .accessibilityHint("Add or update a maintenance entry")
                        }
                        .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                    .padding(.bottom, 10)
                    .background(Color("MaintenanceHistoryColor"))
                    .cornerRadius(15)
				}
				.padding(.top, 15)
                .padding(.horizontal, 15)
				.background(Color("BackgroundColor"))
				.cornerRadius(15)
                .frame(maxWidth: .infinity)
				.onAppear {
					_ = VM.fetchAllMaintenanceForOneType(type: maintenance.maintenanceType)
				}
				Spacer()
			}
            .padding(.bottom, 60)
            .onAppear {
                guard let maintenance = maintenanceVM.maintenances.first(where: { $0.id == maintenanceID }) else {
                    return
                }
                
                frequencyText = "\(maintenance.effectiveFrequencyInDays)"
                
                haptic.impactOccurred()
                refreshData()
            }
			.onChange(of: maintenanceVM.maintenances) {_, _ in
                refreshData()
			}
			.background(Color("BackgroundColor"))
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
                    .accessibilityLabel("Back")
				}
				ToolbarItem(placement: .principal) {
					Text("\(maintenance.maintenanceType.localizedName)")
						.font(.system(size: 22, weight: .bold, design: .default))
						.foregroundColor(Color("TextColor"))
                        .accessibilityAddTraits(.isHeader)
				}
			}
			.alert(
				isPresented: Binding(
					get: { maintenanceVM.showAlert || VM.showAlert },
					set: { newValue in
						if !newValue {
							maintenanceVM.showAlert = false
							VM.showAlert = false
						}
					}
				)
			) {
				if maintenanceVM.showAlert {
					return Alert(
						title: Text(NSLocalizedString("error_title", comment: "Title for error alert")),
						message: Text(maintenanceVM.error?.localizedDescription ?? NSLocalizedString("unknown_error", comment: "Fallback unknown error")),
						dismissButton: .default(Text("OK")) {
							maintenanceVM.showAlert = false
							maintenanceVM.error = nil
						}
					)
				} else {
					return Alert(
						title: Text(NSLocalizedString("error_title", comment: "Title for error alert")),
						message: Text(VM.error?.localizedDescription ?? NSLocalizedString("unknown_error", comment: "Fallback unknown error")),
						dismissButton: .default(Text("OK")) {
							VM.showAlert = false
							VM.error = nil
						}
					)
				}
			}
            .alert(
                NSLocalizedString("notifications_disabled_title", comment: ""),
                isPresented: $notificationVM.showSettingsAlert
            ) {
                Button(NSLocalizedString("cancel_button", comment: ""), role: .cancel) {
                    notificationVM.showSettingsAlert = false
                }
                
                Button(NSLocalizedString("open_settings_button", comment: "")) {
                    notificationVM.openSettings()
                    notificationVM.showSettingsAlert = false
                }
            } message: {
                Text(NSLocalizedString("notifications_disabled_message", comment: ""))
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    Task {
                        await notificationVM.checkAuthorizationStatus()
                    }
                }
            }
		} else {
			Text("Maintenance not found")
                .accessibilityLabel("Maintenance not found")
		}
	}
}

extension MaintenanceDetailsView {
	func message(for days: Int, frequency: Int) -> String {
		let proportion = min(max(Double(days) / Double(frequency), 0), 1)
        
        switch proportion {
        case 0..<1/3:
            return NSLocalizedString("maintenance_due", comment: "")
        case 1/3..<2/3:
            return NSLocalizedString("maintenance_not_yet", comment: "")
        default:
            return NSLocalizedString("maintenance_up_to_date", comment: "")
        }
    }
    
    func color(for days: Int, frequency: Int) -> Color {
        let proportion = min(max(Double(days) / Double(frequency), 0), 1)
		switch proportion {
		case 0..<1/3:
			return Color("ToDoColor")
		case 1/3..<2/3:
			return Color("InProgressColor")
		default:
			return Color("DoneColor")
		}
	}
	
	func formattedDate(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .none
		formatter.locale = Locale.current  
		return formatter.string(from: date)
	}
	
	private func triggerHaptic(maintenance: Maintenance, for days: Int) { //vibrations en fonction de l'état de la maintenance
		let proportion = Double(maintenance.maintenanceType.frequencyInDays - days) / Double(maintenance.maintenanceType.frequencyInDays)
		
		if proportion < 1/3 {
			UISelectionFeedbackGenerator().selectionChanged()
		} else if proportion < 2/3 {
			UIImpactFeedbackGenerator(style: .light).impactOccurred()
		} else {
			UINotificationFeedbackGenerator().notificationOccurred(.warning)
		}
	}
    
    private func saveFrequency() {
        if let maintenance = maintenanceVM.maintenances.first(where: { $0.id == maintenanceID }) {
            
            // Valider l'entrée
            guard let newFrequency = Int(frequencyText),
                  newFrequency > 0,
                  newFrequency <= 365 else {
                // Restaurer la valeur précédente si invalide
                frequencyText = "\(maintenance.effectiveFrequencyInDays)"
                return
            }
            
            // Déterminer si c'est une valeur personnalisée
            let defaultFrequency = maintenance.maintenanceType.frequencyInDays
            let customFrequency: Int? = (newFrequency != defaultFrequency) ? newFrequency : nil
            
            // Ne rien faire si la valeur n'a pas changé
            guard customFrequency != maintenance.customFrequencyInDays else {
                return
            }
            
            // Mettre à jour
            var updatedMaintenance = maintenance
            updatedMaintenance.customFrequencyInDays = customFrequency
            
            maintenanceVM.updateFrequency(maintenance: updatedMaintenance, bikeType: bikeVM.bikeType)
        }
    }
    
    private func refreshData() {
        guard let maintenance = maintenanceVM.maintenances.first(where: { $0.id == maintenanceID }) else {
                return
            }
        let effectiveFrequency = maintenance.effectiveFrequencyInDays
            
            maintenancesForOneType = VM.fetchAllMaintenanceForOneType(type: maintenance.maintenanceType)
            
            let newDaysRemaining = VM.calculateDaysUntilNextMaintenance(type: maintenance.maintenanceType, effectiveFrequency: effectiveFrequency) ?? 0
            daysRemaining = newDaysRemaining
    }
}

extension MaintenanceDetailsView {
	func iconScale(for type: MaintenanceType) -> CGFloat {
		switch type {
		case .CleanDrivetrain:
			return 0.85
		case .RunSoftwareAndBatteryDiagnostics:
			return 0.8
		default:
			return 1.0
		}
	}
}

