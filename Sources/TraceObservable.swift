import SwiftUI
import Combine

// MARK: - Models exposed to SwiftUI

public struct TraceDeepLink: Equatable {
    public let path: String
    public let params: [String: String]
    public let isDeferred: Bool

    public init(path: String, params: [String: String] = [:], isDeferred: Bool) {
        self.path = path
        self.params = params
        self.isDeferred = isDeferred
    }
}

public struct TraceAttribution: Equatable {
    public let attributed: Bool
    public let method: String
    public let campaignId: String?
    public let deepLink: TraceDeepLink?

    public init(attributed: Bool, method: String, campaignId: String?, deepLink: TraceDeepLink?) {
        self.attributed = attributed
        self.method = method
        self.campaignId = campaignId
        self.deepLink = deepLink
    }
}

// MARK: - Observable state

public class TraceObservable: ObservableObject {
    @Published public var deepLink: TraceDeepLink?         = nil
    @Published public var attribution: TraceAttribution?   = nil
    @Published public var pendingDeferredDeepLink: TraceDeepLink? = nil

    public static let shared = TraceObservable()
    private init() {}

    // Caches deep link that arrives before the listener is wired
    // Mirrors Android Trace.kt pendingDeepLink fix
    private var cachedDeepLink: TraceDeepLink? = nil

    public func onDeepLink(_ link: TraceDeepLink) {
        DispatchQueue.main.async {
            // Always flow through deepLink so the .onDeepLink() modifier's
            // .onChange(of: trace.deepLink) fires for ALL links — including
            // deferred ones. The modifier decides whether to navigate
            // immediately or park for post-auth drain.
            self.deepLink = link
        }
    }

    // Called by TraceProvider once listener is registered —
    // replays any deep link that arrived before the view was ready
    internal func drainCachedDeepLink() {
        guard let link = cachedDeepLink else { return }
        cachedDeepLink = nil
        onDeepLink(link)
    }

    internal func cacheDeepLink(_ link: TraceDeepLink) {
        cachedDeepLink = link
    }

    internal func onAttribution(_ result: TraceAttribution) {
        DispatchQueue.main.async { self.attribution = result }
    }

    public func consumeDeepLink() {
        deepLink = nil
    }

    // Park-and-replay — mirrors Android TraceState
    public func parkDeferred(_ link: TraceDeepLink) {
        DispatchQueue.main.async {
            self.pendingDeferredDeepLink = link
            self.deepLink = nil
        }
    }

    public func consumePendingDeferredDeepLink() -> TraceDeepLink? {
        let link = pendingDeferredDeepLink
        pendingDeferredDeepLink = nil
        return link
    }

    public func hasPendingDeferredDeepLink() -> Bool {
        pendingDeferredDeepLink != nil
    }
}
