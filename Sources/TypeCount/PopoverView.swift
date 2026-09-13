import AppKit
import SwiftUI
import TypeCountCore

struct PopoverView: View {
    @ObservedObject var model: AppModel
    @ObservedObject private var store: DailyStatsStore

    init(model: AppModel) {
        self.model = model
        self.store = model.store
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            todaySummary
            weekChart

            if !model.permissionGranted {
                permissionCard
            }

            controls

            footer
        }
        .padding(18)
        .frame(width: 310)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 9) {
            Image(systemName: "keyboard")
                .font(.system(size: 16, weight: .medium))
                .frame(width: 26, height: 26)
                .background(Color.accentColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 7))
                .accessibilityHidden(true)

            Text("TypeCount")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                Text(statusText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var todaySummary: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("TODAY")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(.secondary)

            Text(store.todayCount.formatted(.number.grouping(.automatic)))
                .font(.system(size: 38, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy, value: store.todayCount)

            Text("estimated characters")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today, \(store.todayCount) estimated characters")
    }

    private var weekChart: some View {
        let days = store.recentDays()
        let maximum = max(days.map(\.count).max() ?? 0, 1)

        return VStack(alignment: .leading, spacing: 10) {
            Text("LAST 7 DAYS")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(days) { day in
                    let summary = "\(day.key): \(day.count.formatted(.number.grouping(.automatic))) estimated characters"

                    VStack(spacing: 5) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(barColor(for: day))
                            .frame(height: barHeight(value: day.count, maximum: maximum))
                        Text(weekday(for: day.date))
                            .font(.system(size: 9, weight: isToday(day.date) ? .semibold : .regular))
                            .foregroundStyle(isToday(day.date) ? Color.primary : Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(summary)
                    .help(summary)
                }
            }
            .frame(height: 82)
        }
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("Input Monitoring is not active", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.orange)
            Text("TypeCount only reads key codes and never stores what you type.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Already enabled? Remove the old TypeCount entry, add /Applications/TypeCount.app again, then turn it on.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Open Settings") {
                    model.requestPermission()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("Retry") {
                    model.retryMonitoring()
                }
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private var controls: some View {
        HStack {
            Label("Tracking", systemImage: "waveform.path.ecg")
                .font(.system(size: 12))
            Spacer()
            Toggle(
                "Tracking",
                isOn: Binding(
                    get: { !store.isPaused },
                    set: { model.setTrackingEnabled($0) }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
    }

    private var footer: some View {
        HStack {
            Text("Counts only keyboard input")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Spacer()
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .keyboardShortcut("q")
        }
    }

    private var statusText: String {
        if store.isPaused { return "Paused" }
        if !model.permissionGranted { return "Needs access" }
        return model.monitoringActive ? "Counting" : "Starting"
    }

    private var statusColor: Color {
        if store.isPaused { return .secondary }
        if !model.permissionGranted { return .orange }
        return model.monitoringActive ? .green : .secondary
    }

    private func barColor(for day: DayStat) -> Color {
        isToday(day.date) ? .accentColor : Color.accentColor.opacity(0.38)
    }

    private func barHeight(value: Int, maximum: Int) -> CGFloat {
        value == 0 ? 3 : max(6, 54 * CGFloat(value) / CGFloat(maximum))
    }

    private func weekday(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("EEEEE")
        return formatter.string(from: date)
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.autoupdatingCurrent.isDateInToday(date)
    }
}
