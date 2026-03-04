import SwiftUI

/// Provides TraceObservable via EnvironmentObject to the composition subtree.
/// Call TraceIOS.initialize(config:) in your App init before using this.
///
/// Usage:
/// ```swift
/// @main
/// struct MyApp: App {
///     init() {
///         TraceIOS.initialize(config: .init(apiKey: "tr_live_xxx"))
///     }
///     var body: some Scene {
///         WindowGroup {
///             TraceProvider {
///                 AppRootView()
///             }
///         }
///     }
/// }
/// ```
public struct TraceProvider<Content: View>: View {

    let content: () -> Content
    @StateObject private var trace = TraceObservable.shared

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        content()
            .environmentObject(trace)
    }
}
