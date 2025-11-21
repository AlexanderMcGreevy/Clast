import SwiftUI
import FamilyControls

struct FocusSettingsView: View {
    @StateObject private var selectionStore = SelectionStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isPickerPresented = false
    @State private var currentSelection = FamilyActivitySelection()

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Header
                VStack(spacing: 12) {
                    Image(systemName: "app.badge.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)

                    Text("Focus Settings")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Choose apps to block during focus sessions")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Selection Summary
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Blocked Apps")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))

                            if selectionStore.hasAnySelections {
                                Text("\(selectionStore.totalSelectionCount) apps selected")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("No apps selected")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }

                        Spacer()

                        Image(systemName: selectionStore.hasAnySelections ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 32))
                            .foregroundColor(selectionStore.hasAnySelections ? .green : .white.opacity(0.3))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                }
                .padding(.horizontal, 40)

                Spacer()

                // Action Buttons
                VStack(spacing: 16) {
                    Button {
                        isPickerPresented = true
                    } label: {
                        Text("Select Apps to Block")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(.white)
                            )
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(.white, lineWidth: 2)
                            )
                    }
                    .disabled(!selectionStore.hasAnySelections)
                    .opacity(selectionStore.hasAnySelections ? 1.0 : 0.5)
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .familyActivityPicker(
            isPresented: $isPickerPresented,
            selection: $currentSelection
        )
        .onChange(of: currentSelection) { oldValue, newValue in
            selectionStore.saveSelection(newValue)
        }
        .onAppear {
            currentSelection = selectionStore.selection
        }
        .navigationBarBackButtonHidden(false)
    }
}

#Preview {
    FocusSettingsView()
        .preferredColorScheme(.dark)
}
