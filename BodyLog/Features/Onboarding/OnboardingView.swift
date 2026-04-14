// Created by Banghua Zhao on 14/04/2026
// Copyright Apps Bay Limited. All rights reserved.

import SwiftUI

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(AppState.self) private var appState
    @State private var step = 0
    let onFinished: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ProgressView(value: Double(step + 1), total: 2)
                    .tint(.blue)
                    .padding(.top, 8)

                Group {
                    if step == 0 {
                        introStep
                    } else {
                        setupStep
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)

                actionBar
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .navigationTitle("Welcome to BodyLog")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.loadInitialValuesIfNeeded()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var introStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Track your body data with less effort.")
                    .font(.title2.weight(.semibold))
                Text("Start simple: set your baseline, define your goal, and log consistently.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            introductionItem(
                icon: "target",
                title: "Set clear goals",
                message: "Add start and goal values for Weight and Height to unlock progress tracking."
            )
            introductionItem(
                icon: "repeat.circle",
                title: "Use your preferred units",
                message: "Choose Metric or Imperial as default. You can change this later in Settings."
            )
            introductionItem(
                icon: "calendar",
                title: "Build a routine",
                message: "Log entries regularly (daily or weekly) to get better trend insights."
            )
        }
    }

    private var setupStep: some View {
        Form {
            Section("Default Unit System") {
                Picker("Unit System", selection: $viewModel.selectedUnitSystem) {
                    ForEach(UnitSystem.allCases) { system in
                        Text(system.displayName).tag(system)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Weight Goal Setup") {
                valueRow(title: "Start", text: $viewModel.weightStartText, unit: viewModel.unitSuffixes.weight)
                valueRow(title: "Goal", text: $viewModel.weightGoalText, unit: viewModel.unitSuffixes.weight)
            }

            Section("Height Goal Setup") {
                valueRow(title: "Start", text: $viewModel.heightStartText, unit: viewModel.unitSuffixes.height)
                valueRow(title: "Goal", text: $viewModel.heightGoalText, unit: viewModel.unitSuffixes.height)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            if step == 1 {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.2)) { step = 0 }
                }
                .buttonStyle(.bordered)
            }

            Button(step == 0 ? "Continue" : "Get Started") {
                if step == 0 {
                    withAnimation(.easeInOut(duration: 0.2)) { step = 1 }
                } else {
                    completeOnboarding()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(step == 1 && !viewModel.canFinish)
        }
    }

    private func introductionItem(icon: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.blue)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func valueRow(title: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }

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
