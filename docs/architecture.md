# Architecture

SleepGuard is split into a visible settings app, a scheduled overlay helper, and shared core code.

## Targets

`SleepGuardCore` owns the schedule model, JSON persistence, and LaunchAgent installation. The schedule is stored in `~/Library/Application Support/SleepGuard/schedule.json`.

`SleepGuard` is the visible native settings app. It loads the schedule, lets the user adjust bedtime targets, writes the LaunchAgent, and exits when the settings window closes.

`SleepGuardOverlay` is an accessory helper with no Dock icon. launchd starts it at the configured warning time using `StartCalendarInterval`.

## Source Layout

```text
Sources/
  SleepGuardCore/
    SleepSchedule.swift
    ScheduleStore.swift
    LaunchAgentManager.swift
  SleepGuard/
    main.swift
    SettingsWindowController.swift
    SettingsViewModel.swift
    OverlayExecutableResolver.swift
    SettingsView.swift
  SleepGuardOverlay/
    main.swift
    OverlayOptions.swift
    OverlayWindowController.swift
    OverlayPanel.swift
    OverlayView.swift
```

The core target owns domain state and system integration. The settings app owns user preferences and LaunchAgent installation. The overlay owns runtime countdown UI only.

## LaunchAgent Flow

The settings app writes `~/Library/LaunchAgents/com.faka.sleepguard.overlay.plist` with absolute paths. `Sources/SleepGuardCore/Resources/LaunchAgents/com.faka.sleepguard.overlay.plist` is a readable template for documentation and tests; the runtime plist is generated from the current app location.

- `ProgramArguments` pointing at the bundled overlay helper.
- `StartCalendarInterval` set to the warning time.
- no `KeepAlive`.

After writing the plist, the app reloads it with `launchctl bootstrap` for the current user GUI domain.

## Overlay Flow

The overlay appears as a floating, non-blocking panel. It shows countdown state, a one-time snooze, a collapse control, and a manual logout action. At the graceful logout target, it expands into a final save check. If ignored, it requests the normal macOS logout flow with System Events.

## Battery Behavior

SleepGuard does not keep an idle daemon alive. When the settings app is closed and the overlay is not active, there should be no SleepGuard process running.
