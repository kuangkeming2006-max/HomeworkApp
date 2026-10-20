import HomeworkDomain

/// The only composition root. Platform services will be injected here in later phases.
@MainActor
final class AppContainer {
    let version = "0.1.0"
}
