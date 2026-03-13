import UIKit
import TraceKMP

/// Swift-idiomatic wrapper around the KMP TraceIOS SDK.
/// All logic lives in TraceIOS.kt — this file is a thin bridge.
public class TraceClient {
    public static let shared = TraceClient()
    private init() {}

    // MARK: - Initialize

    public static func initialize(config: TraceClientConfig) {
        let kmpConfig = config.toKmp()
        Trace.shared.initialize(context: nil, config: kmpConfig)
    }

    // MARK: - Listeners

    public static func setDeepLinkListener(_ listener: @escaping (TraceDeepLink) -> Void) {
        Trace.shared.setDeepLinkListener { kmpDeepLink in
            listener(TraceDeepLink(
                path:       kmpDeepLink.path,
                params:     kmpDeepLink.params as? [String: String] ?? [:],
                isDeferred: kmpDeepLink.isDeferred
            ))
        }
    }

    public static func setAttributionListener(_ listener: @escaping (TraceAttributionResult) -> Void) {
        Trace.shared.setAttributionListener { result in
            listener(TraceAttributionResult(from: result))
        }
    }

    public static func setResetListener(_ listener: @escaping () -> Void) {
        Trace.shared.setResetListener {
            DispatchQueue.main.async { listener() }
        }
    }

    // MARK: - Universal / Custom scheme links

    public static func handleUniversalLink(_ url: URL) -> Bool {
        guard let nsUrl = url as NSURL? else { return false }
        return TraceIOS.shared.handleUniversalLink(url: nsUrl as URL)
    }

    public static func handleCustomScheme(_ url: URL) -> Bool {
        guard let nsUrl = url as NSURL? else { return false }
        return TraceIOS.shared.handleCustomScheme(url: nsUrl as URL)
    }

    // MARK: - Events

    public static func trackEvent(
        name: String,
        properties: [String: String] = [:],
    ) {
        Trace.shared.trackEvent(
            name:       name,
            properties: properties
        )
    }

    // MARK: - SKAdNetwork

    public static func updateConversionValue(_ value: Int) {
        TraceIOS.shared.updateConversionValue(value: Int32(value))
    }

    // MARK: - Privacy / Opt-out

    /// Enable or disable all Trace data collection.
    ///
    /// When disabled, no fingerprint data is collected and no network
    /// requests are made. The preference is persisted across app restarts.
    ///
    /// Use this to respect user privacy preferences — for example, after
    /// the user denies App Tracking Transparency (ATT) or withdraws GDPR consent.
    public static func setEnabled(_ enabled: Bool) {
        Trace.shared.setEnabled(enabled: enabled)
    }

    /// Returns whether Trace data collection is currently enabled.
    public static var isEnabled: Bool {
        Trace.shared.isEnabled
    }

    // MARK: - Reset

    /// Resets the install on both the server and locally.
    /// Use this for demo/testing flows to allow re-attribution.
    public static func resetInstall(onComplete: ((Bool) -> Void)? = nil) {
        Trace.shared.resetInstall { success in
            DispatchQueue.main.async {
                onComplete?(success.boolValue)
            }
        }
    }

    // MARK: - Testing

    public static func resetForTesting() {
        Trace.shared.resetForTesting()
    }
}

// MARK: - Region

/// Data region for API traffic routing and data residency.
public enum TraceRegion: String {
    /// Routes traffic to api.traceclick.io (US data residency, default)
    case us
    /// Routes traffic to api-eu.traceclick.io (EU data residency)
    case eu

    fileprivate func toKmp() -> Region {
        switch self {
        case .us: return .us
        case .eu: return .eu
        }
    }
}

// MARK: - Config

public struct TraceClientConfig {
    public let apiKey: String
    public let hashSalt: String
    public let region: TraceRegion
    public let debug: Bool
    public let enabled: Bool
    public let testMode: Bool
    public let simulatedDeepLink: TraceDeepLink?

    public init(
        apiKey: String,
        hashSalt: String,
        region: TraceRegion = .us,
        debug: Bool = false,
        enabled: Bool = true,
        testMode: Bool = false,
        simulatedDeepLink: TraceDeepLink? = nil
    ) {
        self.apiKey = apiKey
        self.hashSalt = hashSalt
        self.region = region
        self.debug = debug
        self.enabled = enabled
        self.testMode = testMode
        self.simulatedDeepLink = simulatedDeepLink
    }

    public static func test(
        apiKey: String = "test_key",
        simulatedDeepLink: TraceDeepLink? = TraceDeepLink(
            path: "/test/welcome",
            params: ["source": "test_mode"],
            isDeferred: true
        )
    ) -> TraceClientConfig {
        TraceClientConfig(
            apiKey:            apiKey,
            hashSalt:          "test-salt-do-not-use-in-production",
            region:            .us,
            debug:             true,
            testMode:          true,
            simulatedDeepLink: simulatedDeepLink
        )
    }

    fileprivate func toKmp() -> TraceConfig {
        let kmpTestMode: TestModeConfig? = testMode ? TestModeConfig(
            simulatedDeepLink: simulatedDeepLink.map { DeepLink(path: $0.path, params: $0.params, isDeferred: $0.isDeferred) },
            simulatedCampaignId: nil,
            simulatedMethod: "TEST",
            responseDelayMs: 300
        ) : nil
        return TraceConfig(
            apiKey:   apiKey,
            hashSalt: hashSalt,
            region:   region.toKmp(),
            debug:    debug,
            testMode: kmpTestMode,
            enabled:  enabled
        )
    }
}

// MARK: - Attribution result bridge

public struct TraceAttributionResult {
    public let attributed: Bool
    public let method: String?
    public let campaignId: String?
    public let deepLink: TraceDeepLink?

    public init(attributed: Bool, method: String?, campaignId: String?, deepLink: TraceDeepLink?) {
        self.attributed = attributed
        self.method = method
        self.campaignId = campaignId
        self.deepLink = deepLink
    }

    fileprivate init(from result: AttributionResult) {
        if let attributed = result as? AttributionResult.Attributed {
            self.attributed = true
            self.method     = attributed.method
            self.campaignId = attributed.campaignId
            self.deepLink   = attributed.deepLink.map {
                TraceDeepLink(path: $0.path, params: $0.params as? [String: String] ?? [:], isDeferred: $0.isDeferred)
            }
        } else {
            self.attributed = false
            self.method     = nil
            self.campaignId = nil
            self.deepLink   = nil
        }
    }
}
