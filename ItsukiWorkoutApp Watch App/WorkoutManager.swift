//
//  WorkoutManager.swift
//  ItsukiWorkoutApp
//
//  Created by Itsuki on 2025/03/02.
//


import SwiftUI
import HealthKit


@MainActor
@Observable
class WorkoutManager: NSObject {
 
    let supportedWorkoutTypes: Set<HKWorkoutActivityType> = [
        .walking,
        .running,
        .cycling,
        .swimming,
        .swimBikeRun,
        .highIntensityIntervalTraining,
    ]
    
    private let typesToShare: Set<HKSampleType> = [HKQuantityType.workoutType()]

    private let typesToRead: Set<HKObjectType> = [
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
        
        HKQuantityType(.stepCount),
        HKQuantityType(.swimmingStrokeCount),
        HKQuantityType(.walkingSpeed),
        HKQuantityType(.cyclingSpeed),
        HKQuantityType(.runningSpeed),

        HKQuantityType(.distanceWalkingRunning),
        HKQuantityType(.distanceCycling),
        HKQuantityType(.distanceSwimming),

        HKObjectType.activitySummaryType()
    ]

    
    var error: WorkoutError? {
        didSet {
            if let error {
                print("error: \(error.message)")
            }
        }
    }
    
    // after session end
    var showResult: Bool = false {
        didSet {
            if !showResult {
                reset()
                return
            }
        }
    }
    var workoutResult: HKWorkout? {
        didSet {
            if workoutResult != nil {
                self.showResult = true
            }
        }
    }
    
    // during the session
    var sessionRunning: Bool = false
    var workoutMetrics: WorkoutMetrics?
    func getElapseTime(at date: Date) -> TimeInterval {
        return self.builder?.elapsedTime(at: date) ?? 0
    }
    
    private var healthStore: HKHealthStore?
    
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    // for iOS: use HKWorkoutBuilder instead.
//    var builder: HKWorkoutBuilder?

    
    override init() {
        super.init()
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
            Task {
                await self.requestAuthorization()
            }
        } else {
            self.error = .unavailable
        }
    }

}


// MARK: - Permission related

extension WorkoutManager {
    private func checkAvailability() async -> Bool {
        if !HKHealthStore.isHealthDataAvailable() {
            self.error = .unavailable
            return false
        }
        
        do {
            let status = try await healthStore?.statusForAuthorizationRequest(toShare: typesToShare, read: typesToRead)
            if status == .unnecessary {
                return true
            } else {
                return await self.requestAuthorization()
            }
            
        } catch(let error) {
            self.error = .requestPermissionError(error)
            return false
        }
    }
    
    private func requestAuthorization() async -> Bool  {
        do {
            try await healthStore?.requestAuthorization(toShare: typesToShare, read: typesToRead)
            return true
        } catch (let error) {
            self.error = .requestPermissionError(error)
            return false
        }
    }
    
}


// MARK: - Manage workout session/builder
extension WorkoutManager {
    
    func startWorkout(with configuration: HKWorkoutConfiguration) async {
        let result = await self.checkAvailability()
        if !result {
            return
        }
        guard let healthStore else {
            self.error = .unavailable
            return
        }

        if !self.supportedWorkoutTypes.contains(configuration.activityType) {
            self.error = .workoutTypeNotSupported
            return
        }
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch(let error) {
            self.error = .startWorkoutFailed(error)
            return
        }

        
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

        //        print("types to collect: ", builder?.dataSource?.typesToCollect as Any)
        
        // to enable additional types to collect, ex: respiratoryRate
        // builder?.dataSource?.enableCollection(for: HKQuantityType(.respiratoryRate), predicate: nil)

        // To monitor session and builder updates
        session?.delegate = self
        builder?.delegate = self
        
        // start activity
        let date = Date()

        session?.startActivity(with: date)

        do {
            try await builder?.beginCollection(at: date)
            self.workoutMetrics = .init(workoutConfiguration: configuration)

        } catch(let error) {
            self.error = .startWorkoutFailed(error)
            reset()
        }
    }
    
    func beginNewSubActivity(with configuration: HKWorkoutConfiguration) async {
        guard let session else {
            self.error = .sessionNotExists
            return
        }
        
        let originalActivity = workoutMetrics?.workoutConfiguration.activityType
        let activityType = configuration.activityType
        
        if originalActivity != .swimBikeRun && activityType != originalActivity {
            self.error = .workoutTypeNotSupported
            return
        }
        
        if originalActivity == .swimBikeRun && activityType != .swimming && activityType != .cycling && activityType != .running && activityType != .transition {
            self.error = .workoutTypeNotSupported
            return

        }
        
        session.beginNewActivity(configuration: configuration, date: Date(), metadata: nil)
        self.workoutMetrics?.subActivityConfiguration = configuration
    }
    
    func endSubActivity() async {
        guard let session else {
            self.error = .sessionNotExists
            return
        }
        
        session.endCurrentActivity(on: Date())
        self.workoutMetrics?.subActivityConfiguration = nil
    }
    
    func resumeSession() {
        session?.resume()
    }
    
    func pauseSession() {
        session?.pause()
    }
    
    func endSession() {
        session?.end()
    }
    
    private func reset() {
        self.session = nil
        self.builder = nil
        self.workoutResult = nil
        self.workoutMetrics = nil
    }
    
}

// MARK: - Read (query) data from Health store

extension WorkoutManager {
    
    func getDailyWorkouts(date: Date = Date()) async -> [HKWorkout] {
        let result = await self.checkAvailability()
        if !result {
            return []
        }
        
        guard let healthStore else {
            self.error = .unavailable
            return []
        }

        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: 1, to: date) else {
            self.error = .queryError(nil)
            return []
        }

        let durationPredicate = HKQuery.predicateForWorkouts(with: .greaterThan, duration: 0)
        let dateRangePredicate = HKQuery.predicateForSamples(
            withStart: calendar.startOfDay(for: date),
            end: calendar.startOfDay(for: endDate),
            options: [.strictStartDate]
        )

        let sampleQueryDescriptor = HKSampleQueryDescriptor(
            predicates: [.workout(NSCompoundPredicate(andPredicateWithSubpredicates: [durationPredicate, dateRangePredicate]))],
            sortDescriptors: [.init(\.startDate, order: .forward)],
            limit: nil
        )
        
        do {
            let results = try await sampleQueryDescriptor.result(for: healthStore)
            print("results.count: \(results.count)")
            return results
        } catch(let error) {
            self.error = .queryError(error)
            return []
        }
    }
    
    func getDailyActivitySummary(date: Date = Date()) async ->  HKActivitySummary? {
        let result = await self.checkAvailability()
        if !result {
            return nil
        }
        
        guard let healthStore else {
            self.error = .unavailable
            return nil
        }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.era, .year, .month, .day], from: date)
        components.calendar = calendar

        let predicate = HKQuery.predicateForActivitySummary(with: components)
        let summaryQueryDescriptor = HKActivitySummaryQueryDescriptor(predicate: predicate)
        
        do {
            let results = try await summaryQueryDescriptor.result(for: healthStore)
            print("results.count: \(results.count)")
            return results.first
        } catch(let error) {
            self.error = .queryError(error)
            return nil
        }
    }
}



// MARK: - other helper functions

extension WorkoutManager {
    nonisolated private func setError(_ error: WorkoutError) {
        DispatchQueue.main.async {
            self.error = error
        }
    }
    
    nonisolated private func updateMetrics(_ statistics: HKStatistics?) {
        guard let statistics else { return }

//        print("update metrics for \(statistics.quantityType.identifier)")
        DispatchQueue.main.async {
            switch statistics.quantityType {
                
            case HKQuantityType(.heartRate):
                self.workoutMetrics?.heartRate = statistics.heartRate
                self.workoutMetrics?.averageHeartRate = statistics.averageHeartRate
                
            case HKQuantityType(.activeEnergyBurned):
                self.workoutMetrics?.energyBurned = statistics.activeEnergyBurned
            case HKQuantityType(.distanceWalkingRunning),
                HKQuantityType(.distanceCycling),
                HKQuantityType(.distanceSwimming):
                self.workoutMetrics?.distance = statistics.totalDistance
                
            case HKQuantityType(.walkingSpeed),
                HKQuantityType(.cyclingSpeed),
                HKQuantityType(.runningSpeed):
                self.workoutMetrics?.speed = statistics.speed
                self.workoutMetrics?.averageSpeed = statistics.averageSpeed

                
            case HKQuantityType(.swimmingStrokeCount):
                self.workoutMetrics?.stepStrokeCount = statistics.strokeCount
           
            case HKQuantityType(.stepCount):
                self.workoutMetrics?.stepStrokeCount = statistics.stepCount

            default:
                return
            }
        }
    }
}


// MARK: - HKWorkoutSessionDelegate

extension WorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("did change to state: \(toState)")
        DispatchQueue.main.async {
            self.sessionRunning = (toState == .running)
        }
        // Wait for the session to transition states before ending the builder.
        if toState == .ended {
            Task {
                do {
                    try await builder?.endCollection(at: date)
                    let workout = try await builder?.finishWorkout()
                    DispatchQueue.main.async {
                        self.workoutResult = workout
                    }
                } catch(let error) {
                    self.setError(.endWorkFailed(error))
                    return
                }
                
            }
        }
    }
    
    
    // called when an error occurs that stops a workout session.
    // When the state of the workout session changes due to an error occurring, this method is always called before workoutSession:didChangeToState:fromState:date:.
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {
        setError(.sessionStoppedWithError(error))
        DispatchQueue.main.async(execute: {
            self.endSession()
            self.reset()
        })
    }
    
    
    // used when divided the session into multiple actives, for example, for a multi-sport event
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didBeginActivityWith workoutConfiguration: HKWorkoutConfiguration, date: Date) {
        print("did begin activity: \(workoutConfiguration)")
        
    }
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didEndActivityWith workoutConfiguration: HKWorkoutConfiguration, date: Date) {
        print("did end activity: \(workoutConfiguration)")
    }
    
}


// MARK: - HKLiveWorkoutBuilderDelegate

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return
            }
            let statistics = workoutBuilder.statistics(for: quantityType)
            updateMetrics(statistics)
        }

    }
    
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        print("did collect event: \(String(describing: workoutBuilder.workoutEvents))")
        if let event = workoutBuilder.workoutEvents.last {
            DispatchQueue.main.async(execute: {
                switch event.type {
                case .pauseOrResumeRequest:
                    print("pauseOrResumeRequest received.")
                    self.sessionRunning ? self.pauseSession() : self.resumeSession()
                    break
                default:
                    break
                }
            })
        }
    }
    
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didBegin workoutActivity: HKWorkoutActivity) {
        print("did begin activity: \(workoutActivity)")
    }
    
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didEnd workoutActivity: HKWorkoutActivity) {
        print("did end activity: \(workoutActivity)")

    }
    
}


// MARK: - Types

extension WorkoutManager {
    enum WorkoutError: Error {
        case unavailable
        case permissionDenied
        case requestPermissionError(Error)
        case workoutTypeNotSupported
        case startWorkoutFailed(Error)
        case endWorkFailed(Error)
        case sessionStoppedWithError(Error)
        case queryError(Error?)
        case sessionNotExists
        
        var message: String {
            switch self {
            case .unavailable:
                return "Workout unavailable."
            case .permissionDenied:
                return "Permission denied."
            case .requestPermissionError(let error):
                return "Request permission: \(error.localizedDescription)"
            case .workoutTypeNotSupported:
                return "Workout type not supported."
            case .startWorkoutFailed(let error):
                return "startWorkoutFailed: \(error.localizedDescription)"
            case .endWorkFailed(let error):
                return "endWorkFailed: \(error.localizedDescription)"
            case .sessionStoppedWithError(let error):
                return "sessionStoppedWithError: \(error.localizedDescription)"
            case .queryError(let error):
                return "queryError: \(error?.localizedDescription ?? "unknown")"
            case .sessionNotExists:
                return "Current workout Session does not exist."
            }
        }
    }
    
    struct WorkoutMetrics: Hashable, Identifiable, Equatable {
        var id: UUID = UUID()
        
        var workoutConfiguration: HKWorkoutConfiguration
        var subActivityConfiguration: HKWorkoutConfiguration?
        
        var averageHeartRate: Double = 0
        var heartRate: Double = 0
        var energyBurned: Double = 0
        
        var distance: Double = 0
        var speed: Double = 0
        var averageSpeed: Double = 0
        
        var stepStrokeCount: Double = 0

        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.workoutConfiguration == rhs.workoutConfiguration
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
