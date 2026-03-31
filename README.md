# Codex Menu Bar App

Native macOS menu bar app that shows today's Codex USD usage and refreshes every minute.

## Requirements

- macOS 13 or newer
- `ccusage-codex` installed and available on `PATH`

## Run

```bash
swift run CodexMenuBarApp
```

## Build A Double-Clickable App

```bash
./scripts/build-app.sh
```

The generated app bundle will be:

```bash
dist/Codex Usage.app
```

You can then double-click `dist/Codex Usage.app` in Finder.

Because the menu bar title is `Codex $...`, it should be easier to spot among other menu bar items.

## Verify CLI dependency

```bash
ccusage-codex daily --since 2026-03-31 --until 2026-03-31 --json
```

If the app shows `Codex --`, open the menu to see the last error returned by the CLI.
