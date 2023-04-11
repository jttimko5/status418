//
//  HealthAccess.swift
//  SmartNote
//
//  Created by Tim Stauder on 4/5/23.
//

import Foundation
import HealthKit

private let healthStore = HKHealthStore()
private let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!


class HealthKitViewModel: ObservableObject {
    
    private var healthStore = HKHealthStore()
    private var healthKitManager = HealthKitManager()
    @Published var userStepCount = ""
    @Published var isAuthorized = false
    
    init() {
        changeAuthorizationStatus()
    }
    
    //MARK: - HealthKit Authorization Request Method
    func healthRequest(date: Date) {
        healthKitManager.setUpHealthRequest(healthStore: healthStore) {
            self.changeAuthorizationStatus()
            self.readStepsTakenToday(date: date)
        }
    }
    
    func changeAuthorizationStatus() {
        guard let stepQtyType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        let status = self.healthStore.authorizationStatus(for: stepQtyType)
        
        switch status {
        case .notDetermined:
            isAuthorized = false
        case .sharingDenied:
            isAuthorized = false
        case .sharingAuthorized:
            DispatchQueue.main.async {
                self.isAuthorized = true
            }
        @unknown default:
            isAuthorized = false
        }
    }
    
    //MARK: - Read User's Step Count
    func readStepsTakenToday(date: Date) {
        healthKitManager.readStepCount(date: date, healthStore: healthStore) { step in
            if step != 0.0 {
                DispatchQueue.main.async {
                    self.userStepCount = String(format: "%.0f", step)
                    print(step)
                }
            }
        }
    }
    
}

class HealthKitManager {
    func setUpHealthRequest(healthStore: HKHealthStore, readSteps: @escaping () -> Void) {
        if HKHealthStore.isHealthDataAvailable(), let stepCount = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) {
            healthStore.requestAuthorization(toShare: [stepCount], read: [stepCount]) { success, error in
                if success {
                    readSteps()
                } else if error != nil {
                    print(error ?? "Error")
                }
            }
        }
        
    }
    
    func readStepCount(date: Date, healthStore: HKHealthStore, completion: @escaping (Double) -> Void) {
        guard let stepQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let first = Calendar.current.startOfDay(for: date)
        var one = DateComponents()
        one.day = 1
        let second = Calendar.current.date(byAdding: one, to: first, wrappingComponents: false)
        
        let predicate = HKQuery.predicateForSamples(withStart: first, end: second, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.count()))
        }
        healthStore.execute(query)
    }
}
