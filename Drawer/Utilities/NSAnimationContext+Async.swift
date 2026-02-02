//
//  NSAnimationContext+Async.swift
//  Drawer
//
//  Created by OpenCode on 2026-02-02.
//
//  Async wrapper for NSAnimationContext to replace completion handler patterns
//  with modern Swift Concurrency.
//

import AppKit

extension NSAnimationContext {
    /// Runs an animation group and awaits its completion.
    ///
    /// This async wrapper replaces the completion handler pattern with structured concurrency.
    ///
    /// Example usage:
    /// ```swift
    /// await NSAnimationContext.runAnimationGroup { context in
    ///     context.duration = 0.3
    ///     panel.animator().alphaValue = 1
    /// }
    /// // Animation complete - continue here
    /// ```
    ///
    /// - Parameter changes: A closure that configures the animation context and applies animations.
    @MainActor
    static func runAnimationGroup(_ changes: @escaping (NSAnimationContext) -> Void) async {
        await withCheckedContinuation { continuation in
            runAnimationGroup(changes) {
                continuation.resume()
            }
        }
    }
}
