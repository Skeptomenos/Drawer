//
//  SettingsMenuBarLayoutView.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import SwiftUI

// MARK: - SettingsMenuBarLayoutView

/// Settings view for configuring menu bar icon layout.
///
/// Displays three sections (Shown, Hidden, Always Hidden) where users can:
/// - See which icons are in each section
/// - Drag and drop icons between sections
/// - Add spacers between icons (Phase 4.2.4)
///
/// Business logic is handled by MenuBarLayoutViewModel (ARCH-002).
struct SettingsMenuBarLayoutView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - ViewModel

    @State private var viewModel = MenuBarLayoutViewModel()

    // MARK: - Local UI State

    /// Whether to show the reset confirmation alert
    @State private var showResetConfirmation: Bool = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LayoutDesign.sectionSpacing) {
                headerSection

                if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                }

                ForEach(MenuBarSectionType.allCases) { sectionType in
                    LayoutSectionView(
                        sectionType: sectionType,
                        items: viewModel.items(for: sectionType),
                        imageCache: viewModel.imageCache,
                        onMoveItem: { item, targetSection, insertIndex in
                            viewModel.moveItem(item, to: targetSection, at: insertIndex)
                        }
                    )
                }

                paletteSection

                Spacer(minLength: 16)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            viewModel.configure(with: appState)
            if viewModel.layoutItems.isEmpty && !viewModel.isRefreshing {
                viewModel.refreshItems()
            }
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(LayoutDesign.sectionPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutDesign.sectionCornerRadius)
                .fill(Color.orange.opacity(0.1))
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()

                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .frame(width: LayoutDesign.headerIconSize, height: LayoutDesign.headerIconSize)

                        Image(systemName: "menubar.rectangle")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }

                    Text("Menu Bar Items")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Drag items between sections to re-order your menu bar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .overlay(alignment: .topTrailing) {
                refreshButton
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: LayoutDesign.sectionCornerRadius)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }

    private var refreshButton: some View {
        Button {
            viewModel.refreshItems()
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isRefreshing)
        .padding(8)
    }

    // MARK: - Palette Section

    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: LayoutDesign.sectionHeaderSpacing) {
            Label("Palette", systemImage: "square.grid.2x2")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                Button {
                    viewModel.addSpacer()
                } label: {
                    Text("Add a Spacer")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button {
                    showResetConfirmation = true
                } label: {
                    Text("Reset Icon Positions")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .alert("Reset Icon Positions?", isPresented: $showResetConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Reset", role: .destructive) {
                        viewModel.resetIconPositions()
                    }
                } message: {
                    Text("This will clear all saved icon position preferences. Icons will stay in their current positions but won't be restored on next launch.")
                }
            }
            .padding(LayoutDesign.sectionPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: LayoutDesign.sectionCornerRadius)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsMenuBarLayoutView()
        .frame(width: 500, height: 600)
        .environment(AppState.shared)
}
