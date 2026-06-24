# Display Off Utility

Windows utility to instantly turn off all monitors (internal + external).

## What It Does

- **Turns off all displays** immediately when triggered
- **Wake displays** by moving the mouse or pressing any key
- No console window flash or visible PowerShell window

## How to Run

Double-click `display-off.cmd` to turn off all monitors.

## Hotkey Setup

To bind this to a global hotkey:

1. **Create a Desktop shortcut**:
   - Right-click `display-off.cmd` → Send to → Desktop (create shortcut)

2. **Assign a hotkey**:
   - Right-click the Desktop shortcut → Properties
   - Click in the "Shortcut key" field
   - Press your desired key combination (e.g., `Ctrl+Alt+0`)
   - Click OK

### Hotkey Notes

- **Works**: `Ctrl+Alt+<key>`, `Ctrl+Shift+<key>`, `Alt+Shift+<key>`
- **Reserved by Windows**: `Win+<key>` combinations cannot be assigned via shortcut properties
- **Recommended**: `Ctrl+Alt+0` for quick access

## Files

- `display-off.ps1` — PowerShell script that sends the monitor-off command
- `display-off.cmd` — Wrapper that launches the script hidden
