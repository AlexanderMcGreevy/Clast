import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var strictMode = false
    @State private var defaultDuration = 25

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                Form {
                    Section {
                        Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        Toggle("Strict Mode", isOn: $strictMode)

                        Picker("Default Duration", selection: $defaultDuration) {
                            Text("15 min").tag(15)
                            Text("25 min").tag(25)
                            Text("45 min").tag(45)
                            Text("60 min").tag(60)
                        }
                    } header: {
                        Text("Preferences")
                    }

                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Button("About Clast") {
                            // Placeholder action
                        }

                        Button("Support") {
                            // Placeholder action
                        }
                    } header: {
                        Text("App Info")
                    }

                    Section {
                        Button("Clear History") {
                            // Placeholder action
                        }
                        .foregroundColor(.red)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
