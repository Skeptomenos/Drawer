//
//  OnboardingView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

// MARK: - OnboardingStep

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case permissions = 1
    case tutorial = 2
    case completion = 3

    var canSkip: Bool {
        switch self {
        case .welcome, .completion:
            return false
        case .permissions, .tutorial:
            return true
        }
    }
}

// MARK: - OnboardingView

struct OnboardingView: View {

    // MARK: - Environment & State

    @Environment(\.dismiss) private var dismiss
    @State private var permissionManager = PermissionManager.shared
    @State private var currentStep: OnboardingStep = .welcome

    // MARK: - Properties

    let onComplete: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            navigationBar
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
        }
        .frame(width: 520, height: 480)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Step Content Views

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .welcome:
            WelcomeStepView()
        case .permissions:
            PermissionsStepView()
        case .tutorial:
            TutorialStepView()
        case .completion:
            CompletionStepView()
        }
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        HStack {
            if currentStep.canSkip {
                Button("Skip") {
                    advanceToNextStep()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Spacer()

            stepIndicator

            Spacer()

            if currentStep == .completion {
                Button("Get Started") {
                    completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button(nextButtonTitle) {
                    advanceToNextStep()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canAdvance)
            }
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                Circle()
                    .fill(step == currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }

    // MARK: - Computed Properties

    private var nextButtonTitle: String {
        switch currentStep {
        case .welcome:
            return "Continue"
        case .permissions:
            return permissionManager.hasAllPermissions ? "Continue" : "Continue Anyway"
        case .tutorial:
            return "Continue"
        case .completion:
            return "Get Started"
        }
    }

    private var canAdvance: Bool {
        true
    }

    // MARK: - Private Methods

    private func advanceToNextStep() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = nextStep
            }
        }
    }

    private func completeOnboarding() {
        onComplete()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}
