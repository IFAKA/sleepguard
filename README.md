# SleepGuard

SleepGuard is a native Swift macOS bedtime reminder and sleep schedule app that helps you wake at 5:45 AM by getting you off the Mac early enough to wind down.

**A battery-first macOS sleep schedule app that uses launchd instead of an always-on daemon.**

SleepGuard is built for people who want a simple, local-first Mac bedtime utility without Electron, analytics, a menu bar process, or a polling loop.

## Highlights

- Native macOS app written in Swift, SwiftUI, and AppKit.
- Per-user `launchd` scheduling with `StartCalendarInterval`.
- Zero idle SleepGuard process when the app and overlay are closed.
- Calm non-blocking countdown overlay with one snooze.
- Graceful logout request that lets macOS show normal unsaved-work prompts.
- Light Mode, Dark Mode, keyboard navigation, and VoiceOver-friendly labels.

## Keywords

`macos bedtime app`, `macos sleep schedule`, `macos sleep reminder`, `launchd app`, `native swift macos`, `battery friendly mac app`, `logout reminder`, `bedtime reminder`, `swiftui macos app`, `no background daemon`

## What It Does

- Starts a calm warning overlay at 8:45 PM.
- Targets graceful logout at 9:15 PM.
- Keeps the 9:45 PM in-bed goal visible.
- Keeps the 5:45 AM wake-up goal explicit.
- Uses a per-user LaunchAgent with `StartCalendarInterval`.
- Runs no permanent menu bar app, polling loop, Electron shell, or `KeepAlive` process.

## Why It Exists

Most focus apps trade battery life for constant presence. SleepGuard takes the opposite approach: macOS already has a scheduler, so the app writes a LaunchAgent and exits. The helper is launched only when it is time to wrap up.

## User Experience

The overlay is intentionally non-blocking. You can keep typing, clicking, switching apps, and saving work. It can collapse into a small countdown pill, but it cannot fully disappear while active. SleepGuard allows one short snooze and then shows a final save check before requesting the normal macOS logout flow.

The logout request is graceful: macOS and your apps can still show normal unsaved-work prompts.

## Build

```sh
swift build -c release
make package
```

The packaged app is written to `dist/SleepGuard.app`.

## Install Locally

```sh
make package
cp -R dist/SleepGuard.app /Applications/
open /Applications/SleepGuard.app
```

Click **Save Schedule** in the app to install the per-user LaunchAgent. Closing SleepGuard after that is expected; launchd starts the overlay at the warning time.

## Run From Source

```sh
swift run SleepGuard
```

Preview the overlay without allowing it to log out:

```sh
swift run SleepGuardOverlay -- --preview --no-logout
```

## Architecture

SleepGuard has three Swift targets:

- `SleepGuardCore`: shared schedule model, persistence, and LaunchAgent management.
- `SleepGuard`: visible native settings app.
- `SleepGuardOverlay`: hidden helper launched only at warning time.

The app follows a small clean architecture:

- domain and infrastructure in `SleepGuardCore`
- settings presentation in `Sources/SleepGuard`
- scheduled overlay presentation in `Sources/SleepGuardOverlay`
- no business logic hidden in generated project files

See [docs/architecture.md](docs/architecture.md).

## Safety Model

SleepGuard is a self-discipline tool, not parental control or device management software. It does not try to trap the user, block input, bypass macOS prompts, or hide from system tools.

## Defaults

| Event | Time |
| --- | --- |
| Warning starts | 8:45 PM |
| Graceful logout target | 9:15 PM |
| In-bed target | 9:45 PM |
| Wake-up target | 5:45 AM |

## License

MIT
