//
//  HKWorkoutView.swift
//  ItsukiWorkoutApp
//
//  Created by Itsuki on 2025/03/04.
//

import SwiftUI
import HealthKit

struct HKWorkoutView: View {
    var workout: HKWorkout
    
    @State private var showBreakdown: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(workout.workoutActivityType.string) Summary")
                .font(.title3)
                .fontWeight(.bold)

            Text("**Duration:** \(workout.duration.hourMinuteSecond)" )

            
            let distanceStatistics = switch workout.workoutActivityType {
            case .cycling:
                workout.statistics(for: HKQuantityType(.distanceCycling))
            case .swimming:
                workout.statistics(for: HKQuantityType(.distanceSwimming))
            default:
                workout.statistics(for: HKQuantityType(.distanceWalkingRunning))
            }
            if let distanceStatistics {
                Text("**Total Distance:** \(distanceStatistics.totalDistance.formatted(.number.precision(.fractionLength(0)))) \(HKStatistics.distanceUnit.unitString)" )
            }
            
            if let energyStatistics = workout.statistics(for: HKQuantityType(.activeEnergyBurned)) {
                Text("**Energy Burnt:** \(energyStatistics.activeEnergyBurned.formatted(.number.precision(.fractionLength(0)))) \(HKStatistics.energyUnit.unitString)" )
            }
            
            if let heartRateStatistics = workout.statistics(for: HKQuantityType(.heartRate)) {
                Text("**Avg. Heart Rate:** \(heartRateStatistics.averageHeartRate.formatted(.number.precision(.fractionLength(0)))) bpm" )
            }
            
            if let stepCountStatistics = workout.statistics(for: HKQuantityType(.stepCount)) {
                Text("**Steps:** \(stepCountStatistics.stepCount.formatted(.number.precision(.fractionLength(0))))" )

            }
            
            if let strokeCountStatistics = workout.statistics(for: HKQuantityType(.swimmingStrokeCount)) {
                Text("**Strokes:** \(strokeCountStatistics.strokeCount.formatted(.number.precision(.fractionLength(0))))" )
            }
            
            if workout.workoutActivities.count > 1 {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Button(action: {
                        showBreakdown.toggle()
                    }, label: {
                        HStack {
                            Text("**Breakdown**")
                            Spacer()
                            Image(systemName: showBreakdown ? "chevron.down" : "chevron.left")

                        }
                        .frame(maxWidth: .infinity)
                    })
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    
                    if showBreakdown {
                        ForEach(0..<workout.workoutActivities.count, id: \.self) { index in
                            let activity: HKWorkoutActivity = workout.workoutActivities[index]
                            
                            VStack(alignment: .leading) {
                                Text("**\(activity.workoutConfiguration.activityType.string)**")
                                    .foregroundStyle(.primary.opacity(0.8))
                                
                                Text("\(activity.startDate.string(dateStyle: .none, timeStyle: .medium))-\(activity.endDate?.string(dateStyle: .none, timeStyle: .medium) ?? "(none)")")
                                    .font(.system(size: 12))
                                
                                let distanceStatistics = switch activity.workoutConfiguration.activityType {
                                case .cycling:
                                    activity.statistics(for: HKQuantityType(.distanceCycling))
                                case .swimming:
                                    activity.statistics(for: HKQuantityType(.distanceSwimming))
                                default:
                                    activity.statistics(for: HKQuantityType(.distanceWalkingRunning))
                                }
                                if let distanceStatistics {
                                    Text("**Total Distance:** \(distanceStatistics.totalDistance.formatted(.number.precision(.fractionLength(0)))) \(HKStatistics.distanceUnit.unitString)" )
                                }
                                
                                if let energyStatistics = activity.statistics(for: HKQuantityType(.activeEnergyBurned)) {
                                    Text("**Energy Burnt:** \(energyStatistics.activeEnergyBurned.formatted(.number.precision(.fractionLength(0)))) \(HKStatistics.energyUnit.unitString)" )
                                }
                                
                                if let heartRateStatistics = activity.statistics(for: HKQuantityType(.heartRate)) {
                                    Text("**Avg. Heart Rate:** \(heartRateStatistics.averageHeartRate.formatted(.number.precision(.fractionLength(0)))) bpm" )
                                }
                                
                                if let stepCountStatistics = activity.statistics(for: HKQuantityType(.stepCount)) {
                                    Text("**Steps:** \(stepCountStatistics.stepCount.formatted(.number.precision(.fractionLength(0))))" )

                                }
                                
                                if let strokeCountStatistics = activity.statistics(for: HKQuantityType(.swimmingStrokeCount)) {
                                    Text("**Strokes:** \(strokeCountStatistics.strokeCount.formatted(.number.precision(.fractionLength(0))))" )
                                }

                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }

                    }
                }

            }
            
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }
}

extension Date {
    static let formatter = DateFormatter()
    func string(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        Date.formatter.dateStyle = dateStyle
        Date.formatter.timeStyle = timeStyle
        return Date.formatter.string(from: self)
    }
}
