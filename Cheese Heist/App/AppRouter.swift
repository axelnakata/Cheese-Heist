// AppRouter.swift — Cheese Heist
// PRD §9 — the single owner of the current route.

import Observation

@Observable
final class AppRouter {
    private(set) var route: AppRoute = .splash

    func navigate(to route: AppRoute) {
        self.route = route
    }
}
