//
//  ContentView.swift
//  GlassWorkout Watch App
//
//  Created by Patrick de Nonneville on 13/06/2024.
//

import SwiftUI
import WatchKit


struct ContentView: View {
    @StateObject private var workoutManager = WorkoutManager.shared
    @State private var timeElapsed = 0
    let epsilon = 0.000000000000000001
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        var pace = if workoutManager.speed == 0 { Text("⏱️-- min/km")
        } else {
            Text("⏱️\(1000/workoutManager.speed/60, specifier: "%.0f").\(1000/workoutManager.speed-1000/workoutManager.speed/60, specifier: "%.0f") min/km")
        }
        VStack {
            if workoutManager.isWorkoutSessionActive{
                Button(action: {
                    workoutManager.stopWorkout()
                }) {
                    Text("▶️")
                }
            } else {
                Button(action: {
                    workoutManager.startWorkout()
                }) {
                    Text("⏹️")
                }}
            HStack{
                Text("❤️\(workoutManager.heartRate, specifier: "%.0f") BPM")
                Text("⚡️\(workoutManager.power, specifier: "%.0f") w")
            }.padding()
            HStack{
                Text("📏\(workoutManager.distance/1000, specifier: "%.2f") km")
                Text("⏰\(timeElapsed)s")
            }.padding()
            HStack{
                pace
            }.padding()
        }
        .padding()
        .onAppear {
            workoutManager.requestAuthorization()
        }
        .onReceive(timer) { time in
                if workoutManager.isWorkoutSessionActive {
                    timeElapsed += 1
                }}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



///#Preview {
///    ContentView()
///}


