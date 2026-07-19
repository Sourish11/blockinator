import SwiftUI
import IGBlockCore

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily allowance") {
                    Stepper(
                        "\(appState.dailyAllowanceMinutes) min / day",
                        value: $appState.dailyAllowanceMinutes,
                        in: UserDefaultsSettingsStore.minDailyAllowanceMinutes...UserDefaultsSettingsStore.maxDailyAllowanceMinutes
                    )
                }
                Section("Restricted sections") {
                    Toggle("Reels", isOn: $appState.isReelsRestricted)
                    Toggle("Explore", isOn: $appState.isExploreRestricted)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SettingsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.35))
                .clipShape(Circle())
        }
        .padding(16)
    }
}
