import SwiftUI

struct FocusHomeView: View {
    @State private var selectedHours: Int = 0
    @State private var selectedMinutes: Int = 25
    @State private var isNavigatingToSession = false

    let hours = Array(0...23)
    let minutes = Array(0...59)

    var body: some View {
        NavigationStack {
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
                        isNavigatingToSession = true
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

                    Spacer()
                }
            }
            .navigationDestination(isPresented: $isNavigatingToSession) {
                RunningSessionView(hours: selectedHours, minutes: selectedMinutes)
            }
        }
    }
}

#Preview {
    FocusHomeView()
        .preferredColorScheme(.dark)
}
