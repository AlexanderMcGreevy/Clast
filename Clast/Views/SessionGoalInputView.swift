//
//  SessionGoalInputView.swift
//  Clast
//
//  Created by Alexander McGreevy on 11/13/25.
//

import SwiftUI

struct SessionGoalInputView: View {
    @Binding var isPresented: Bool
    let onGoalSubmitted: (String) -> Void
    
    @State private var goalText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("Set Your Session Goal")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("What do you want to accomplish during this focus session?")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Goal Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Goal")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    TextEditor(text: $goalText)
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
                    
                    Text("Be specific about what you want to complete")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button {
                        isTextFieldFocused = false
                        onGoalSubmitted(goalText)
                    } label: {
                        Text("Start Session")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(.white)
                            )
                    }
                    .disabled(goalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(goalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                    
                    Button {
                        isPresented = false
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}
