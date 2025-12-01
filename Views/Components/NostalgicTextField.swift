//
//  NostalgicTextField.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

struct NostalgicTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var errorMessage: String?
    var keyboardType: UIKeyboardType = .default

    @FocusState private var isFocused: Bool
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isFocused ? AppColors.primary : AppColors.textSecondary)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }

                TextField(placeholder, text: $text)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textPrimary)
                    .keyboardType(keyboardType)
                    .focused($isFocused)
                    .onChange(of: isFocused) { oldValue, newValue in
                        withAnimation(Constants.Animation.bouncy) {
                            isAnimating = newValue
                        }

                        if newValue {
                            Constants.Haptics.selection.selectionChanged()
                        }
                    }
            }
            .padding(.horizontal, Constants.Layout.paddingMedium)
            .padding(.vertical, Constants.Layout.paddingMedium)
            .background(
                RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusMedium)
                    .fill(Color.white)
                    .shadow(
                        color: isFocused ? AppColors.primary.opacity(0.3) : Color.black.opacity(0.05),
                        radius: isFocused ? 8 : 4,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusMedium)
                    .stroke(
                        errorMessage != nil ? Color.red :
                        isFocused ? AppColors.primary : Color.clear,
                        lineWidth: 2
                    )
            )

            if let errorMessage = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                    Text(errorMessage)
                        .font(.system(size: 14))
                }
                .foregroundColor(.red)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(Constants.Animation.smooth, value: errorMessage)
    }
}

#Preview {
    VStack(spacing: 24) {
        NostalgicTextField(
            placeholder: "Enter your name",
            text: .constant(""),
            icon: "person.fill"
        )

        NostalgicTextField(
            placeholder: "Enter your email",
            text: .constant("test@example.com"),
            icon: "envelope.fill",
            keyboardType: .emailAddress
        )

        NostalgicTextField(
            placeholder: "Job Role",
            text: .constant(""),
            icon: "briefcase.fill",
            errorMessage: "This field is required"
        )
    }
    .padding()
    .background(AppColors.background)
}
