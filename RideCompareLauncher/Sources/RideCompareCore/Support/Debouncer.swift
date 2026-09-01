import Foundation

/// A tiny Swift Concurrency debouncer used to avoid firing a Places
/// Autocomplete request on every keystroke.
///
/// Each call to `run` cancels any previously scheduled work and schedules
/// `operation` to run after `delay`. If a newer call arrives before the
/// delay elapses, the older one is cancelled and never executes — so only
/// the most recent keystroke ends up making a network request. This is a
/// plain `actor` with no Combine/RunLoop dependency, so it works the same in
/// the app target and in this package's unit tests.
public actor Debouncer {
    private var task: Task<Void, Never>?
    private let delay: Duration

    public init(delay: Duration = .milliseconds(300)) {
        self.delay = delay
    }

    /// Cancels any pending call and schedules `operation` after `delay`.
    /// `operation` is `@Sendable` and runs on a detached task, so callers
    /// that need to touch `@MainActor` state should hop back explicitly
    /// (e.g. wrap the body in `await MainActor.run { ... }`).
    public func run(_ operation: @escaping @Sendable () async -> Void) {
        task?.cancel()
        task = Task {
            do {
                try await Task.sleep(for: delay)
            } catch {
                return // cancelled — a newer keystroke superseded this one
            }
            guard !Task.isCancelled else { return }
            await operation()
        }
    }

    /// Cancels any pending scheduled work without running it.
    public func cancel() {
        task?.cancel()
        task = nil
    }
}
