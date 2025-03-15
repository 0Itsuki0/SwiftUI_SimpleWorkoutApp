//
//  ContentView.swift
//  ItsukiWorkoutApp Watch App
//
//  Created by Itsuki on 2025/03/02.
//

import SwiftUI

struct ContentView: View {
    @Environment(WorkoutManager.self) private var workoutManager

    var body: some View {
        VStack(spacing: 24) {
            NavigationLink(destination: {
                NewWorkoutView()
                    .environment(workoutManager)
            }, label: {
                Text("New Workout")
            })
            
            NavigationLink(destination: {
                DailySummaryView()
                    .environment(workoutManager)
            }, label: {
                Text("Daily Summary")
            })
        
        }
    }
}

#Preview {
    NavigationStack {
        ContentView()
            .environment(WorkoutManager())
    }
}
