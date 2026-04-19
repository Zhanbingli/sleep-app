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
    var bedtime: Date
    var wakeTime: Date
    var stressLevel: StressLevel
    var usedPhoneBeforeBed: Bool
    var hadLateCaffeine: Bool
    var hadAlcohol: Bool
    var settleFeedback: SettleFeedback?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        mood: Mood = .refreshed,
        latencyMinutes: Int,
        wakeCount: Int,
        notes: String = "",
        bedtime: Date? = nil,
        wakeTime: Date? = nil,
        stressLevel: StressLevel = .moderate,
        usedPhoneBeforeBed: Bool = false,
        hadLateCaffeine: Bool = false,
        hadAlcohol: Bool = false,
        settleFeedback: SettleFeedback? = nil
    ) {
        self.id = id
        self.date = date
        self.mood = mood
        self.latencyMinutes = latencyMinutes
        self.wakeCount = wakeCount
        self.notes = notes
        self.bedtime = bedtime ?? date.addingTimeInterval(-8 * 3_600)
        self.wakeTime = wakeTime ?? date
        self.stressLevel = stressLevel
        self.usedPhoneBeforeBed = usedPhoneBeforeBed
        self.hadLateCaffeine = hadLateCaffeine
        self.hadAlcohol = hadAlcohol
        self.settleFeedback = settleFeedback
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case date
        case mood
        case latencyMinutes
        case wakeCount
        case notes
        case bedtime
        case wakeTime
        case stressLevel
        case usedPhoneBeforeBed
        case hadLateCaffeine
        case hadAlcohol
        case settleFeedback
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        mood = try container.decodeIfPresent(Mood.self, forKey: .mood) ?? .okay
        latencyMinutes = try container.decodeIfPresent(Int.self, forKey: .latencyMinutes) ?? 20
        wakeCount = try container.decodeIfPresent(Int.self, forKey: .wakeCount) ?? 1
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        bedtime = try container.decodeIfPresent(Date.self, forKey: .bedtime) ?? date.addingTimeInterval(-8 * 3_600)
        wakeTime = try container.decodeIfPresent(Date.self, forKey: .wakeTime) ?? date
        stressLevel = try container.decodeIfPresent(StressLevel.self, forKey: .stressLevel) ?? .moderate
        usedPhoneBeforeBed = try container.decodeIfPresent(Bool.self, forKey: .usedPhoneBeforeBed) ?? false
        hadLateCaffeine = try container.decodeIfPresent(Bool.self, forKey: .hadLateCaffeine) ?? false
        hadAlcohol = try container.decodeIfPresent(Bool.self, forKey: .hadAlcohol) ?? false
        settleFeedback = try container.decodeIfPresent(SettleFeedback.self, forKey: .settleFeedback)
    }

    var sleepDurationHours: Double {
        max(0, wakeTime.timeIntervalSince(bedtime) / 3_600)
    }

    var habitTags: [String] {
        var tags: [String] = []
        if usedPhoneBeforeBed { tags.append("睡前刷手机") }
        if hadLateCaffeine { tags.append("晚咖啡") }
        if hadAlcohol { tags.append("酒精") }
        if stressLevel == .high { tags.append("高压力") }
        return tags
    }
}

enum SettleFeedback: String, Codable, CaseIterable, Identifiable {
    case yes
    case somewhat
    case no

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yes:
            return "有帮助"
        case .somewhat:
            return "有一点"
        case .no:
            return "没有"
        }
    }
}

enum Mood: String, Codable, CaseIterable, Identifiable {
    case refreshed = "精神好"
    case okay = "还行"
    case tired = "有点累"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .refreshed:
            return .green
        case .okay:
            return .yellow
        case .tired:
            return .orange
        }
    }
}

enum StressLevel: String, Codable, CaseIterable, Identifiable {
    case low = "低"
    case moderate = "中"
    case high = "高"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .low:
            return "睡前整体较平静"
        case .moderate:
            return "还有一些杂念"
        case .high:
            return "明显紧绷或停不下来"
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

enum SoundKind: String, Codable, Hashable, CaseIterable, Identifiable {
    case pinkNoise
    case rain
    case fireplace

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pinkNoise:
            return "waveform"
        case .rain:
            return "cloud.rain"
        case .fireplace:
            return "flame"
        }
    }

    var displayName: String {
        switch self {
        case .pinkNoise:
            return "粉噪声"
        case .rain:
            return "雨声"
        case .fireplace:
            return "壁炉"
        }
    }

    var onboardingDescription: String {
        switch self {
        case .pinkNoise:
            return "平稳遮挡环境声"
        case .rain:
            return "更轻柔，更有包裹感"
        case .fireplace:
            return "温暖、适合慢慢降速"
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

enum BreathingPatternPreset: String, Codable, CaseIterable, Identifiable, Hashable {
    case fourSevenEight
    case box
    case coherent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fourSevenEight:
            return "4-7-8"
        case .box:
            return "盒式呼吸"
        case .coherent:
            return "共振呼吸"
        }
    }

    var shortDescription: String {
        switch self {
        case .fourSevenEight:
            return "长呼气，适合脑子停不下来时"
        case .box:
            return "节奏稳定，适合把注意力从手机拉回来"
        case .coherent:
            return "均匀呼吸，适合平稳放松"
        }
    }

    var bedtimeBenefit: String {
        switch self {
        case .fourSevenEight:
            return "先把兴奋感压下来，再去入睡。"
        case .box:
            return "让注意力回到身体，减少分心。"
        case .coherent:
            return "维持平缓节律，适合搭配音景渐弱。"
        }
    }

    var pattern: BreathingPattern {
        switch self {
        case .fourSevenEight:
            return BreathingPattern(
                name: displayName,
                description: "经典入睡放松，呼气更长帮助镇静",
                phases: [
                    .init(title: "吸气", duration: 4),
                    .init(title: "屏息", duration: 7),
                    .init(title: "呼气", duration: 8)
                ]
            )
        case .box:
            return BreathingPattern(
                name: displayName,
                description: "均匀四拍，适合把注意力从屏幕和杂念拉回来",
                phases: [
                    .init(title: "吸气", duration: 4),
                    .init(title: "屏息", duration: 4),
                    .init(title: "呼气", duration: 4),
                    .init(title: "停顿", duration: 4)
                ]
            )
        case .coherent:
            return BreathingPattern(
                name: displayName,
                description: "稳定吸呼节律，帮助身体进入更平缓的状态",
                phases: [
                    .init(title: "吸气", duration: 5),
                    .init(title: "呼气", duration: 5)
                ]
            )
        }
    }
}

enum SleepChallenge: String, Codable, CaseIterable, Identifiable {
    case mindRacing
    case phoneScrolling
    case stressLoad
    case lightSleep
    case noiseSensitive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mindRacing:
            return "脑子停不下来"
        case .phoneScrolling:
            return "总会刷手机"
        case .stressLoad:
            return "压力太高，身体不松"
        case .lightSleep:
            return "容易醒，睡不踏实"
        case .noiseSensitive:
            return "对环境声音很敏感"
        }
    }

    var description: String {
        switch self {
        case .mindRacing:
            return "睡前想很多，明明困了也很难真正进入睡眠。"
        case .phoneScrolling:
            return "本来只想看几分钟，结果越看越晚。"
        case .stressLoad:
            return "脑子和身体都绷着，休息模式切不进来。"
        case .lightSleep:
            return "夜里容易醒，或者一点动静就打断。"
        case .noiseSensitive:
            return "需要外界声音被遮住，才更容易安心。"
        }
    }

    var focusLabel: String {
        switch self {
        case .mindRacing:
            return "先降速"
        case .phoneScrolling:
            return "断开刺激"
        case .stressLoad:
            return "先松下来"
        case .lightSleep:
            return "更平稳"
        case .noiseSensitive:
            return "屏蔽噪音"
        }
    }

    var defaultBreathing: BreathingPatternPreset {
        switch self {
        case .mindRacing:
            return .fourSevenEight
        case .phoneScrolling:
            return .box
        case .stressLoad:
            return .fourSevenEight
        case .lightSleep:
            return .coherent
        case .noiseSensitive:
            return .coherent
        }
    }

    var defaultSound: SoundKind {
        switch self {
        case .mindRacing:
            return .rain
        case .phoneScrolling:
            return .fireplace
        case .stressLoad:
            return .rain
        case .lightSleep:
            return .pinkNoise
        case .noiseSensitive:
            return .pinkNoise
        }
    }

    var defaultFadeMinutes: Int {
        switch self {
        case .mindRacing:
            return 35
        case .phoneScrolling:
            return 30
        case .stressLoad:
            return 40
        case .lightSleep:
            return 45
        case .noiseSensitive:
            return 45
        }
    }
}

enum TonightState: String, CaseIterable, Identifiable, Hashable {
    case racingThoughts
    case stressed
    case scrolling
    case mentallyAlert

    var id: String { rawValue }

    var title: String {
        switch self {
        case .racingThoughts:
            return "脑子停不下来"
        case .stressed:
            return "今晚压力很高"
        case .scrolling:
            return "我还在想刷手机"
        case .mentallyAlert:
            return "身体累，但脑子还亮着"
        }
    }

    var detail: String {
        switch self {
        case .racingThoughts:
            return "先减速，再进入睡眠准备状态。"
        case .stressed:
            return "先把紧绷感降下来。"
        case .scrolling:
            return "先脱离刺激，而不是再做选择。"
        case .mentallyAlert:
            return "先把意识从兴奋切到稳定。"
        }
    }

    var recommendedBreathing: BreathingPatternPreset {
        switch self {
        case .racingThoughts:
            return .fourSevenEight
        case .stressed:
            return .fourSevenEight
        case .scrolling:
            return .box
        case .mentallyAlert:
            return .coherent
        }
    }

    var recommendedSoundKind: SoundKind {
        switch self {
        case .racingThoughts:
            return .rain
        case .stressed:
            return .rain
        case .scrolling:
            return .fireplace
        case .mentallyAlert:
            return .pinkNoise
        }
    }

    var focusLabel: String {
        switch self {
        case .racingThoughts:
            return "先降速"
        case .stressed:
            return "先松下来"
        case .scrolling:
            return "脱离刺激"
        case .mentallyAlert:
            return "切换状态"
        }
    }
}

struct SleepProfile: Codable, Equatable {
    var primaryChallenge: SleepChallenge
    var preferredSound: SoundKind
    var preferredWindDownMinutes: Int
}

struct SleepSummary {
    var averageLatency: Double
    var averageWakeCount: Double
    var averageSleepHours: Double
    var phoneUseRate: Double
    var caffeineRate: Double
    var alcoholRate: Double
    var highStressRate: Double
    var positiveSettleRate: Double
    var recentMood: Mood?
    var lastEntry: SleepEntry?
}

struct TonightPlan {
    var title: String
    var detail: String
    var recommendedBreathing: BreathingPatternPreset
    var fadeMinutes: Int
    var focusLabel: String
    var recommendedSoundKind: SoundKind
    var insight: String
    var stateTitle: String
}
