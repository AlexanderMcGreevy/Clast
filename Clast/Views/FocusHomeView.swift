import SwiftUI
import FamilyControls

struct FocusHomeView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var selectionStore = SelectionStore.shared
    @StateObject private var focusController = FocusController.shared
    
    @State private var selectedHours: Int = 0
    @State private var selectedMinutes: Int = 25
    @State private var isNavigatingToSession = false
    @State private var isNavigatingToSettings = false
    @State private var showPermissionDeniedAlert = false
    
    let hours = Array(0...23)
    let minutes = Array(0...59)
    
    var body: some View {
        ZStack {
            NavigationStack {
                Group {
                    if sessionManager.activeTimer != nil {
                        // Show running session if timer is active
                        RunningSessionView(hours: 0, minutes: 0)
                    } else {
                        // Show setup screen
                        ZStack {
                            Color.black
                                .ignoresSafeArea()
                            
                            VStack(spacing: 40) {
                                Spacer()
                                
                                // App Title
                                Text("CLAST")
                                    .font(.system(size: 64, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Prove your progress.")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Spacer()
                                
                                // Duration Picker
                                VStack(spacing: 16) {
                                    Text("Focus Duration")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    HStack(spacing: 0) {
                                        // Hours Picker
                                        Picker("Hours", selection: $selectedHours) {
                                            ForEach(hours, id: \.self) { hour in
                                                Text("\(hour)")
                                                    .tag(hour)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 80)
                                        
                                        Text("h")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 30)
                                        
                                        // Minutes Picker
                                        Picker("Minutes", selection: $selectedMinutes) {
                                            ForEach(minutes, id: \.self) { minute in
                                                Text("\(minute)")
                                                    .tag(minute)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 80)
                                        
                                        Text("m")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 30)
                                    }
                                    .frame(height: 150)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(.ultraThinMaterial)
                                    )
                                }
                                .padding(.horizontal, 40)
                                
                                Spacer()
                                
                                // Start Button
                                Button {
                                    // WIRING POINT: Check authorization and configuration before starting
                                    if focusController.authorizationStatus != .approved {
                                        // Show permission denied alert
                                        showPermissionDeniedAlert = true
                                    } else if !selectionStore.hasAnySelections {
                                        // Route to settings if no apps selected
                                        isNavigatingToSettings = true
                                    } else {
                                        isNavigatingToSession = true
                                    }
                                } label: {
                                    Text("Start Focus Session")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 60)
                                        .background(
                                            RoundedRectangle(cornerRadius: 30)
                                                .fill(.white)
                                        )
                                }
                                .padding(.horizontal, 40)
                                
                                // Settings Button
                                Button {
                                    isNavigatingToSettings = true
                                } label: {
                                    HStack {
                                        Image(systemName: "app.badge.fill")
                                        Text("Configure Blocked Apps")
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                }
                                .padding(.horizontal, 40)
                                
                                Spacer()
                            }
                        }
                        .navigationDestination(isPresented: $isNavigatingToSession) {
                            RunningSessionView(hours: selectedHours, minutes: selectedMinutes)
                        }
                        .navigationDestination(isPresented: $isNavigatingToSettings) {
                            FocusSettingsView()
                        }
                    }
                }
                
                // Permission denied overlay
                if showPermissionDeniedAlert {
                    PermissionDeniedView(isPresented: $showPermissionDeniedAlert)
                }
            }
            .task {
                // Refresh authorization status when view appears
                // This ensures we have the latest status from iOS
                // Using .task instead of .onAppear ensures this runs before the view is rendered
                focusController.refreshAuthorizationStatus()

                print("📱 [FocusHomeView] Authorization status: \(focusController.authorizationStatus)")
                print("📱 [FocusHomeView] Has selections: \(selectionStore.hasAnySelections)")
            }
            .onChange(of: focusController.authorizationStatus) { oldStatus, newStatus in
                // Auto-dismiss permission alert if authorization is granted
                if newStatus == .approved && showPermissionDeniedAlert {
                    showPermissionDeniedAlert = false
                    print("✅ [FocusHomeView] Authorization granted - dismissing permission alert")
                }
            }
        }
    }
}

#Preview {
    FocusHomeView()
        .environmentObject(SessionManager())
        .preferredColorScheme(.dark)
}
