import SwiftUI
import FamilyControls

struct PermissionDeniedView: View {
    @Binding var isPresented: Bool
    @StateObject private var focusController = FocusController.shared

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Permission card
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)

                // Title
                Text("Clast needs Screen Time access")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Message
                Text("To block apps during your focus sessions, Clast requires Screen Time permission.\n\nGo to Settings → Screen Time → App & Website Activity → Clast and enable access.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        Task { @MainActor in
                            do {
                                try await focusController.requestAuthorization()
                                // Authorization granted, close the view
                                isPresented = false
                            } catch {
                                // If it fails, open settings
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    await UIApplication.shared.open(url)
                                }
                            }
                        }
                    } label: {
                        Text("Grant Permission")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 27)
                                    .fill(.white)
                            )
                    }

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open Settings")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }

                    Button {
                        isPresented = false
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    PermissionDeniedView(isPresented: .constant(true))
        .preferredColorScheme(.dark)
}
