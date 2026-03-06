# Technical Design Notes for MovePause

## 1. What This Document Is

This document records the current technical direction for MovePause v1. The repository already contains an early working implementation, but these notes describe the intended product and engineering shape rather than claiming every detail is finished or validated.

## 2. Product Shape and Rationale

The recommended v1 implementation is a **Garmin Connect IQ data field**.

This is the right starting shape because it:

* plugs into Garmin's standard Run activity rather than replacing it
* keeps the user inside the familiar native workout flow
* reduces surface area compared with a full custom activity app
* addresses the core problem without expanding the product too early

A full custom activity app may be worth revisiting later, but it is not the planned starting point.

## 3. Core Behavioural Model

The behavioural model should stay simple: trust Garmin's timer state rather than inventing custom motion detection.

That means:

* when Garmin considers the activity paused, MovePause should count paused time
* when Garmin considers the activity running, MovePause should count moving time
* the displayed model should be alternating move/pause periods, not laps or workout steps

This keeps the semantics aligned with what the runner already sees on the watch and avoids unnecessary inference logic.

## 4. Proposed Runtime State

The initial runtime state should stay small and explicit. A reasonable state model includes:

* whether the activity has started
* whether the activity is currently paused
* the last update timestamp
* current moving-period duration
* current pause-period duration
* previous moving-period duration
* configured target pause duration
* whether the target alert has already fired for the current pause

Derived values should remain derived where possible. The first version should optimise for clarity and debuggability over clever abstractions.

## 5. Time Accumulation Strategy

The implementation should not rely only on pause and resume callbacks for duration tracking.

Preferred approach:

* on each compute or update cycle, capture the current timestamp
* calculate the delta from the previous tick
* classify that delta using Garmin's current timer state
* add the delta to either the active move period or the active pause period
* refresh the current pause duration while paused

This approach should be more robust across device differences and callback timing quirks than a callback-only model.

## 6. Period Model

MovePause should model the run as alternating periods:

* a moving period while Garmin's timer is running
* a pause period while Garmin's timer is paused or stopped

On a move-to-pause transition:

* the completed move duration becomes the new `previous moving` reference
* the active move duration resets
* the active pause duration starts from zero

On a pause-to-move transition:

* the active pause duration resets
* the new move duration starts from zero

Lap events may still exist in the host activity, but they are not part of the external product model and should not drive the displayed semantics.

## 7. UX Priorities

### While Moving

The moving state should prioritise work-oriented information:

* current moving duration in the largest treatment
* previous moving duration as the secondary metric
* a progress bar that compares the current move against the previous move

The first move of the session has no previous reference, so no comparison bar should be shown.

### While Paused

The paused state should prioritise recovery-oriented information:

* current pause duration in the largest treatment
* optional time remaining to a configured target
* previous moving duration as the secondary metric
* a progress bar that depletes as the pause target is consumed, then turns full and red once the pause overruns

### Design Principles

The planned UI should be:

* glanceable during a run
* low in cognitive load
* conservative about how much it tries to display at once
* compatible with tighter multi-field layouts
* able to simplify gracefully across screen shapes and sizes without mode-specific hardcoding

## 8. Platform and API Areas Likely Involved

The planned v1 work is likely to touch these areas:

* `WatchUi.DataField`
* `Activity.Info`
* periodic updates via `compute(info)`
* activity timer state inspection
* pause and resume related callbacks where they are available and reliable
* `Attention` vibration support
* application properties or settings

Possible later work, but not a v1 requirement:

* `FitContributor` for exportable post-run metrics

## 9. Tooling and Development Workflow

The planned local stack is:

* Garmin Connect IQ SDK Manager
* the current Connect IQ SDK plus selected device packs
* Visual Studio Code
* the Garmin Monkey C extension for VS Code
* a developer signing key

The planned workflow is:

1. Generate a Data Field project scaffold.
2. Limit the first implementation to a small watch subset.
3. Build the timing engine before polishing UI details.
4. Use the simulator for arithmetic checks, state transitions, and layout iteration.
5. Test early on a real watch for pause, resume, Auto Pause, and alert behaviour.
6. Add settings only after the core semantics are stable.

Testing should remain practical:

* use the simulator for layout and baseline logic checks
* use real hardware for behaviour that depends on watch semantics and actual running conditions

## 10. Planned Implementation Sequence

The planned implementation order is:

### Phase 1

* create the Data Field scaffold
* implement timer-state-based move and pause accumulation
* verify clean pause and resume transitions

### Phase 2

* treat the workout as alternating move and pause periods
* capture the previous moving duration at each move-to-pause transition

### Phase 3

* implement a usable moving view and paused view
* support the initial target devices

### Phase 4

* add configurable recovery targets
* add an optional vibration alert when the target is reached

### Phase 5

* run maintainer field testing
* fix edge cases and UI problems
* prepare for a small beta

### Current Repo Today

The repository currently contains:

* a Connect IQ Data Field scaffold for `epix2pro47mm`
* validated early timer-state handling on simulator and watch
* a move/pause period model with previous-move reference tracking
* current moving, paused, and ready layouts under active iteration
* recovery target settings, remaining-time/overtime behaviour, and one-shot vibration alerts
* resources, manifest, and jungle files for the app project
* public documentation describing the project and its direction
* contribution guidance and issue templates

### Expected Expansion During Later Phases

The project will likely expand from the initial scaffold into something broadly like this:

```text
MovePause/
  manifest.xml
  resources/
    strings/
    layouts/
    drawables/
    properties.xml
  src/
    MovePauseField.mc
    helpers/
```

That structure is planned, not current.

## 11. Open Design Questions

These questions remain open and should be resolved through a mix of implementation, simulator work, and real device testing:

* which Garmin devices should be supported first
* whether very short pauses should count by default
* whether the moving view should always compare against the previous move, or allow a simpler mode
* whether the paused view should show elapsed time only, or elapsed plus remaining time by default when a target exists
* how much configurability is useful before the field becomes cluttered

## 12. Future Technical Topics

These topics are reasonable to revisit later, once the first version exists and its behaviour is proven:

* optional FIT contribution for exportable post-run metrics
* short-pause filtering thresholds
* multiple display modes
* stronger device-specific layout tuning
* packaging and release automation once there is a real release flow
* a Garmin Store submission checklist once beta scope is fixed
