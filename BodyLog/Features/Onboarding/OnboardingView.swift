// Created by Banghua Zhao on 14/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import SwiftUI

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(AppState.self) private var appState
    @State private var page = 0
    let onFinished: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if page == 0 {
                    welcomePage
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    setupPage
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
            .clipped()
            .frame(maxHeight: .infinity)

            bottomBar
        }
        .ignoresSafeArea(.keyboard)
        .onAppear { viewModel.loadInitialValuesIfNeeded() }
        .onChange(of: viewModel.selectedUnitSystem) { old, new in
            viewModel.convertValues(from: old, to: new)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Welcome Page

    private var welcomePage: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    Image(systemName: "figure.arms.open")
                        .font(.system(size: 52))
                        .foregroundStyle(.blue)
                }
                .padding(.top, 56)
                .padding(.bottom, 20)

                Text("BodyLog")
                    .font(.largeTitle.weight(.bold))
                    .padding(.bottom, 8)

                Text("Track what matters. Reach your goals.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 44)

                VStack(alignment: .leading, spacing: 22) {
                    featureRow(
                        icon: "target",
                        color: .blue,
                        title: "Set clear goals",
                        description: "Define your start and target to unlock progress tracking."
                    )
                    featureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green,
                        title: "See real trends",
                        description: "Charts and stats that show how far you've come."
                    )
                    featureRow(
                        icon: "calendar.badge.checkmark",
                        color: .orange,
                        title: "Build a habit",
                        description: "Log daily or weekly for accurate insights over time."
                    )
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Setup Page

    private var setupPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quick Setup")
                        .font(.largeTitle.weight(.bold))
                    Text("Choose your units and set a starting point.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // Unit system
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("Unit System")
                    HStack(spacing: 12) {
                        ForEach(UnitSystem.allCases) { system in
                            unitSystemCard(system)
                        }
                    }
                }

                // Weight
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("Weight")
                    metricCard(
                        icon: "scalemass.fill",
                        name: "Weight",
                        color: .blue,
                        unit: viewModel.unitSuffixes.weight,
                        startText: $viewModel.weightStartText,
                        goalText: $viewModel.weightGoalText
                    )
                }

                // Height
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("Height")
                    metricCard(
                        icon: "figure.stand",
                        name: "Height",
                        color: .green,
                        unit: viewModel.unitSuffixes.height,
                        startText: $viewModel.heightStartText,
                        goalText: $viewModel.heightGoalText
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                if page == 1 {
                    Button("Back") {
                        withAnimation(.easeInOut(duration: 0.3)) { page = 0 }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Button(page == 0 ? "Continue" : "Get Started") {
                    if page == 0 {
                        withAnimation(.easeInOut(duration: 0.3)) { page = 1 }
                    } else {
                        completeOnboarding()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(page == 1 && !viewModel.canFinish)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .trailing) {
                    if page == 1 && viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 16)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(.regularMaterial)
    }

    // MARK: - Subviews

    private func featureRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func unitSystemCard(_ system: UnitSystem) -> some View {
        let isSelected = viewModel.selectedUnitSystem == system
        return Button {
            viewModel.selectedUnitSystem = system
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .white : .secondary)
                    Text(system.displayName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isSelected ? .white : .primary)
                }
                Text(system == .metric ? "kg · cm" : "lbs · in")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? Color.blue : Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private func metricCard(
        icon: String,
        name: String,
        color: Color,
        unit: String,
        startText: Binding<String>,
        goalText: Binding<String>
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(name)
                    .font(.headline)
                Spacer()
                Text(unit)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: unit)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().padding(.leading, 16)

            metricValueRow(label: "Start", text: startText, unit: unit)

            Divider().padding(.leading, 16)

            metricValueRow(label: "Goal", text: goalText, unit: unit)
        }
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func metricValueRow(label: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            TextField("—", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .font(.body.monospacedDigit())
            Text(unit)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: unit)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Actions

    private func completeOnboarding() {
        Task {
            let saved = await viewModel.saveOnboardingData()
            guard saved else { return }
            appState.unitSystem = viewModel.selectedUnitSystem
            appState.hasCompletedOnboarding = true
            onFinished()
        }
    }
}
