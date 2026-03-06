# MovePause for Garmin

MovePause is a planned Garmin Connect IQ data field for showing moving time, paused time, and recovery timing during normal runs.

## Status

MovePause has completed its initial public foundation pass. The repository now contains the project narrative, technical direction, roadmap, and contributor scaffolding, but implementation has not started yet.

## Problem It Solves

Garmin handles structured workouts well, but many runners do not pre-program every session. In practice, runs are often improvised:

* hill reps until fatigue dictates otherwise
* fartlek by feel
* standing recoveries between efforts
* stop-start urban running
* trail sessions shaped by terrain rather than a fixed workout file

During those sessions, Garmin's standard running experience does not provide a simple, general-purpose way to see:

* how long the current pause has lasted
* how much paused time has accumulated in the current segment
* how much paused time has accumulated across the full run
* how much of the current segment has actually been spent moving

MovePause is intended to make those distinctions glanceable without requiring a pre-built workout.

## v1 Scope

The current v1 plan is intentionally narrow:

* a Data Field app type inside Garmin's standard Run activity
* Garmin timer state as the source of truth for moving versus paused time
* run-level moving and paused totals
* current-segment moving and paused totals
* a pause-focused view that makes recovery timing obvious while stopped
* an optional recovery target with a vibration alert
* a small initial device list rather than broad watch support on day one

## Non-goals

MovePause is not currently planned to:

* replace Garmin structured workouts
* ship first as a full custom activity app
* infer training quality or workout load
* detect intervals automatically with custom motion logic
* support every Garmin watch from the outset
* add cloud sync or external analytics integrations

## Repo Guide

This repository is currently a public build journal for the project.

* [Technical design notes](docs/TECHNICAL.md) describe the proposed behaviour, platform approach, and implementation sequence for v1.
* [Roadmap](docs/ROADMAP.md) describes the planned phases, exit criteria, and likely post-v1 directions.
* [Contributing](CONTRIBUTING.md) explains what kinds of feedback and contributions are useful at this stage.

## Contributing Now

Useful contributions right now include:

* device-specific observations about Garmin timer, Auto Pause, and lap behaviour
* feedback on scope and UX tradeoffs
* documentation fixes and clarity improvements
* implementation suggestions that keep v1 narrow and testable

If you open an issue, use the repository templates where possible so device model, firmware, and reproduction details are captured consistently.

## License

This project is released under the MIT License. See [LICENSE](LICENSE).
