# MovePause for Garmin

MovePause is a Garmin Connect IQ data field for improvised interval-style runs where you want to track moving time, paused time, and pacing against the last completed move or pause without pre-building a workout.

## Status

MovePause is in active early implementation. Core timer-state handling has been validated in the simulator and on an Epix Pro (Gen 2, 47mm), and the current UI and alert behaviour is being iterated in real use.

## Problem It Solves

Garmin handles structured workouts well, but many runners do not pre-program every session. In practice, runs are often improvised:

* hill reps until fatigue dictates otherwise
* fartlek by feel
* standing recoveries between efforts
* stop-start urban running
* trail sessions shaped by terrain rather than a fixed workout file

During those sessions, Garmin's standard running experience does not provide a simple, general-purpose way to see:

* how long the current move has lasted
* how long the current pause has lasted
* how long the previous move lasted
* whether the current move or pause is on track against the previous one

MovePause is intended to make those distinctions glanceable without requiring a pre-built workout.

## v1 Scope

The current v1 plan is intentionally narrow:

* a Data Field app type inside Garmin's standard Run activity
* Garmin timer state as the source of truth for moving versus paused time
* an alternating move/pause model rather than lap-based workout logic
* current moving duration as the main moving-state metric
* current pause duration as the main paused-state metric
* asymmetric layouts where the active move timer sits above the gauge, then demotes to the top grey reference when you pause
* previous moving duration as the reference shown in both moving and paused states
* previous pause duration as the paused-state comparison reference
* a segmented progress gauge that stays visible as a scaffold, compares the current move or pause against the relevant reference, and turns red on overrun
* 30-second pause haptics and previous-period completion alerts
* no settings surface; behaviour is learned from the session itself
* a small initial device list rather than broad watch support on day one

## Non-goals

MovePause is not currently planned to:

* replace Garmin structured workouts
* ship first as a full custom activity app
* infer training quality or workout load
* detect intervals automatically with custom motion logic
* treat laps as the core product model
* show a broad set of run totals in the field UI
* support every Garmin watch from the outset
* add cloud sync or external analytics integrations

## Repo Guide

This repository now contains the early Connect IQ implementation alongside the docs that describe the current direction.

* [Technical design notes](docs/TECHNICAL.md) describe the proposed behaviour, platform approach, and implementation sequence for v1.
* [Roadmap](docs/ROADMAP.md) describes the planned phases, exit criteria, and likely post-v1 directions.
* [Contributing](CONTRIBUTING.md) explains what kinds of feedback and contributions are useful at this stage.

## Contributing Now

Useful contributions right now include:

* device-specific observations about Garmin timer and Auto Pause behaviour
* feedback on scope and UX tradeoffs
* documentation fixes and clarity improvements
* implementation suggestions that keep v1 narrow and testable

If you open an issue, use the repository templates where possible so device model, firmware, and reproduction details are captured consistently.

## License

This project is released under the MIT License. See [LICENSE](LICENSE).
