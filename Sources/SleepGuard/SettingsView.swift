import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            Form {
                scheduleSection
                overlaySection
                actionsSection
            }
            .formStyle(.grouped)
            .padding(20)
        }
        .frame(minWidth: 560, minHeight: 430)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 30, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("SleepGuard")
                    .font(.title2.weight(.semibold))
                Text("Battery-first bedtime schedule with no idle background process.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
    }

    private var scheduleSection: some View {
        Section {
            Toggle("Enable bedtime schedule", isOn: $viewModel.schedule.isEnabled)
                .accessibilityHint("When enabled, launchd starts the overlay at the warning time.")

            DatePicker("Warning starts", selection: warningBinding, displayedComponents: .hourAndMinute)
            DatePicker("Graceful logout target", selection: logoutBinding, displayedComponents: .hourAndMinute)
            DatePicker("In-bed target", selection: inBedBinding, displayedComponents: .hourAndMinute)
            DatePicker("Wake-up target", selection: wakeBinding, displayedComponents: .hourAndMinute)
        } header: {
            Label("Daily rhythm", systemImage: "moon.zzz")
        }
    }

    private var overlaySection: some View {
        Section {
            Toggle("Allow one snooze", isOn: $viewModel.schedule.allowsOneSnooze)
            Stepper(
                "Snooze: \(viewModel.schedule.snoozeMinutes) minutes",
                value: $viewModel.schedule.snoozeMinutes,
                in: 5...20,
                step: 5
            )
            Picker("Final prompt", selection: $viewModel.schedule.finalPromptMinutes) {
                Text("1 min").tag(1)
                Text("2 min").tag(2)
                Text("3 min").tag(3)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Final prompt duration")
        } header: {
            Label("Overlay behavior", systemImage: "rectangle.on.rectangle")
        }
    }

    private var actionsSection: some View {
        Section {
            HStack(spacing: 12) {
                Button {
                    viewModel.saveAndInstall()
                } label: {
                    Label("Save Schedule", systemImage: "checkmark.circle")
                }
                .keyboardShortcut(.defaultAction)

                Button {
                    viewModel.previewOverlay()
                } label: {
                    Label("Preview Overlay", systemImage: "play.rectangle")
                }

                Button(role: .destructive) {
                    viewModel.removeSchedule()
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            }

            StatusRow(isInstalled: viewModel.isInstalled, message: viewModel.statusMessage)
        }
    }

    private var warningBinding: Binding<Date> {
        Binding(get: { viewModel.warningDate }, set: { viewModel.warningDate = $0 })
    }

    private var logoutBinding: Binding<Date> {
        Binding(get: { viewModel.logoutDate }, set: { viewModel.logoutDate = $0 })
    }

    private var inBedBinding: Binding<Date> {
        Binding(get: { viewModel.inBedDate }, set: { viewModel.inBedDate = $0 })
    }

    private var wakeBinding: Binding<Date> {
        Binding(get: { viewModel.wakeDate }, set: { viewModel.wakeDate = $0 })
    }
}

struct StatusRow: View {
    var isInstalled: Bool
    var message: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: isInstalled ? "checkmark.seal.fill" : "powerplug")
                .foregroundStyle(isInstalled ? .green : .secondary)
                .accessibilityHidden(true)
            Text(message.isEmpty ? defaultMessage : message)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var defaultMessage: String {
        isInstalled
            ? "LaunchAgent installed. The overlay starts only at the scheduled warning time."
            : "No LaunchAgent installed. SleepGuard has no idle process."
    }
}
