import SwiftUI

extension View {
    public func onDeepLink<Route: Hashable>(
        path: Binding<[Route]>,
        mapper: TraceRouteMapper<Route>,
        authGate: @escaping () -> Bool = { true }
    ) -> some View {
        modifier(TraceDeepLinkHandlerModifier(
            path: path,
            mapper: mapper,
            authGate: authGate
        ))
    }
}

private struct TraceDeepLinkHandlerModifier<Route: Hashable>: ViewModifier {

    @Binding var path: [Route]
    let mapper: TraceRouteMapper<Route>
    let authGate: () -> Bool
    @EnvironmentObject var trace: TraceObservable

    func body(content: Content) -> some View {
        // Evaluate authGate() each render so SwiftUI can detect transitions
        let isAuth = authGate()

        content
        .onOpenURL { url in
            let deepLink = TraceDeepLink(
                path: url.path,
                params: parseQuery(url.query ?? ""),
                isDeferred: false
            )
            trace.onDeepLink(deepLink)
        }
        .onChange(of: trace.deepLink) { deepLink in
            guard let deepLink else { return }

            guard let result = mapper.mapResult(deepLink) else {
                trace.consumeDeepLink()
                return
            }

            switch result {
            case .action(let execute):
                execute()
                trace.consumeDeepLink()
            case .navigate(let route):
                if deepLink.isDeferred && !authGate() {
                    // Auth not ready — park until post-auth handler drains it
                    trace.parkDeferred(deepLink)
                    return
                }

                if deepLink.isDeferred {
                    // Replace stack — user must not back-navigate to blank launch screen
                    self.path = [route]
                } else {
                    if self.path.last != route { self.path.append(route) }
                }
                trace.consumeDeepLink()
            }
        }
        // Post-auth drain: when authGate() transitions to true (parent
        // re-renders because auth state changed), navigate to any
        // parked deferred deep link.
        .onChange(of: isAuth) { authenticated in
            guard authenticated else { return }
            guard let pending = trace.consumePendingDeferredDeepLink() else { return }
            guard let result = mapper.mapResult(pending) else { return }
            switch result {
            case .navigate(let route):
                self.path = [route]
            case .action(let execute):
                execute()
            }
        }
    }

    private func parseQuery(_ query: String) -> [String: String] {
        guard !query.isEmpty else { return [:] }
        return Dictionary(
            uniqueKeysWithValues: query
                .components(separatedBy: "&")
                .compactMap { pair -> (String, String)? in
                    let kv = pair.components(separatedBy: "=")
                    guard kv.count == 2 else { return nil }
                    return (kv[0], kv[1])
                }
        )
    }
}
