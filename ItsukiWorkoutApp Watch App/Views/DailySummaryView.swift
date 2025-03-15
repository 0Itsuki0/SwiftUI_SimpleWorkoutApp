//
//  DailySummaryView.swift
//  ItsukiWorkoutApp
//
//  Created by Itsuki on 2025/03/04.
//

import SwiftUI
//import HealthKitUI
import HealthKit

struct DailySummaryView: View {
    @Environment(WorkoutManager.self) private var workoutManager
    @State private var workouts: [HKWorkout] = []
    @State private var summary: HKActivitySummary?
    
    var body: some View {
        VStack {
            if let error = workoutManager.error {
                Text(error.message)
                    .foregroundStyle(.red)
            }
            TabView(content: {
                WorkoutListView(workouts: workouts)
                ActivityRingView(summary: summary)
            })
        }
        .navigationTitle("Daily Summary")
        .task {
            let today = Date()
            self.workouts = await workoutManager.getDailyWorkouts(date: today)
            self.summary = await workoutManager.getDailyActivitySummary(date: today)
        }
    }
    
}

struct ActivityRingView: View {
    var summary: HKActivitySummary?
    
    var body: some View {
        VStack(spacing: 8) {
            if summary == nil {
                Text("No summary available...")
                    .font(.system(size: 12))
                    .opacity(0.8)
            }
            ActivityRingRepresentable(summary: summary)
                .padding(.all, 8)
        }
    }
}

struct ActivityRingRepresentable: WKInterfaceObjectRepresentable {
    var summary: HKActivitySummary?

    func makeWKInterfaceObject(context: Context) -> some WKInterfaceObject {
        let activityRing = WKInterfaceActivityRing()
        activityRing.setActivitySummary(summary, animated: true)
        return activityRing
    }

    func updateWKInterfaceObject(_ wkInterfaceObject: WKInterfaceObjectType, context: Context) {}
}



struct WorkoutListView: View {
    var workouts: [HKWorkout]
    
    @State private var showSheet: Bool = false
    @State private var selectedWorkout: HKWorkout?
    
    var body: some View {
        List {
            if workouts.isEmpty {
                VStack(alignment: .leading) {
                    Text("You haven't worked out for today!")
                    Text("Go for a jog!")
                }
                .font(.system(size: 12))
            }
            
            ForEach(0..<workouts.count, id: \.self) { index in
                let workout = self.workouts[index]
                
                Button(action: {
                    selectedWorkout = workout
                    showSheet = true
                }, label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("**\(workout.workoutActivityType.string)**")
                            .font(.system(size: 12))
                        HStack {
                            Text(workout.startDate, style: .date)
                            Text(workout.startDate, style: .time)
                            Text("-")
                            Text(workout.endDate, style: .time)
                        }
                        .font(.system(size: 10))

                    }
                })

            }

        }
        .sheet(isPresented: $showSheet, content: {
            if let selectedWorkout {
                ScrollView {
                    HKWorkoutView(workout: selectedWorkout)
                    Spacer()
                        .frame(height: 8)
                    
                    Button(action: {
                        showSheet = false
                    }, label: {
                       Text("Done")
                    })

                }
                .toolbarVisibility(.hidden, for: .navigationBar)
            }
        })
        .onChange(of: showSheet, {
            if !showSheet {
                selectedWorkout = nil
            }
        })
    }
}




#Preview {
//    let workoutsPredicate = HKQuery.predicateForWorkouts(with: .greaterThan, duration: 0)
//    let datePredicate = NSPredicate(format: "startDate >= %@", Calendar.current.startOfDay(for: Date()) as NSDate)
//    let calendar = Calendar.current
//    var components = calendar.dateComponents([.era, .year, .month, .day], from: Date())
//    components.calendar = calendar
//
//    let predicate = HKQuery.predicateForActivitySummary(with: components)

    return ActivityRingView()
        .environment(WorkoutManager())
//        .onAppear {
//            print(workoutsPredicate)
//            print(datePredicate)
//            print(NSCompoundPredicate(andPredicateWithSubpredicates: [workoutsPredicate, datePredicate]))
//        }
}
