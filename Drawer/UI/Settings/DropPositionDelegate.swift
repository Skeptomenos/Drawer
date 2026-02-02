import SwiftUI

/// Drop delegate that calculates insertion index based on drop location.
/// Updates `dropInsertIndex` during drag to show the visual indicator.
struct DropPositionDelegate: DropDelegate {

    /// Items in the section (ordered)
    let items: [SettingsLayoutItem]

    /// Cached frames of each item in coordinate space
    let itemFrames: [UUID: CGRect]

    /// Binding to the drop insert index for visual feedback
    @Binding var dropInsertIndex: Int

    func dropUpdated(info: DropInfo) -> DropProposal? {
        // Calculate insert index based on horizontal position
        let dropLocation = info.location
        dropInsertIndex = calculateInsertIndex(at: dropLocation)
        return DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {
        // Keep the last valid index for the actual drop operation
        // The dropDestination handler will use this value
    }

    func performDrop(info: DropInfo) -> Bool {
        // Let the dropDestination handler perform the actual drop
        // This delegate is only for position tracking
        return false
    }

    func validateDrop(info: DropInfo) -> Bool {
        return true
    }

    /// Calculates the insertion index based on the drop point's horizontal position.
    /// - Parameter point: The drop location in the section's coordinate space
    /// - Returns: The index at which to insert the dropped item
    private func calculateInsertIndex(at point: CGPoint) -> Int {
        guard !items.isEmpty else { return 0 }

        // Sort items by their horizontal position (left to right)
        let sortedFrames = items.compactMap { item -> (Int, CGRect)? in
            guard let frame = itemFrames[item.id],
                  let index = items.firstIndex(where: { $0.id == item.id }) else {
                return nil
            }
            return (index, frame)
        }.sorted { $0.1.minX < $1.1.minX }

        // Find the insertion point based on horizontal position
        for (itemIndex, frame) in sortedFrames {
            let midX = frame.midX
            if point.x < midX {
                return itemIndex
            }
        }

        // If past all items, insert at end
        return items.count
    }
}
