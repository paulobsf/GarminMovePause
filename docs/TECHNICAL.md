# Technical Design Notes for MovePause

## 1. What This Document Is

This document records the current technical direction for MovePause v1. The repository now contains a validated phase-1 implementation and an initial phase-2 implementation, but the design notes still describe the intended shape of the broader v1 rather than claiming every planned piece is already complete.

## 2. Product Shape and Rationale

The recommended first implementation is a **Garmin Connect IQ data field**.

This is the planned v1 shape because it:

* plugs into Garmin's standard Run activity rather than replacing it
* keeps the user inside the familiar native workout flow
* reduces surface area compared with a full custom activity app
* addresses the core problem without expanding the product too early

A full custom activity app may be worth revisiting later, but it is not the planned starting point.

## 3. Core Behavioural Model

The planned behavioural model is simple: trust Garmin's timer state rather than inventing custom motion detection.

That means:

* when Garmin considers the activity paused, MovePause should count paused time
* when Garmin considers the activity running, MovePause should count moving time

This keeps the semantics aligned with what the runner already sees on the watch and avoids unnecessary inference logic.

## 4. Proposed Runtime State

The initial runtime state should stay small and explicit. A reasonable proposed state model includes:

* whether the activity is currently paused
* the last update timestamp
* the timestamp at which the current pause started
* total moving milliseconds
* total paused milliseconds
* current-segment moving milliseconds
* current-segment paused milliseconds
* current pause duration
* configured target pause duration
* whether the target alert has already fired for the current pause

Derived values should remain derived where possible. The first version should optimise for clarity and debuggability over clever abstractions.

## 5. Time Accumulation Strategy

The planned implementation should not rely only on pause and resume callbacks for duration tracking.

Preferred approach:

* on each compute or update cycle, capture the current timestamp
* calculate the delta from the previous tick
* classify that delta using Garmin's current timer state
* add the delta to either moving or paused totals
* refresh the current pause duration while paused

This approach should be more robust across device differences and callback timing quirks than a callback-only model.

## 6. Segment Model

The planned v1 segment model is intentionally simple and lap-like.

A segment should begin:

* at activity start
* when the user manually creates a new lap

Within the active segment, MovePause should track:

* segment moving time
* segment paused time

This is enough to support improvised reps, hill sessions, and recovery timing without attempting automatic interval detection.

Edge cases that should be verified during implementation:

* lap pressed while already paused
* repeated pause and resume cycles within one segment
* Auto Pause transitions inside a segment

## 7. UX Priorities

### While Moving

The moving state should prioritise work-oriented information:

* current-segment moving time
* current-segment paused time
* total moving time
* total paused time

### While Paused

The paused state should prioritise recovery-oriented information:

* current pause duration in the largest treatment
* optional time remaining to a configured target
* current-segment paused time
* total paused time

### Design Principles

The planned UI should be:

* glanceable during a run
* low in cognitive load
* conservative about how much it tries to display at once
* able to simplify gracefully across screen shapes and sizes

## 8. Platform and API Areas Likely Involved

The exact API details should be confirmed against the Connect IQ SDK version in use when implementation begins. The planned v1 work is likely to touch these areas:

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
5. Test early on a real watch for pause, resume, lap, Auto Pause, and alert behaviour.
6. Add settings only after the core semantics are stable.

Testing should remain practical:

* use the simulator for layout and baseline logic checks
* use real hardware for behaviour that depends on watch semantics and actual running conditions

## 10. Planned Implementation Sequence

The planned implementation order is:

### Phase 1

* create the Data Field scaffold
* implement total moving and total paused accumulation
* verify clean pause and resume transitions

### Phase 2

* add current-segment moving and paused counters
* support lap-based segment resets

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
* validated phase-1 timing logic for total moving and paused accumulation
* initial phase-2 segment moving and paused counters with lap-based resets
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
* whether segment resets should later expand beyond manual laps
* whether very short pauses should count by default
* whether the moving view should emphasise segment totals or run totals
* whether the paused view should show elapsed time only, or elapsed plus remaining time by default
* how much configurability is useful before the field becomes cluttered

## 12. Future Technical Topics

These topics are reasonable to revisit later, once the first version exists and its behaviour is proven:

* optional FIT contribution for exportable post-run metrics
* short-pause filtering thresholds
* multiple display modes
* stronger device-specific layout tuning
* packaging and release automation once there is a real release flow
* a Garmin Store submission checklist once beta scope is fixed
