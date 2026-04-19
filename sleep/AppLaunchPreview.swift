import SwiftUI

enum AppLaunchPreviewScreen: String {
    case onboarding
    case tonight
    case more
    case history
    case soundscape
}

enum AppLaunchPreview {
    static var current: AppLaunchPreviewScreen? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "--preview-screen") else {
            return nil
        }
        let valueIndex = arguments.index(after: flagIndex)
        guard valueIndex < arguments.endIndex else {
            return nil
        }
        return AppLaunchPreviewScreen(rawValue: arguments[valueIndex])
    }
}

struct AppLaunchPreviewRootView: View {
    let screen: AppLaunchPreviewScreen

    var body: some View {
        Group {
            switch screen {
            case .onboarding:
                NavigationStack {
                    OnboardingView()
                }
            case .tonight:
                NavigationStack {
                    ContentView()
                }
            case .more:
                RootTabView(initialTab: .more)
            case .history:
                NavigationStack {
                    SleepHistoryView()
                }
            case .soundscape:
                NavigationStack {
                    SoundscapeView()
                }
            }
        }
    }
}
