import AppKit
import SwiftUI

struct OverlayView: View {
    @ObservedObject var controller: OverlayWindowController

    var body: some View {
        ZStack {
            morphingBackground
            expanded
                .opacity(controller.isCollapsed ? 0 : 1)
                .scaleEffect(controller.isCollapsed ? 0.86 : 1, anchor: .trailing)
                .accessibilityHidden(controller.isCollapsed)
            collapsed
                .opacity(controller.isCollapsed ? 1 : 0)
                .scaleEffect(controller.isCollapsed ? 1 : 1.12, anchor: .trailing)
                .accessibilityHidden(!controller.isCollapsed)
        }
        .frame(
            width: controller.isCollapsed ? 164 : 520,
            height: controller.isCollapsed ? 52 : 156
        )
        .buttonStyle(.bordered)
        .tint(.accentColor)
        .animation(.smooth(duration: 0.24), value: controller.isCollapsed)
        .onExitCommand {
            controller.closePreview()
        }
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

            if controller.previewMode {
                Button {
                    controller.closePreview()
                } label: {
                    Label("Close", systemImage: "xmark.circle")
                }
                .keyboardShortcut(.cancelAction)
                .accessibilityHint("Closes the preview overlay.")
            }

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
        .frame(width: 164, height: 52)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("SleepGuard countdown pill")
    }

    private var morphingBackground: some View {
        RoundedRectangle(
            cornerRadius: controller.isCollapsed ? 26 : 14,
            style: .continuous
        )
            .fill(.regularMaterial)
            .overlay {
                RoundedRectangle(
                    cornerRadius: controller.isCollapsed ? 26 : 14,
                    style: .continuous
                )
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.72))
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: controller.isCollapsed ? 26 : 14,
                    style: .continuous
                )
                .stroke(.separator, lineWidth: 1)
            }
    }
}
