//
//  ItsukiWorkoutAppApp.swift
//  ItsukiWorkoutApp Watch App
//
//  Created by Itsuki on 2025/03/02.
//

import SwiftUI

@main
struct ItsukiWorkoutApp_Watch_AppApp: App {
    @State private var workoutManager = WorkoutManager()
    var body: some Scene {
        WindowGroup {
            NavigationStack {
//                NewWorkoutView()
//                DailySummaryView()
                ContentView()
                    .environment(workoutManager)
            }
        }
    }
}
