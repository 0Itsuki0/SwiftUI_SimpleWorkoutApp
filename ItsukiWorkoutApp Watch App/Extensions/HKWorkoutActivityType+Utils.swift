//
//  HKWorkoutActivityType+Utils.swift
//  ItsukiWorkoutApp
//
//  Created by Itsuki on 2025/03/03.
//

import HealthKit

extension HKWorkoutActivityType {

    var string: String {
        switch self {
        case .walking:
            return "Walking"
        case .running:
            return "Running"
        case .cycling:
            return "Cycling"
        case .swimming:
            return "Swimming"
        case .swimBikeRun:
            return "Triathlon"
        case .highIntensityIntervalTraining:
            return "Interval Training"
        case .transition:
            return "Transition"
        default:
            return "(not supported)"
        }
    }
}
