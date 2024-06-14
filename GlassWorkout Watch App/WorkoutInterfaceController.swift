//
//  WorkoutInterfaceController.swift
//  GlassWorkout Watch App
//
//  Created by Patrick de Nonneville on 13/06/2024.
//

import SwiftUI
import HealthKit

class WorkoutManager: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    
    static let shared = WorkoutManager()
    
    private var healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    @Published var heartRate: Double = 0.0
    @Published var activeEnergyBurned: Double = 0.0
    @Published var distance: Double = 0.0
    @Published var isWorkoutSessionActive: Bool = false // Published property to track workout session state
    @Published var speed: Double = 0.0
    @Published var power: Double = 0.0
    

    override private init() {
        super.init()
    }
    
    func requestAuthorization() {
        let readTypes: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .runningPower)!,
            HKQuantityType.quantityType(forIdentifier: .runningSpeed)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        ]

        let writeTypes: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { (success, error) in
            if !success {
                // Handle the error here.
                print("Authorization failed: \(String(describing: error?.localizedDescription))")
            }
        }
    }

    func startWorkout() {
        guard let workoutConfiguration = createWorkoutConfiguration() else { return }

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()

            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: workoutConfiguration)

            workoutSession?.delegate = self
            workoutBuilder?.delegate = self

            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { (success, error) in
                if !success {
                    // Handle the error here.
                    print("Error beginning workout collection: \(String(describing: error?.localizedDescription))")
                }
            }
        } catch {
            // Handle the error here.
            print("Error starting workout: \(error.localizedDescription)")
        }
    }

    func stopWorkout() {
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { (success, error) in
            if success {
                self.workoutBuilder?.finishWorkout { (workout, error) in
                    // Handle the finished workout.
                    if let error = error {
                        print("Error finishing workout: \(error.localizedDescription)")
                    } else {
                        print("Workout finished successfully.")
                    }
                }
            } else {
                print("Error ending collection: \(String(describing: error?.localizedDescription))")
            }
        }
    }

    private func createWorkoutConfiguration() -> HKWorkoutConfiguration? {
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .running
        workoutConfiguration.locationType = .outdoor

        return workoutConfiguration
    }

    // MARK: - HKWorkoutSessionDelegate

    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // Handle state changes (e.g., started, paused, ended).
        print("Workout session state changed to: \(toState.rawValue)")
        DispatchQueue.main.async {
            self.isWorkoutSessionActive = (toState == .running) // Update the published property
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        // Handle errors.
        print("Workout session failed with error: \(error.localizedDescription)")
    }

    // MARK: - HKLiveWorkoutBuilderDelegate

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            let statistics = workoutBuilder.statistics(for: quantityType)

            // Update your UI with the new data.
            DispatchQueue.main.async {
                if quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate),
                   let heartRate = statistics?.mostRecentQuantity() {
                    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    self.heartRate = heartRate.doubleValue(for: heartRateUnit)
                    print(self.heartRate)
                }

                if quantityType == HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
                   let activeEnergy = statistics?.mostRecentQuantity() {
                    let activeEnergyUnit = HKUnit.kilocalorie()
                    self.activeEnergyBurned = activeEnergy.doubleValue(for: activeEnergyUnit)
                }

                if quantityType == HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
                   let distance = statistics?.mostRecentQuantity() {
                    let distanceUnit = HKUnit.meter()
                    self.distance = distance.doubleValue(for: distanceUnit)
                }
                
                if quantityType == HKQuantityType.quantityType(forIdentifier: .runningPower),
                   let power = statistics?.mostRecentQuantity() {
                    let powerUnit = HKUnit.watt()
                    self.power = power.doubleValue(for: powerUnit)
                }
                
                if quantityType == HKQuantityType.quantityType(forIdentifier: .runningSpeed),
                   let speed = statistics?.mostRecentQuantity() {
                    let speedUnit = HKUnit.meter()
                    self.speed = speed.doubleValue(for: speedUnit) * 1000 / 60
                }
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events if needed.
    }
}
