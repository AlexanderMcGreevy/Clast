import SwiftUI

struct SettingsView: View {
    @StateObject private var selectionStore = SelectionStore.shared
    @State private var notificationsEnabled = true
    @State private var strictMode = false
    @State private var defaultDuration = 25
    @State private var isNavigatingToFocusSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                Form {
                    Section {
                        Button {
                            isNavigatingToFocusSettings = true
                        } label: {
                            HStack {
                                Label("Blocked Apps", systemImage: "app.badge.fill")
                                    .foregroundColor(.white)
                                Spacer()
                                if selectionStore.hasAnySelections {
                                    Text("\(selectionStore.totalSelectionCount) selected")
                                        .foregroundColor(.white.opacity(0.5))
                                        .font(.system(size: 14))
                                } else {
                                    Text("Not configured")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 14))
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.3))
                                    .font(.system(size: 14))
                            }
                        }
                    } header: {
                        Text("Focus Mode")
                    }

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

                    #if DEBUG
                    Section {
                        Button {
                            ShieldDiagnostics.shared.runDiagnostics()
                        } label: {
                            Label("Run Shield Diagnostics", systemImage: "stethoscope")
                                .foregroundColor(.white)
                        }

                        Button {
                            ShieldDiagnostics.shared.printActiveShields()
                        } label: {
                            Label("Check Active Shields", systemImage: "shield.fill")
                                .foregroundColor(.white)
                        }
                    } header: {
                        Text("Debug Tools")
                    } footer: {
                        Text("Check Xcode console for diagnostic output")
                            .font(.caption)
                    }
                    #endif
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $isNavigatingToFocusSettings) {
                FocusSettingsView()
            }
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
