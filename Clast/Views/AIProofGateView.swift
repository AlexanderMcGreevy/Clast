//
//  AIProofGateView.swift
//  Clast
//
//  Created by Alexander McGreevy on 11/13/25.
//

import SwiftUI

struct AIProofGateView: View {
    let timeRemaining: Int
    let onReturnToSession: () -> Void
    let onBreakTaken: () -> Void
    let onEndEarly: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var stateManager = SessionStateManager.shared
    
    @State private var proofText: String = ""
    @State private var selectedImages: [UIImage] = []
    @State private var recognizedImageText: String = ""
    @State private var isRecognizingText = false
    @State private var isVerifying = false
    @State private var verificationResult: ProgressVerificationResponse?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isNavigatingToBreak = false
    @FocusState private var isTextFieldFocused: Bool

    var hasAnyInput: Bool {
        !proofText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImages.isEmpty
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    isTextFieldFocused = false
                }

            ScrollView {
                VStack(spacing: 30) {
                    Spacer()
                        .frame(height: 20)

                    // Title
                    VStack(spacing: 12) {
                        if isVerifying || isRecognizingText {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                        } else {
                            Text("Prove Your Progress")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }

                        Text(
                            isRecognizingText ? "Reading text from images..." :
                            isVerifying ? "Verifying your progress..." :
                            "Show what you accomplished since the last check."
                        )
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    }

                    if let result = verificationResult {
                        // Show verification result
                        ResultDisplayView(result: result)
                            .padding(.horizontal, 40)
                    } else if !isVerifying && !isRecognizingText {
                        // Show input form
                        VStack(spacing: 24) {
                            // Text Input Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Describe Your Progress")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))

                                TextEditor(text: $proofText)
                                    .focused($isTextFieldFocused)
                                    .frame(height: 150)
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
                            
                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(height: 1)
                                Text("AND/OR")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 60)

                            // Image Upload Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Show Your Work (Screenshots/Photos)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 40)

                                ImagePicker(selectedImages: $selectedImages, maxSelection: 5)
                                    .padding(.horizontal, 40)
                                    .onChange(of: selectedImages) { oldValue, newValue in
                                        if !newValue.isEmpty {
                                            recognizeTextFromImages()
                                        }
                                    }
                                
                                if !selectedImages.isEmpty {
                                    ImagePreviewGrid(images: selectedImages) { index in
                                        selectedImages.remove(at: index)
                                        if selectedImages.isEmpty {
                                            recognizedImageText = ""
                                        } else {
                                            recognizeTextFromImages()
                                        }
                                    }
                                }
                                
                                if !recognizedImageText.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "text.viewfinder")
                                                .foregroundColor(.green)
                                            Text("Text extracted from images")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.green)
                                        }
                                        .padding(.horizontal, 40)
                                        
                                        Text(recognizedImageText)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                            .padding(.horizontal, 40)
                                            .lineLimit(3)
                                    }
                                }
                            }
                        }
                    }

                    Spacer()
                        .frame(height: 20)

                    // Action Buttons
                    if let result = verificationResult {
                        if result.allowBreak {
                            Button {
                                isNavigatingToBreak = true
                            } label: {
                                Text("Take Your Break")
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
                                // Reset for retry
                                verificationResult = nil
                                proofText = ""
                                selectedImages = []
                                recognizedImageText = ""
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
                    } else if !isVerifying && !isRecognizingText {
                        Button {
                            verifyProgress()
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
                        .disabled(!hasAnyInput)
                        .opacity(hasAnyInput ? 1.0 : 0.5)
                        .padding(.horizontal, 40)
                    }

                    Spacer()
                        .frame(height: 40)
                }
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
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .navigationDestination(isPresented: $isNavigatingToBreak) {
            if let result = verificationResult {
                BreakUnlockedView(
                    breakDuration: result.breakDuration,
                    score: result.score,
                    timeRemaining: timeRemaining,
                    onReturnToSession: onReturnToSession,
                    onBreakTaken: onBreakTaken,
                    onEndEarly: onEndEarly
                )
            }
        }
    }
    
    private func recognizeTextFromImages() {
        isRecognizingText = true
        
        Task {
            do {
                let extractedText = try await TextRecognitionService.shared.recognizeText(from: selectedImages)
                
                await MainActor.run {
                    recognizedImageText = extractedText
                    isRecognizingText = false
                }
            } catch {
                await MainActor.run {
                    isRecognizingText = false
                    recognizedImageText = ""
                    errorMessage = "Could not read text from images: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func verifyProgress() {
        guard let state = stateManager.currentState else {
            errorMessage = "No active session state found"
            showError = true
            return
        }
        
        isTextFieldFocused = false
        isVerifying = true
        
        Task {
            do {
                // Combine user's written text with extracted image text
                let combinedScrapedText = [proofText, recognizedImageText]
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .joined(separator: "\n\n")
                
                // Calculate delta from previous state
                let delta = stateManager.getScrapedTextDelta(newText: combinedScrapedText)
                
                // Call verification service
                let result = try await ProgressVerificationService.shared.verifyProgress(
                    sessionGoal: state.sessionGoal,
                    currentSummary: state.stateSummary,
                    userNote: proofText.isEmpty ? "(User provided images only)" : proofText,
                    scrapedDelta: delta
                )
                
                // Update state with new summary
                stateManager.updateState(newSummary: result.updatedSummary, scrapedText: combinedScrapedText)
                
                await MainActor.run {
                    isVerifying = false
                    verificationResult = result
                }
                
            } catch {
                await MainActor.run {
                    isVerifying = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Result Display View

struct ResultDisplayView: View {
    let result: ProgressVerificationResponse
    
    var body: some View {
        VStack(spacing: 20) {
            // Score Visualization
            ZStack {
                Circle()
                    .stroke(lineWidth: 12)
                    .foregroundColor(.white.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: result.score)
                    .stroke(
                        result.allowBreak ? Color.green : Color.orange,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.8), value: result.score)
                
                VStack(spacing: 4) {
                    Text("\(Int(result.score * 100))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("score")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Status
            HStack(spacing: 8) {
                Image(systemName: result.allowBreak ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 24))
                Text(result.allowBreak ? "Break Earned" : "Keep Working")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(result.allowBreak ? .green : .orange)
            
            // Reason
            Text(result.reason)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
}

#Preview {
    AIProofGateView(
        timeRemaining: 900,
        onReturnToSession: {},
        onBreakTaken: {},
        onEndEarly: {}
    )
    .preferredColorScheme(.dark)
}
