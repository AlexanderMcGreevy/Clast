import SwiftUI

struct ProofGateView: View {
    let timeRemaining: Int
    let onReturnToSession: () -> Void
    let onBreakTaken: () -> Void
    let onEndEarly: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var proofText: String = ""
    @State private var hasSubmitted = false
    @State private var passed = false
    @State private var isNavigatingToBreak = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Title
                VStack(spacing: 12) {
                    Text("Prove Your Progress")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Describe what you accomplished during this focus session.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Text Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Progress")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))

                    TextEditor(text: $proofText)
                        .focused($isTextFieldFocused)
                        .frame(height: 180)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.1))
                        )
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                        .scrollContentBackground(.hidden)
                }
                .padding(.horizontal, 40)

                // Result Display (after submission)
                if hasSubmitted {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 24))
                            Text(passed ? "Progress Verified" : "Insufficient Progress")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(passed ? .green : .red)
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(passed ? .green.opacity(0.2) : .red.opacity(0.2))
                        )
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 16) {
                    if !hasSubmitted {
                        Button {
                            isTextFieldFocused = false
                            hasSubmitted = true
                            // Simulate random pass/fail (70% pass rate)
                            passed = proofText.count > 10 && Bool.random() || proofText.count > 20
                        } label: {
                            Text("Submit Proof")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(.white)
                                )
                        }
                        .disabled(proofText.isEmpty)
                        .opacity(proofText.isEmpty ? 0.5 : 1.0)
                        .padding(.horizontal, 40)
                    } else if passed {
                        Button {
                            isNavigatingToBreak = true
                        } label: {
                            Text("Continue")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(.green)
                                )
                        }
                        .padding(.horizontal, 40)
                    } else {
                        Button {
                            hasSubmitted = false
                            proofText = ""
                        } label: {
                            Text("Try Again")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(.white, lineWidth: 2)
                                )
                        }
                        .padding(.horizontal, 40)
                    }
                }

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    onReturnToSession()
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Return to Session")
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .navigationDestination(isPresented: $isNavigatingToBreak) {
            BreakUnlockedView(
                timeRemaining: timeRemaining,
                onReturnToSession: onReturnToSession,
                onBreakTaken: onBreakTaken,
                onEndEarly: onEndEarly
            )
        }
    }
}

#Preview {
    ProofGateView(timeRemaining: 900, onReturnToSession: {}, onBreakTaken: {}, onEndEarly: {})
        .preferredColorScheme(.dark)
}
