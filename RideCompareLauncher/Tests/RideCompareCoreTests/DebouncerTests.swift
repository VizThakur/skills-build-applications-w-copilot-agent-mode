import XCTest
@testable import RideCompareCore

final class DebouncerTests: XCTestCase {
    func testOnlyTheLastCallRuns() async {
        let debouncer = Debouncer(delay: .milliseconds(30))
        let results = ResultsBox()

        await debouncer.run { await results.append(1) }
        await debouncer.run { await results.append(2) }
        await debouncer.run { await results.append(3) }

        // Give the debouncer's delay plus a margin to fire exactly once.
        try? await Task.sleep(for: .milliseconds(100))

        let values = await results.values
        XCTAssertEqual(values, [3], "Only the most recent scheduled call should have run")
    }

    func testCancelPreventsScheduledWorkFromRunning() async {
        let debouncer = Debouncer(delay: .milliseconds(30))
        let results = ResultsBox()

        await debouncer.run { await results.append(1) }
        await debouncer.cancel()

        try? await Task.sleep(for: .milliseconds(100))

        let values = await results.values
        XCTAssertTrue(values.isEmpty)
    }
}

/// A tiny actor to collect results from concurrent closures without a data race.
private actor ResultsBox {
    private(set) var values: [Int] = []

    func append(_ value: Int) {
        values.append(value)
    }
}
