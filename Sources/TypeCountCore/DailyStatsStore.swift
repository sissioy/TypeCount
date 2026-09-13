import Combine
import Foundation

public struct DayStat: Identifiable, Equatable {
    public let key: String
    public let date: Date
    public let halfUnits: Int

    public var id: String { key }
    public var count: Int { halfUnits / 2 }

    public init(key: String, date: Date, halfUnits: Int) {
        self.key = key
        self.date = date
        self.halfUnits = halfUnits
    }
}

@MainActor
public final class DailyStatsStore: ObservableObject {
    @Published public private(set) var records: [String: Int]
    @Published public private(set) var isPaused: Bool

    public let storageKey: String

    private let defaults: UserDefaults
    private var calendar: Calendar
    private let now: () -> Date
    private let debounceInterval: TimeInterval
    private var currentDayKey: String
    private var saveWorkItem: DispatchWorkItem?

    private struct Payload: Codable {
        let version: Int
        let halfUnitsByDay: [String: Int]
    }

    public init(
        defaults: UserDefaults = .standard,
        storageKey: String = "TypeCount.history.v1",
        calendar: Calendar = .autoupdatingCurrent,
        now: @escaping () -> Date = Date.init,
        debounceInterval: TimeInterval = 1
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.calendar = calendar
        self.now = now
        self.debounceInterval = debounceInterval
        self.currentDayKey = Self.dayKey(for: now(), calendar: calendar)
        self.isPaused = defaults.object(forKey: storageKey + ".paused") as? Bool ?? false

        if let data = defaults.data(forKey: storageKey),
           let payload = try? JSONDecoder().decode(Payload.self, from: data),
           payload.version == 1 {
            self.records = payload.halfUnitsByDay.filter { $0.value >= 0 }
        } else {
            self.records = [:]
        }
    }

    public var todayHalfUnits: Int {
        records[Self.dayKey(for: now(), calendar: calendar), default: 0]
    }

    public var todayCount: Int {
        todayHalfUnits / 2
    }

    public func record(halfUnits: Int, at date: Date? = nil) {
        guard halfUnits > 0, MonitoringPolicy.shouldRecord(isPaused: isPaused) else { return }
        let eventDate = date ?? now()
        rolloverIfNeeded(at: eventDate)
        let key = Self.dayKey(for: eventDate, calendar: calendar)
        records[key, default: 0] += halfUnits
        scheduleSave()
    }

    public func setPaused(_ paused: Bool) {
        guard isPaused != paused else { return }
        isPaused = paused
        defaults.set(paused, forKey: storageKey + ".paused")
        flush()
    }

    public func rolloverIfNeeded(at date: Date? = nil) {
        let newKey = Self.dayKey(for: date ?? now(), calendar: calendar)
        guard currentDayKey != newKey else { return }
        flush()
        currentDayKey = newKey
        objectWillChange.send()
    }

    public func recentDays(count: Int = 7, endingAt date: Date? = nil) -> [DayStat] {
        guard count > 0 else { return [] }
        let end = calendar.startOfDay(for: date ?? now())
        return (0..<count).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: end) ?? end
            let key = Self.dayKey(for: day, calendar: calendar)
            return DayStat(key: key, date: day, halfUnits: records[key, default: 0])
        }
    }

    public func flush() {
        saveWorkItem?.cancel()
        saveWorkItem = nil
        let payload = Payload(version: 1, halfUnitsByDay: records)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        defaults.set(data, forKey: storageKey)
    }

    public static func dayKey(for date: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    private func scheduleSave() {
        saveWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.flush()
        }
        saveWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: item)
    }
}
