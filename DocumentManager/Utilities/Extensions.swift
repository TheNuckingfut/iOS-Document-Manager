import Foundation
import SwiftUI
import UIKit
import Combine

/**
 * Utility Extensions
 *
 * This file contains extensions to standard types and protocols that provide
 * additional functionality used throughout the application. Extending existing
 * types with new methods and computed properties keeps the code more concise
 * and readable.
 */

// MARK: - Date Extensions

/**
 * Extensions for the Date type
 *
 * These extensions provide convenient formatting options for displaying dates
 * in a user-friendly way throughout the application.
 */
extension Date {
    /**
     * Formats a date as a string with customizable style
     *
     * - Parameter style: The DateFormatter style to use (default: .medium)
     * - Returns: A formatted string representation of the date
     *
     * Example: "Jan 12, 2023, 2:30 PM" (for medium style)
     */
    func formattedString(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /**
     * Provides a relative time description of the date
     *
     * Returns a localized string describing the date relative to the current time
     * (e.g., "2 hours ago", "yesterday", "in 3 days")
     *
     * - Returns: A string representing the relative time
     */
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - View Extensions

/**
 * Extensions for SwiftUI Views
 *
 * These extensions add convenient functionality to all SwiftUI views,
 * making UI customization easier and more consistent.
 */
extension View {
    /**
     * Applies corner radius to specific corners of a view
     *
     * Unlike the standard cornerRadius modifier which applies to all corners,
     * this allows applying radius to specific corners only.
     *
     * - Parameters:
     *   - radius: The radius to apply to the corners
     *   - corners: Which corners to round (e.g., .topLeft, .bottomRight, etc.)
     * - Returns: A modified view with the specified corner radius
     */
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    /**
     * Dismisses the keyboard by resigning first responder status
     *
     * Call this method when you need to dismiss the keyboard programmatically,
     * such as when tapping outside a text field or submitting a form.
     */
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Custom Shapes

/**
 * Custom shape for applying radius to specific corners
 *
 * This shape is used by the cornerRadius extension on View to create
 * views with selective corner rounding.
 */
struct RoundedCorner: Shape {
    /// The radius to apply to the selected corners
    var radius: CGFloat = .infinity
    
    /// Which corners should be rounded
    var corners: UIRectCorner = .allCorners

    /**
     * Creates a path with rounded corners
     *
     * - Parameter rect: The rectangle in which to create the path
     * - Returns: A Path with the specified corners rounded
     */
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - String Extensions

/**
 * Extensions for String type
 *
 * These extensions add useful string manipulation and validation functionality.
 */
extension String {
    /**
     * Determines if a string is empty or contains only whitespace
     *
     * This is useful for validating user input where whitespace-only
     * should be treated the same as an empty string.
     *
     * - Returns: True if the string is empty or contains only whitespace characters
     */
    var isBlank: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Publisher Extensions

/**
 * Extensions for Publishers in the Combine framework
 *
 * These extensions enable better interoperability between Combine and Swift's
 * modern async/await concurrency system by providing bridging functions.
 */
extension Publisher {
    /**
     * Maps publisher values using an async transform
     *
     * This operator bridges between Combine publishers and Swift's async/await,
     * allowing asynchronous operations to be performed on publisher values.
     *
     * - Parameter transform: An async closure that transforms the output
     * - Returns: A publisher that emits the transformed values
     */
    func asyncMap<T>(_ transform: @escaping (Output) async -> T) -> Publishers.FlatMap<Future<T, Error>, Publishers.MapError<Self, Error>> where Failure == Error {
        flatMap { value in
            Future { promise in
                Task {
                    do {
                        let result = await transform(value)
                        promise(.success(result))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
    
    /**
     * Maps publisher values using an async throwing transform
     *
     * Similar to asyncMap, but handles transforms that can throw errors.
     * This provides complete integration between Combine and async/await.
     *
     * - Parameter transform: An async throwing closure that transforms the output
     * - Returns: A publisher that emits the transformed values or errors
     */
    func asyncMap<T>(_ transform: @escaping (Output) async throws -> T) -> Publishers.FlatMap<Future<T, Error>, Publishers.MapError<Self, Error>> where Failure == Error {
        flatMap { value in
            Future { promise in
                Task {
                    do {
                        let result = try await transform(value)
                        promise(.success(result))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
}

// MARK: - UIApplication Extensions

/**
 * Extensions for UIApplication
 *
 * These extensions provide app-wide utility functions.
 */
extension UIApplication {
    /**
     * Dismisses the keyboard app-wide
     *
     * This is an alternative to the View.hideKeyboard() extension that can
     * be called from anywhere, not just within a SwiftUI view context.
     */
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
