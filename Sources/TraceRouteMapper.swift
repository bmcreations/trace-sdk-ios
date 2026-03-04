import Foundation
import TraceKMP

/// Type-safe wrapper around the shared Kotlin DeepLinkMapperBuilder.
///
/// PathPattern and DeepLinkParams come directly from the KMP framework —
/// the matching algorithm lives in commonMain and is shared with Android.
/// This class only adds Swift generic type safety at the boundary.
///
/// Usage:
/// ```swift
/// let mapper = TraceRouteMapper<AppRoute> { m in
///     m.link("/product/{id}")  { .product(id: $0.require("id")) }
///     m.link("/checkout")      { .checkout(promo: $0["promo"]) }
///     m.link("/invite/{code}") { .invite(code: $0.require("code")) }
/// }
/// ```
public class TraceRouteMapper<Route: Hashable> {

    public typealias RouteFactory = (TraceDeepLinkParams) -> Route?

    private var entries: [(TracePathPattern, RouteFactory)] = []

    public init(_ build: (TraceRouteMapper<Route>) -> Void) {
        build(self)
    }

    /// Register a URI template and its typed route factory.
    /// Mirrors the Kotlin `link("/product/{id}") { ... }` DSL exactly.
    public func link(_ pattern: String, factory: @escaping RouteFactory) {
        entries.append((TracePathPattern(template: pattern), factory))
    }

    /// Called by the view modifier — matches the deep link and returns a typed route.
    public func map(_ deepLink: TraceDeepLink) -> Route? {
        for (pattern, factory) in entries {
            guard let match = pattern.match(path: deepLink.path) else { continue }
            var merged = match
            deepLink.params.forEach { merged[$0.key] = $0.value }
            let params = TraceDeepLinkParams(raw: merged)
            if let route = factory(params) { return route }
        }
        return nil
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
