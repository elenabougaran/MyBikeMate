//
//  FakeBikeVM.swift
//  CarCareTests
//
//  Created by Ordinateur elena on 02/12/2025.
//

import XCTest
@testable import CarCare

@MainActor
final class FakeBikeVM: BikeVM {
    init() {
        super.init(notificationVM: FakeNotificationVM(maintenanceVM: FakeMaintenanceVM3()))
        self.brand = "TestBrand"
        self.model = "TestModel"
        self.year = 2025
        self.bikeType = .Manual
        self.identificationNumber = "12345"
        self.bike = Bike(id: UUID(), brand: brand, model: model, year: year, bikeType: bikeType, identificationNumber: identificationNumber)
    }

    override func fetchBikeData(completion: (() -> Void)? = nil) {
        // Pas de fetch réel, juste remplir les propriétés pour le test
        completion?()
    }
}
