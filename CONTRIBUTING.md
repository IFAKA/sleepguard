# Contributing

Thanks for improving SleepGuard. Keep contributions aligned with the project goal: a native, battery-first macOS bedtime utility with no idle background process.

## Development

```sh
swift build
swift test
swift run SleepGuard
```

Use `make package` to create `dist/SleepGuard.app`.

## Design Principles

- Prefer native AppKit and SwiftUI controls.
- Use semantic system colors and materials.
- Keep all controls keyboard accessible.
- Add VoiceOver labels where visible text is not enough.
- Do not add Electron, polling loops, persistent menu bar processes, or `KeepAlive`.

## Pull Requests

Open focused PRs with a short description, screenshots for UI changes, and the verification steps you ran.
