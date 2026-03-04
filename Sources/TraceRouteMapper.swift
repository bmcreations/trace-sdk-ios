import Foundation
import TraceKMP

/// Result of mapping a deep link — either a navigation route or an action.
/// Mirrors the Kotlin `DeepLinkResult<T>` sealed interface.
public enum TraceDeepLinkResult<Route: Hashable> {
    /// Navigate to the given route.
    case navigate(Route)
    /// Execute a side-effect (e.g. claim a reward) without navigating.
    case action(() -> Void)
}

/// Type-safe wrapper around the shared Kotlin DeepLinkMapperBuilder.
///
/// PathPattern and DeepLinkParams come directly from the KMP framework —
/// the matching algorithm lives in commonMain and is shared with Android.
/// This class only adds Swift generic type safety at the boundary.
///
/// Usage:
/// ```swift
/// let mapper = TraceRouteMapper<AppRoute> { m in
///     m.route("/product/{id}")  { .product(id: $0.require("id")) }
///     m.route("/checkout")      { .checkout(promo: $0["promo"]) }
///     m.route("/invite/{code}") { .invite(code: $0.require("code")) }
///     m.action("/claim/promo/{amount}") { claimReward($0.require("amount")) }
/// }
/// ```
public class TraceRouteMapper<Route: Hashable> {

    public typealias RouteFactory = (TraceDeepLinkParams) -> Route?
    public typealias ActionHandler = (TraceDeepLinkParams) -> Void

    private enum Entry {
        case route(TracePathPattern, (TraceDeepLinkParams) -> Route?)
        case action(TracePathPattern, (TraceDeepLinkParams) -> Void)
    }

    private var entries: [Entry] = []

    public init(_ build: (TraceRouteMapper<Route>) -> Void) {
        build(self)
    }

    /// Register a URI template that maps to a navigation route.
    public func route(_ pattern: String, factory: @escaping RouteFactory) {
        entries.append(.route(TracePathPattern(template: pattern), factory))
    }

    /// Register a URI template that triggers a side-effect without navigation.
    public func action(_ pattern: String, handler: @escaping ActionHandler) {
        entries.append(.action(TracePathPattern(template: pattern), handler))
    }

    /// Backwards-compatible alias for `route()`.
    public func link(_ pattern: String, factory: @escaping RouteFactory) {
        route(pattern, factory: factory)
    }

    /// Matches the deep link and returns a typed result (route or action).
    public func mapResult(_ deepLink: TraceDeepLink) -> TraceDeepLinkResult<Route>? {
        for entry in entries {
            switch entry {
            case .route(let pattern, let factory):
                guard let params = matchParams(pattern: pattern, deepLink: deepLink) else { continue }
                if let route = factory(params) { return .navigate(route) }
            case .action(let pattern, let handler):
                guard let params = matchParams(pattern: pattern, deepLink: deepLink) else { continue }
                return .action { handler(params) }
            }
        }
        return nil
    }

    /// Convenience that returns only navigation routes (ignoring actions).
    /// Called by the view modifier for backwards compatibility.
    public func map(_ deepLink: TraceDeepLink) -> Route? {
        guard case .navigate(let route) = mapResult(deepLink) else { return nil }
        return route
    }

    private func matchParams(pattern: TracePathPattern, deepLink: TraceDeepLink) -> TraceDeepLinkParams? {
        guard let match = pattern.match(path: deepLink.path) else { return nil }
        var merged = match
        deepLink.params.forEach { merged[$0.key] = $0.value }
        return TraceDeepLinkParams(raw: merged)
    }
}

// MARK: - Path pattern (mirrors Kotlin PathPattern in commonMain)

internal class TracePathPattern {

    private enum Segment {
        case literal(String)
        case capture(String)
    }

    private let segments: [Segment]

    init(template: String) {
        self.segments = template
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .components(separatedBy: "/")
            .filter { !$0.isEmpty }
            .map { seg in
                if seg.hasPrefix("{") && seg.hasSuffix("}") {
                    let name = String(seg.dropFirst().dropLast())
                    return .capture(name)
                }
                return .literal(seg)
            }
    }

    func match(path: String) -> [String: String]? {
        let incoming = path
            .components(separatedBy: "?").first ?? path
        let parts = incoming
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .components(separatedBy: "/")
            .filter { !$0.isEmpty }

        guard parts.count == segments.count else { return nil }

        var params: [String: String] = [:]
        for (segment, part) in zip(segments, parts) {
            switch segment {
            case .literal(let value):
                guard value.lowercased() == part.lowercased() else { return nil }
            case .capture(let name):
                params[name] = part
            }
        }
        return params
    }
}

// MARK: - DeepLinkParams (mirrors Kotlin DeepLinkParams in commonMain)

public struct TraceDeepLinkParams {
    private let raw: [String: String]

    internal init(raw: [String: String]) {
        self.raw = raw
    }

    public subscript(key: String) -> String? { raw[key] }

    /// Returns the value for key, crashing with a descriptive message if absent.
    /// Use for parameters your route absolutely requires.
    public func require(_ key: String) -> String {
        guard let value = raw[key] else {
            fatalError("Deep link is missing required parameter '\(key)'. Available: \(raw.keys)")
        }
        return value
    }

    public func int(_ key: String) -> Int?    { raw[key].flatMap { Int($0) } }
    public func bool(_ key: String) -> Bool?  {
        switch raw[key]?.lowercased() {
        case "true", "1": return true
        case "false", "0": return false
        default: return nil
        }
    }
}
