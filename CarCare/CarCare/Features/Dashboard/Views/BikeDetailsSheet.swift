//
//  BikeDetailSheet.swift
//  CarCare
//
//  Created by Ordinateur elena on 03/11/2025.
//

import SwiftUI

struct BikeDetailsSheet: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    let haptic = UIImpactFeedbackGenerator(style: .medium)
    @ObservedObject var bikeVM: BikeVM
    @ObservedObject var maintenanceVM : MaintenanceVM
    @ObservedObject var notificationVM: NotificationViewModel
    @ObservedObject var VM: DashboardVM
    @State private var goToAdd = false
    let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        df.locale = Locale.current
        return df
    }()
    
    let thousandFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        return f
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle indicator
           /* Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)*/
            DragHandleArea()
                .frame(height: 80)
            
                ScrollView {
                    VStack(spacing: 20) {
                        HStack(spacing: 15) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("\(bikeVM.brand.uppercased())")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.system(size: 14, weight: .bold, design: .default))
                                    .foregroundColor(Color("TextColor"))
                                Text("\(bikeVM.model)")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.system(size: 14, weight: .bold, design: .default))
                                    .foregroundColor(Color("SecondTextColor"))
                                
                                VStack(alignment: .leading) {
                                    Text(thousandFormatter.string(from: NSNumber(value: bikeVM.year)) ?? "")
                                    if !bikeVM.identificationNumber.isEmpty {
                                        Circle()
                                            .fill(Color("SecondTextColor"))
                                            .frame(width: 8, height: 8)
                                        Text("\(bikeVM.identificationNumber)")
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(Color("SecondTextColor"))
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                Spacer()
                            }
                            .padding(.top, 15)
                            .padding(.leading, 20)
                            .frame(width: 170, height: 140)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color("MainComponentColor").opacity(0.3),
                                                Color("MainComponentColor2").opacity(0.3)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(bikeVM.brand) \(bikeVM.model), year \(bikeVM.year)")
                            .accessibilityHint(bikeVM.identificationNumber.isEmpty ? "" : "Identification number \(bikeVM.identificationNumber)")

                            
                            VStack(spacing: 20) {
                                Text(NSLocalizedString("maintenance_key", comment: ""))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.system(size: 14, weight: .bold, design: .default))
                                    .foregroundColor(Color("TextColor"))
                                    .padding(.leading, 15)

                                Text("\(maintenanceVM.overallStatus.label)")
                                    .font(.system(size: 14, weight: .bold, design: .default))
                                    .foregroundColor(maintenanceVM.overallStatus == .aJour ? Color("DoneColor") :
                                                        maintenanceVM.overallStatus == .bientotAPrevoir ? Color("InProgressColor") :
                                                        Color("ToDoColor"))
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(
                                        Capsule()
                                            .strokeBorder(
                                                maintenanceVM.overallStatus == .aJour ? Color("DoneColor") :
                                                    maintenanceVM.overallStatus == .bientotAPrevoir ? Color("InProgressColor") :
                                                    Color("ToDoColor"),
                                                lineWidth: 2
                                            )
                                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                    )
                                Spacer()
                            }
                            .padding(.top, 15)
                            .frame(width: 170, height: 140)
                            .background(
                                LinearGradient(
                                    colors: [Color("MainComponentColor").opacity(0.3), Color("MainComponentColor2").opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            .cornerRadius(15)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Overall maintenance status")
                            .accessibilityValue(maintenanceVM.overallStatus.label)
                            .accessibilityHint("Indicates if maintenance is up to date or upcoming")
                        }
                        
                        ZStack {
                            Image("Maintenance")
                                .resizable()
                                .frame(width: 360, height: 250)
                                .cornerRadius(10)
                                .scaledToFit()
                                .shadow(color: .black.opacity(isDarkMode ? 0.1 : 0.25), radius: 8, x: 0, y: 4)
                                .accessibilityHidden(true)
                            
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0),
                                    Color.black.opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(width: 360, height: 250)
                            .cornerRadius(10)
                            
                            
                            VStack(alignment: .leading) {
                                Text(NSLocalizedString("last_maintenance_key", comment: ""))
                                    .font(.system(size: 22, weight: .bold, design: .default))
                                    .padding(.bottom, 5)
                                
                                Text("\(maintenanceVM.generalLastMaintenance?.maintenanceType.localizedName ?? "")")
                                    .font(.system(size: 16, weight: .bold, design: .default))
                                
                                if let date = maintenanceVM.generalLastMaintenance?.date {
                                    Text(formatter.string(from: date))
                                        .font(.system(size: 16, weight: .bold, design: .default))
                                } else {
                                    Text(NSLocalizedString("no_date_key", comment: ""))
                                        .font(.system(size: 16, weight: .bold, design: .default))
                                }
                            }
                            .foregroundColor(.white)
                            .bold()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .frame(width: 350, height: 250, alignment: .bottomLeading)
                            .accessibilityElement(children: .ignore)
                            .accessibilityAddTraits(.isStaticText)
                            .accessibilityLabel("Last maintenance: \(maintenanceVM.generalLastMaintenance?.maintenanceType.localizedName ?? "No maintenance recorded"), \(maintenanceVM.generalLastMaintenance?.date != nil ? formatter.string(from: maintenanceVM.generalLastMaintenance!.date) : "No date")")
                           
                            
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        
                        VStack(spacing: 20) {
                            NavigationLink(
                                destination: BikeModificationsView(bikeVM: bikeVM, notificationVM: notificationVM) {
                                    //closure de BikeModificationsView
                                    maintenanceVM.deleteAllMaintenances()
                                }
                            ) {
                                Text(NSLocalizedString("button_modify_bike_information", comment: ""))
                                    .font(.system(size: 16, weight: .bold, design: .default))
                                    .foregroundColor(Color("TextColor"))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color("BackgroundColor"))
                                    .cornerRadius(10)
                                    .overlay(
                                        Group {
                                            if isDarkMode {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                                            }
                                        }
                                    )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 10)
                            .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 2)
                            .accessibilityLabel("Modify bike information. Opens the screen to edit your bike's details")
                            
                            Button {
                                haptic.impactOccurred()
                                goToAdd = true
                            } label: {
                                Text(NSLocalizedString("button_Add_Maintenance", comment: ""))
                                    .font(.system(size: 16, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color("AppPrimaryColor"))
                                    .cornerRadius(10)
                            }
                            .padding(.bottom, 20)
                            .padding(.horizontal, 10)
                            .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 2)
                            .allowsHitTesting(true)
                            .contentShape(Rectangle())
                            .accessibilityLabel("Add maintenance. Opens the screen to add a new maintenance entry")
                            .accessibilityAddTraits(.isButton)
                        }
                        .navigationDestination(isPresented: $goToAdd) {
                            AddMaintenanceView(
                                bikeVM: bikeVM,
                                maintenanceVM: maintenanceVM,
                                onAdd: {
                                    VM.fetchLastMaintenance(for: bikeVM.bikeType)
                                    maintenanceVM.fetchAllMaintenance(for: bikeVM.bikeType)
                                },
                                notificationVM: notificationVM
                            )
                        }
                        .padding(.top, 10)
                        
                        Spacer(minLength: 70)
                    }
                }
                .padding(.bottom, UIAccessibility.isVoiceOverRunning ? 0 : 70)
                .padding(.top, UIAccessibility.isVoiceOverRunning ? 90 : 0)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color("BackgroundColor"), Color("BackgroundColor2")]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedCorner(radius: 25, corners: [.topLeft, .topRight]))
        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        .onAppear {
            haptic.prepare()
        }
    }
}


struct DragHandleArea: View {
    var body: some View {
        VStack(spacing: 7) {
            // Indicateur visuel classique
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 50, height: 6)
                .padding(.top, 12)
            
            // Texte d'aide
            Text("Glisser pour agrandir")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        .contentShape(Rectangle())
    }
}
