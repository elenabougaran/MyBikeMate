//
//  DashboardViewE.swift
//  CarCare
//
//  Created by Ordinateur elena on 03/11/2025.
//

import SwiftUI

struct DashboardView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    //@AppStorage("isPremiumUser") private var isPremiumUser = false
    @ObservedObject var bikeVM: BikeVM
    @ObservedObject var maintenanceVM: MaintenanceVM
    @ObservedObject var notificationVM: NotificationViewModel
    @StateObject private var VM: DashboardVM
    @State private var sheetPosition: CGFloat = 0.7 // 0.8 = medium, 0.1 = large
    @State private var dragOffset: CGFloat = 0
    @State private var didLoadData = false
    @State private var showPaywall = false
    @State private var showPopover = false
    let haptic = UIImpactFeedbackGenerator(style: .medium)
    
    init(bikeVM: BikeVM, maintenanceVM: MaintenanceVM, notificationVM: NotificationViewModel) {
        self.bikeVM = bikeVM
        self.maintenanceVM = maintenanceVM
        self.notificationVM = notificationVM
        _VM = StateObject(wrappedValue: DashboardVM(maintenanceVM: maintenanceVM, bikeVM: bikeVM))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                if let imageData = bikeVM.bike?.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                } else if bikeVM.bike == nil {
                    EmptyView()
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                } else {
                    Image("Riding")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                }
                if didLoadData {
                    BikeDetailsSheet(bikeVM: bikeVM, maintenanceVM: maintenanceVM, notificationVM: notificationVM, VM: VM)
                        .frame(height: geometry.size.height)
                        .offset(y: UIAccessibility.isVoiceOverRunning ? 0 : (geometry.size.height * sheetPosition) + dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation.height
                                }
                                .onEnded { value in
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        // Calculer la nouvelle position
                                        let newPosition = sheetPosition + (value.translation.height / geometry.size.height)
                                        
                                        // Snap vers medium (0.5) ou large (0.1)
                                        if newPosition < 0.3 {
                                            sheetPosition = 0.2 // Position haute
                                        } else {
                                            sheetPosition = 0.7 // Position basse
                                        }
                                        
                                        dragOffset = 0
                                    }
                                }
                        )
                        .accessibilityLabel("Bike Details")
                }
            }
        }
        .onAppear {
            if UIAccessibility.isVoiceOverRunning {
                sheetPosition = 0.1 // sheet complètement visible
            }
            guard !didLoadData else { return } //evite boucle lors du changement de light dark mode
            didLoadData = true
            bikeVM.fetchBikeData() { //bikeData mises dans publised
                VM.fetchLastMaintenance(for: bikeVM.bikeType)
                maintenanceVM.fetchAllMaintenance(for: bikeVM.bikeType) //utile pour statut général entretien
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    haptic.impactOccurred()
                    VM.exportPDF(maintenances: maintenanceVM.maintenances)
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .imageScale(.large)
                        .foregroundColor(Color.white)
                        .shadow(color: .black.opacity(0.6), radius: 1, x: 0, y: 0)
                        .offset(y: -2)
                }
                /*.popover(isPresented: $showPopover, arrowEdge: .top) {
                    VStack(spacing: 20) {
                        Text(NSLocalizedString("premium_feature", comment: ""))
                            .font(.system(size: 22, weight: .bold, design: .default))
                        
                        Text(NSLocalizedString("share_summary_description", comment: ""))
                            .multilineTextAlignment(.center)
                            .font(.system(size: 18, weight: .regular, design: .default))
                            .frame(maxWidth: 250)
                        
                        Button(action: {
                            haptic.impactOccurred()
                            showPopover = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showPaywall = true
                            }
                        }) {
                            Text(NSLocalizedString("unlock_now", comment: ""))
                                .font(.system(size: 18, weight: .bold, design: .default))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color("MainComponentColor"))
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }*/
            }
        }
        .ignoresSafeArea()
        .padding(.bottom, 40)
        /*.fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }*/
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            isPresented: Binding(
                get: { bikeVM.showAlert || maintenanceVM.showAlert || VM.showAlert },
                set: { newValue in
                    if !newValue {
                        bikeVM.showAlert = false
                        maintenanceVM.showAlert = false
                        VM.showAlert = false
                    }
                }
            )
        ) {
            if bikeVM.showAlert {
                return Alert(
                    title: Text(NSLocalizedString("bike_error", comment: "")),
                    message: Text(bikeVM.error?.localizedDescription ?? NSLocalizedString("unknown_error", comment: "")),
                    dismissButton: .default(Text("OK")) {
                        bikeVM.showAlert = false
                        bikeVM.error = nil
                    }
                )
            } else if maintenanceVM.showAlert {
                return Alert(
                    title: Text(NSLocalizedString("maintenance_error", comment: "")),
                    message: Text(maintenanceVM.error?.localizedDescription ?? NSLocalizedString("unknown_error", comment: "")),
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
    }
}
