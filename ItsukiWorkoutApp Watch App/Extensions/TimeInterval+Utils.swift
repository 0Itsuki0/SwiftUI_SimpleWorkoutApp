//
//  TimeInterval+utils.swift
//  ItsukiWorkoutApp
//
//  Created by Itsuki on 2025/03/03.
//

import Foundation

extension TimeInterval {
    var hourMinuteSecond: String {
        let interval = Int(self)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / (60*60)) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
