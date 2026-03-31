# Codex Menu Bar App Design

**Goal**

Build a native macOS menu bar app in SwiftUI that shows today's Codex USD cost in the menu bar and refreshes automatically every minute.

**User-facing behavior**

- The menu bar title shows today's cost in a compact format such as `Today $12.34`.
- When data is loading, the title shows `Codex --`.
- Clicking the menu bar item opens a panel with:
  - today's USD cost
  - today's input tokens
  - today's output tokens
  - the last 7 days of daily costs
  - last refresh time
  - a manual refresh button
- The app refreshes once at launch and then every 60 seconds.
- If `ccusage-codex` is missing or returns invalid data, the menu stays alive and the panel shows the error.

**Architecture**

The app will shell out to the installed `ccusage-codex` CLI instead of reading Codex raw data files directly. This keeps the app aligned with the existing reporting logic and avoids coupling to Codex internal log formats.

The implementation is split into three layers:

- a command service that runs `ccusage-codex ... --json`
- a parser and model layer that normalizes the JSON output into app-specific structs
- a SwiftUI view model and menu bar UI that renders state and handles periodic refresh

**Error handling**

- If the CLI command cannot be launched, show an actionable error message.
- If the command exits non-zero, surface stderr in a shortened form.
- If JSON parsing fails, show a parse error and keep the last successful data if available.

**Testing**

Core logic will be covered with unit tests:

- parse a successful daily report into a day summary
- parse a 7-day report into chart rows
- format the menu bar title from loaded state
- surface service errors without crashing

UI behavior will be kept thin so most logic stays testable without UI automation.
