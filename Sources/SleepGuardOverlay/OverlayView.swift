import SwiftUI

struct OverlayView: View {
    @ObservedObject var controller: OverlayWindowController

    var body: some View {
        Group {
            if controller.isCollapsed {
                collapsed
            } else {
                expanded
            }
        }
        .buttonStyle(.bordered)
        .tint(.accentColor)
    }

    private var expanded: some View {
        HStack(spacing: 16) {
            Image(systemName: controller.isFinalPrompt ? "exclamationmark.circle.fill" : "moon.zzz.fill")
                .font(.system(size: 30, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(controller.isFinalPrompt ? .orange : .blue)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                Text(controller.isFinalPrompt ? "Final save check" : "Time to wrap up")
                    .font(.headline)
                Text(controller.statusText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(controller.remainingText)
                    .font(.system(.title2, design: .rounded).monospacedDigit().weight(.semibold))
                    .accessibilityLabel("Countdown")
                    .accessibilityValue(controller.remainingText)
            }

            Spacer(minLength: 8)
            actions
        }
        .padding(18)
        .frame(width: 520, height: 156)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.separator, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("SleepGuard bedtime overlay")
    }

    private var actions: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Button {
                controller.toggleCollapsed()
            } label: {
                Label("Collapse", systemImage: "chevron.up")
            }
            .accessibilityHint("Collapses SleepGuard into a small countdown pill.")

            Button {
                controller.snooze()
            } label: {
                Label("Snooze", systemImage: "clock.arrow.circlepath")
            }
            .disabled(!controller.snoozeAvailable || controller.isFinalPrompt)
            .accessibilityHint("Adds one short delay to the logout target.")

            Button(role: .destructive) {
                controller.logoutNow()
            } label: {
                Label("Log out now", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .accessibilityHint("Requests the normal macOS logout flow.")
        }
    }

    private var collapsed: some View {
        HStack(spacing: 10) {
            Image(systemName: "moon.zzz.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)
                .accessibilityHidden(true)
            Text(controller.remainingText)
                .font(.system(.body, design: .rounded).monospacedDigit().weight(.semibold))
                .accessibilityLabel("Countdown")
                .accessibilityValue(controller.remainingText)
            Button {
                controller.toggleCollapsed()
            } label: {
                Image(systemName: "chevron.down")
            }
            .help("Expand SleepGuard")
            .accessibilityLabel("Expand SleepGuard")
        }
        .padding(.horizontal, 14)
        .frame(width: 252, height: 56)
        .background(.regularMaterial, in: Capsule())
        .overlay {
            Capsule().stroke(.separator, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("SleepGuard countdown pill")
    }
}
