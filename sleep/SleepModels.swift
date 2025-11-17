//
//  SleepModels.swift
//  sleep
//
//  Created by ChatGPT on 17/11/25.
//

import Foundation
import SwiftUI

struct SleepEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var mood: Mood
    var latencyMinutes: Int
    var wakeCount: Int
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        mood: Mood = .refreshed,
        latencyMinutes: Int,
        wakeCount: Int,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.mood = mood
        self.latencyMinutes = latencyMinutes
        self.wakeCount = wakeCount
        self.notes = notes
    }
}

enum Mood: String, Codable, CaseIterable, Identifiable {
    case refreshed = "精神好"
    case okay = "还行"
    case tired = "有点累"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .refreshed: return .green
        case .okay: return .yellow
        case .tired: return .orange
        }
    }
}

struct RoutineStep: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var icon: String
    var durationMinutes: Int
    var completed: Bool

    init(
        id: UUID = UUID(),
        title: String,
        icon: String,
        durationMinutes: Int,
        completed: Bool = false
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.durationMinutes = durationMinutes
        self.completed = completed
    }
}

struct SoundscapeTrack: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var kind: SoundKind
    var volume: Double
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        kind: SoundKind,
        volume: Double = 0.7,
        isEnabled: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.kind = kind
        self.volume = volume
        self.isEnabled = isEnabled
    }
}

enum SoundKind: String, Codable, Hashable, CaseIterable {
    case pinkNoise
    case rain
    case fireplace

    var icon: String {
        switch self {
        case .pinkNoise: return "waveform"
        case .rain: return "cloud.rain"
        case .fireplace: return "flame"
        }
    }
}

struct BreathingPattern: Identifiable, Hashable {
    struct Phase: Hashable {
        let title: String
        let duration: Int
    }

    let id: UUID
    var name: String
    var description: String
    var phases: [Phase]

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        phases: [Phase]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.phases = phases
    }
}

struct SleepSummary {
    var averageLatency: Double
    var averageWakeCount: Double
    var recentMood: Mood?
    var lastEntry: SleepEntry?
}
