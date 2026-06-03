# SleepGuard

SleepGuard is a battery-first macOS bedtime utility that helps you wake at 5:45 AM by getting you off the Mac early enough to wind down.

Social-share one-liner: **A native macOS bedtime guard that uses launchd scheduling instead of an idle daemon.**

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
