import Foundation
import Testing
@testable import TypeCountCore

@Suite("Daily stats store", .serialized)
@MainActor
struct DailyStatsStoreTests {
    @Test func oddChineseHalfUnitIsPreservedAndDisplayedRoundedDown() {
        let context = makeContext()
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let date = makeDate(2026, 8, 14, 10)
        let store = makeStore(context: context, now: { date })

        store.record(halfUnits: 1)
        #expect(store.todayHalfUnits == 1)
        #expect(store.todayCount == 0)

        store.record(halfUnits: 1)
        #expect(store.todayHalfUnits == 2)
        #expect(store.todayCount == 1)
    }

    @Test func flushAndReloadPreserveRecordsAndRemainder() {
        let context = makeContext()
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let date = makeDate(2026, 8, 14, 10)
        let first = makeStore(context: context, now: { date })
        first.record(halfUnits: 3)
        first.flush()

        let second = makeStore(context: context, now: { date })
        #expect(second.todayHalfUnits == 3)
        #expect(second.todayCount == 1)
    }

    @Test func midnightCreatesSeparateDayTotals() {
        let context = makeContext()
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        var now = makeDate(2026, 8, 14, 23)
        let store = makeStore(context: context, now: { now })
        store.record(halfUnits: 2)

        now = makeDate(2026, 8, 15, 1)
        store.record(halfUnits: 4)

        let days = store.recentDays(count: 2, endingAt: now)
        #expect(days.map(\.count) == [1, 2])
        #expect(days.map(\.key) == ["2026-08-14", "2026-08-15"])
    }

    @Test func recentDaysFillGapsAndRemainSorted() {
        let context = makeContext()
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let start = makeDate(2026, 8, 8, 10)
        let end = makeDate(2026, 8, 14, 10)
        let store = makeStore(context: context, now: { start })
        store.record(halfUnits: 2, at: start)
        store.record(halfUnits: 6, at: end)

        let days = store.recentDays(count: 7, endingAt: end)
        #expect(days.count == 7)
        #expect(days.map(\.count) == [1, 0, 0, 0, 0, 0, 3])
        #expect(days.first?.key == "2026-08-08")
        #expect(days.last?.key == "2026-08-14")
    }

    @Test func pausedStoreDoesNotRecord() {
        let context = makeContext()
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let date = makeDate(2026, 8, 14, 10)
        let store = makeStore(context: context, now: { date })
        store.setPaused(true)
        store.record(halfUnits: 2)
        #expect(store.todayCount == 0)

        store.setPaused(false)
        store.record(halfUnits: 2)
        #expect(store.todayCount == 1)
    }

    private func makeContext() -> (defaults: UserDefaults, suiteName: String) {
        let suiteName = "TypeCountTests.\(UUID().uuidString)"
        return (UserDefaults(suiteName: suiteName)!, suiteName)
    }

    private func makeStore(
        context: (defaults: UserDefaults, suiteName: String),
        now: @escaping () -> Date
    ) -> DailyStatsStore {
        DailyStatsStore(
            defaults: context.defaults,
            storageKey: "test.history",
            calendar: calendar,
            now: now,
            debounceInterval: 60
        )
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar
    }

    private func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
}
