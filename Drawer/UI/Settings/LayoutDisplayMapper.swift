//
//  LayoutDisplayMapper.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

/// Maps layout items to their display sections, accounting for Always Hidden being disabled.
struct LayoutDisplayMapper {
    /// Returns items for display in a given section.
    ///
    /// When Always Hidden is disabled, items assigned to Always Hidden are shown in Hidden.
    ///
    /// - Parameters:
    ///   - layoutItems: The full list of layout items.
    ///   - sectionType: The section to display.
    ///   - alwaysHiddenEnabled: Whether Always Hidden is enabled in settings.
    /// - Returns: Items to display in the specified section.
    static func itemsForDisplay(
        layoutItems: [SettingsLayoutItem],
        sectionType: MenuBarSectionType,
        alwaysHiddenEnabled: Bool
    ) -> [SettingsLayoutItem] {
        let itemsForSection = { (section: MenuBarSectionType) -> [SettingsLayoutItem] in
            layoutItems
                .filter { $0.section == section }
                .sorted { $0.order < $1.order }
        }

        if alwaysHiddenEnabled {
            return itemsForSection(sectionType)
        }

        switch sectionType {
        case .visible:
            return itemsForSection(.visible)
        case .hidden:
            return itemsForSection(.alwaysHidden) + itemsForSection(.hidden)
        case .alwaysHidden:
            return []
        }
    }
}
