//
//  NewWorkoutView.swift
//  ItsukiWorkoutApp
//
//  Created by Itsuki on 2025/03/02.
//

import SwiftUI
//import HealthKitUI
import HealthKit

struct NewWorkoutView: View {
    @Environment(WorkoutManager.self) private var workoutManager
    @State private var selectedWorkoutType: HKWorkoutActivityType? = nil
    @State private var showConfigurationSheet: Bool = false
    
    @State private var swimLocation: HKWorkoutSwimmingLocationType = .pool
    @State private var lapLength: Int = 400
    @State private var activityLocation: HKWorkoutSessionLocationType = .outdoor

    var body: some View {
        @Bindable var workoutManager = workoutManager
        let supportedWorkoutTypes = Array(workoutManager.supportedWorkoutTypes)
        List {
            if let error = workoutManager.error {
                Text(error.message)
                    .foregroundStyle(.red)
            }
            
            ForEach(0..<supportedWorkoutTypes.count, id: \.self) { index in
                let workoutType = supportedWorkoutTypes[index]
                Button(action: {
                    selectedWorkoutType = workoutType
                    showConfigurationSheet = true
                }, label: {
                    Text(workoutType.string)
                })
            }
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showConfigurationSheet, content:  {

            VStack(alignment: .leading, spacing: 8) {
                if let selectedWorkoutType {
                    if selectedWorkoutType == .swimming {
                        List {
                            Picker(selection: $swimLocation, content: {
                                Text("Open water")
                                    .tag(HKWorkoutSwimmingLocationType.openWater)
                                Text("Pool")
                                    .tag(HKWorkoutSwimmingLocationType.pool)

                            }, label: {
                                Text("Swim Location")
                            })

                        }
                        .frame(height: 56)
                        .scrollIndicators(.hidden)
                        .scrollDisabled(true)

                        
                        HStack {
                            Text("Lap Length(m)")
                                .padding(.leading, 4)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            TextField("", value: $lapLength, format: .number)
                        }

        
                    } else {
                        Form {
                            Picker(selection: $activityLocation, content: {
                                Text("Indoor")
                                    .tag(HKWorkoutSessionLocationType.indoor)
                                Text("Outdoor")
                                    .tag(HKWorkoutSessionLocationType.outdoor)
                                
                            }, label: {
                                Text("Activity Location")
                            })
                            
                        }
                    }
                    
                    if let error = workoutManager.error {
                        Text(error.message)
                            .foregroundStyle(.red)
                            .padding(.leading, 4)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            showConfigurationSheet = false
                        }, label: {
                            Text("Cancel")
                                .foregroundStyle(.red)
                                .padding(.all, 4)
                                .contentShape(Rectangle())

                        })
                        
                        Button(action: {
                            Task {
                                let configuration = HKWorkoutConfiguration()
                                configuration.activityType = selectedWorkoutType
                                if selectedWorkoutType == .swimming {
                                    configuration.swimmingLocationType = swimLocation
                                    configuration.lapLength = HKQuantity(unit: HKUnit.meter(), doubleValue: Double(lapLength))
                                } else {
                                    configuration.locationType = activityLocation
                                }
                                await workoutManager.startWorkout(with: configuration)
                                showConfigurationSheet = false
                            }

                        }, label: {
                            Text("Start")
                                .foregroundStyle(.blue)
                                .padding(.all, 4)
                                .contentShape(Rectangle())
                        })
                        
                    }
                    .padding(.trailing, 4)
                    .fontWeight(.semibold)
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                }
            }
            .font(.system(size: 12))
            .frame(maxHeight: .infinity, alignment: .top)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .interactiveDismissDisabled()
        })
        .onChange(of: showConfigurationSheet, {
            if !showConfigurationSheet {
                selectedWorkoutType = nil
            }
        })
        .onAppear {
            workoutManager.error = nil
        }
        .onDisappear {
            workoutManager.error = nil
        }
        .navigationTitle("New Workout")
        .navigationDestination(item: $workoutManager.workoutMetrics, destination: { _ in
                WorkoutProgressView()
                    .environment(workoutManager)
        })
        .sheet(isPresented: $workoutManager.showResult) {
            WorkoutResultView()
                .environment(workoutManager)
                .toolbarVisibility(.hidden, for: .navigationBar)
        }
    }
}

struct WorkoutProgressView: View {
    @Environment(WorkoutManager.self) private var workoutManager
    @State private var currentDate: Date = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var showControl: Bool = false
    @State private var showProgressView: Bool = false
    
    @State private var selectedWorkoutType: HKWorkoutActivityType? = nil
    @State private var showNewSubActivitySheet: Bool = false
    @State private var showConfigurationSheet: Bool = false

    @State private var swimLocation: HKWorkoutSwimmingLocationType = .pool
    @State private var lapLength: Int = 400
    @State private var activityLocation: HKWorkoutSessionLocationType = .outdoor


    var body: some View {

        ZStack {

            if showProgressView {
                ProgressView()
                    .controlSize(.extraLarge)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            
            if let metrics = workoutManager.workoutMetrics {
                VStack(alignment: .leading) {
                    HStack {
                        Text(workoutManager.getElapseTime(at: currentDate).hourMinuteSecond)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        
                        Button(action: {
                            showControl.toggle()
                        }, label: {
                            Image(systemName: "ellipsis")
                                .rotationEffect(.degrees(showControl ? 90 : 0))
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(.gray))
                        })
                        .overlay(alignment: .top, content: {
                            if showControl {
                                let sessionRunning = workoutManager.sessionRunning
                                VStack(spacing: 8) {
                                    Button(action: {
                                        sessionRunning ? workoutManager.pauseSession() : workoutManager.resumeSession()
                                    }, label: {
                                        Image(systemName: sessionRunning ? "pause.fill" : "arrow.clockwise")
                                            .frame(width: 32, height: 32)
                                            .background(Circle().fill(.gray))
                                    })
                                    
                                    Button(action: {
                                        workoutManager.endSession()
                                        self.showProgressView = true
                                    }, label: {
                                        Image(systemName: "stop.fill")
                                            .frame(width: 32, height: 32)
                                            .background(Circle().fill(.gray))
                                    })

                                }
                                .padding(.top, 40)
                            }
                        })
                        .overlay(alignment: .trailing, content: {
                            if showControl {
                                
                                if metrics.subActivityConfiguration != nil && metrics.workoutConfiguration.activityType != .swimBikeRun {
                                    Button(action: {
                                        Task {
                                            await workoutManager.endSubActivity()
                                            showControl = false
                                        }
                                    }, label: {
                                        Text("End Interval")
                                            .font(.system(size: 12))
                                            .frame(width: 108, height: 32)
                                            .background(Capsule().fill(.gray))
                                    })
                                    .padding(.trailing, 40)

                                } else {
                                    Button(action: {
                                        if metrics.workoutConfiguration.activityType == .swimBikeRun {
                                            showNewSubActivitySheet = true
                                            return
                                        }
                                        
                                        Task {
                                            await workoutManager.beginNewSubActivity(with: metrics.workoutConfiguration)
                                            if workoutManager.error == nil {
                                                showControl = false
                                            }
                                        }
                                        return
   
                                    }, label: {
                                        Text(metrics.workoutConfiguration.activityType == .swimBikeRun ? "New SubActivity" : "New Interval")
                                            .font(.system(size: 12))
                                            .frame(width: 108, height: 32)
                                            .background(Capsule().fill(.gray))
                                    })
                                    .padding(.trailing, 40)

                                }
                            }
                        })
                        .buttonStyle(.plain)
                    }
                    
                    if let subActivity = metrics.subActivityConfiguration {
                        Text(subActivity.activityType.string)
                            .font(.system(size: 12))
                            .opacity(0.5)
                            .padding(.bottom, 4)
                    }

                    Text(metrics.distance.formatted(.number.precision(.fractionLength(0))) + " \(HKStatistics.distanceUnit.unitString)")
                    Text(metrics.energyBurned.formatted(.number.precision(.fractionLength(0))) + " \(HKStatistics.energyUnit.unitString)")
                    Text(metrics.heartRate.formatted(.number.precision(.fractionLength(0))) + " bpm")
                    if metrics.workoutConfiguration.activityType == .swimming {
                        Text(metrics.stepStrokeCount.formatted(.number.precision(.fractionLength(0))) + " strokes")
                    }
                    if metrics.workoutConfiguration.activityType == .walking || metrics.workoutConfiguration.activityType == .running || metrics.workoutConfiguration.activityType == .highIntensityIntervalTraining {
                        Text(metrics.stepStrokeCount.formatted(.number.precision(.fractionLength(0))) + " steps")
                    }
                }
                .onReceive(timer) { input in
                    currentDate = input
                }
                .sheet(isPresented: $showNewSubActivitySheet, content:  {
                    List {
                        if let error = workoutManager.error {
                            Text(error.message)
                                .foregroundStyle(.red)
                        }
                        let activityTypes: [HKWorkoutActivityType] = self.getAllowedSubActivities()
                        
                        ForEach(0..<activityTypes.count, id: \.self) { index in
                            let workoutType = activityTypes[index]
                            Button(action: {
                                if workoutType == .transition {
                                    let configuration = HKWorkoutConfiguration()
                                    configuration.activityType = .transition
                                    configuration.locationType = metrics.workoutConfiguration.locationType
                                    Task {
                                        await workoutManager.beginNewSubActivity(with: configuration)
                                        if workoutManager.error == nil {
                                            showNewSubActivitySheet = false
                                            showControl = false
                                        }
                                    }
                                    return
                                }
                        
                                selectedWorkoutType = workoutType
                                showNewSubActivitySheet = false
                                showConfigurationSheet = true
                                
                            }, label: {
                                Text(workoutType.string)
                            })
                        }
                    }
                })
                .sheet(isPresented: $showConfigurationSheet, content:  {

                    VStack(alignment: .leading, spacing: 8) {
                        if let selectedWorkoutType {
                            if selectedWorkoutType == .swimming {
                                List {
                                    Picker(selection: $swimLocation, content: {
                                        Text("Open water")
                                            .tag(HKWorkoutSwimmingLocationType.openWater)
                                        Text("Pool")
                                            .tag(HKWorkoutSwimmingLocationType.pool)

                                    }, label: {
                                        Text("Swim Location")
                                    })

                                }
                                .frame(height: 56)
                                .scrollIndicators(.hidden)
                                .scrollDisabled(true)

                                
                                HStack {
                                    Text("Lap Length(m)")
                                        .padding(.leading, 4)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                    TextField("", value: $lapLength, format: .number)
                                }

                
                            } else {
                                Form {
                                    Picker(selection: $activityLocation, content: {
                                        Text("Indoor")
                                            .tag(HKWorkoutSessionLocationType.indoor)
                                        Text("Outdoor")
                                            .tag(HKWorkoutSessionLocationType.outdoor)
                                        
                                    }, label: {
                                        Text("Activity Location")
                                    })
                                    
                                }
                            }
                            
                            if let error = workoutManager.error {
                                Text(error.message)
                                    .foregroundStyle(.red)
                                    .padding(.leading, 4)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            
                            HStack(spacing: 8) {
                                Button(action: {
                                    showConfigurationSheet = false
                                    showNewSubActivitySheet = true
                                }, label: {
                                    Text("Cancel")
                                        .foregroundStyle(.red)
                                        .padding(.all, 4)
                                        .contentShape(Rectangle())

                                })
                                
                                Button(action: {
                                    Task {
                                        let configuration = HKWorkoutConfiguration()
                                        configuration.activityType = selectedWorkoutType
                                        if selectedWorkoutType == .swimming {
                                            configuration.swimmingLocationType = swimLocation
                                            configuration.lapLength = HKQuantity(unit: HKUnit.meter(), doubleValue: Double(lapLength))
                                        } else {
                                            configuration.locationType = activityLocation
                                        }
                                        await workoutManager.beginNewSubActivity(with: configuration)
                                        showConfigurationSheet = false
                                        if workoutManager.error != nil {
                                            showNewSubActivitySheet = true
                                        } else {
                                            showControl = false
                                        }
                                    }

                                }, label: {
                                    Text("Start")
                                        .foregroundStyle(.blue)
                                        .padding(.all, 4)
                                        .contentShape(Rectangle())
                                })
                                
                            }
                            .padding(.trailing, 4)
                            .fontWeight(.semibold)
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        }
                    }
                    .font(.system(size: 12))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .toolbarVisibility(.hidden, for: .navigationBar)
                    .interactiveDismissDisabled()
                })
                .disabled(showProgressView)
                .navigationTitle("\(metrics.workoutConfiguration.activityType.string)")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onTapGesture {
            self.showControl = false
        }
        .onAppear {
            workoutManager.error = nil
        }
        .onDisappear {
            workoutManager.error = nil
        }

    }
    
    private func getAllowedSubActivities() -> [HKWorkoutActivityType] {
        guard let metrics = workoutManager.workoutMetrics else {
            return []
        }
        
        if metrics.workoutConfiguration.activityType == .swimBikeRun {
            let activityTypes: [HKWorkoutActivityType] = (metrics.subActivityConfiguration == nil || metrics.subActivityConfiguration?.activityType != .transition) ? [.swimming, .cycling, .running, .transition] : [.swimming, .cycling, .running]
            return activityTypes
        }
        
        return metrics.subActivityConfiguration == nil ? [metrics.workoutConfiguration.activityType] : []
    }
}

struct WorkoutResultView: View {
    @Environment(WorkoutManager.self) private var workoutManager

    var body: some View {
        
        if let result = workoutManager.workoutResult {
            ScrollView {

                HKWorkoutView(workout: result)
                
                Spacer()
                    .frame(height: 8)
                
                Button(action: {
                    workoutManager.showResult = false
                }, label: {
                   Text("Done")
                })

            }
        }
    }
}

#Preview {
    let manager = WorkoutManager()
    let configuration = HKWorkoutConfiguration()
    configuration.activityType = .swimBikeRun
    
    return NavigationStack {
        NewWorkoutView()
//        WorkoutProgressView()
            .environment(manager)
            .onAppear {
                manager.workoutMetrics = .init(workoutConfiguration: configuration)
            }

    }
}
