# Roadmap

This roadmap translates the current MovePause direction into a practical delivery plan.

It is intentionally narrow. The aim is to solve one clear problem well before expanding scope.

This roadmap is directional rather than fixed. It may change as simulator and device testing reveal platform constraints, device-specific behaviour, or better ways to keep v1 focused.

The initial repository foundation is already in place. Core timer-state handling has been validated in the simulator and on an Epix Pro (Gen 2, 47mm). The active work now is validating the period-based UI, self-learned pacing cues, and alert behaviour in real use.

## Guiding Principles

* start with the smallest useful version
* optimise for clarity and trustworthiness over feature count
* prefer Garmin-native semantics over clever inference
* support a small set of devices first
* use real-world running sessions to validate behaviour early

## Phase 1: Core Timing Engine

### Objective

Build the minimum logic needed to distinguish moving and paused time reliably.

### Deliverables

* Data Field scaffold created
* moving and paused state tracked from Garmin timer state
* duration accumulation behaves correctly across move and pause periods
* pause and resume transitions handled safely
* lightweight debug logging added

### Notes

This phase should not try to solve UI polish or broad device support.

### Exit Criteria

* core durations behave correctly in the simulator
* core durations behave correctly on at least one real watch
* no obvious drift or double-counting across repeated pause and resume cycles

## Phase 2: Period Model

### Objective

Support rep-like usage by modelling the run as alternating move and pause periods.

### Deliverables

* current move duration
* current pause duration
* previous move duration captured on every move-to-pause transition
* lap events explicitly ignored in the displayed model
* repeated pause and resume cycles handled correctly

### Notes

The displayed semantics should stay simple: the field answers "how long has this move lasted?", "how long has this pause lasted?", and "how long was the last move?"

### Exit Criteria

* runners can use the field for improvised intervals or hill reps without confusion
* previous-move references remain trustworthy across repeated move/pause cycles

## Phase 3: Usable UI

### Objective

Make the field genuinely useful at a glance during a real run.

### Deliverables

* running-state layout
* paused-state layout
* ready-state layout
* hierarchy for key metrics
* initial support for a small device subset
* typography and spacing refined for quick readability

### Notes

Prioritise the paused state. That is where the runner most needs help.

### Exit Criteria

* while paused, the runner can instantly see how long recovery has lasted
* while moving, the runner can compare the current move against the previous move without effort
* layouts remain legible on the chosen launch devices

## Phase 4: Self-Learned Pacing

### Objective

Support practical standing recoveries without requiring a pre-set target.

### Deliverables

* previous pause duration captured for paused-state comparison
* paused-state bar fills against the previous pause once available
* vibration every 30 seconds while paused
* beep/vibrate when move or pause reference reaches 100%
* no settings screen

### Notes

Prefer behaviour learned from the session over configuration.

### Exit Criteria

* a runner can manage improvised recoveries from the watch alone
* alerts feel reliable rather than noisy

## Phase 5: Field Testing

### Objective

Prove the app in actual running sessions.

### Deliverables

* maintainer field-testing notes from real runs
* bug list from manual pause sessions
* bug list from Auto Pause sessions
* fixes for timing, UI, and edge cases
* clearer view of supported versus unsupported device behaviour

### Notes

This phase matters more than adding new features.

### Exit Criteria

* the field feels trustworthy during repeated real use
* the main edge cases are understood and documented
* launch scope is evidence-based rather than aspirational

## Phase 6: Beta Release

### Objective

Get the app into the hands of early testers.

### Deliverables

* installation instructions
* screenshots
* known limitations
* supported-device list
* beta release notes
* feedback template for testers

### Notes

A narrow, honest beta is better than broad support claimed too early.

### Exit Criteria

* external testers can install and use the app
* feedback arrives in a structured way
* launch blockers are distinguishable from nice-to-have ideas

## Phase 7: v1 Release

### Objective

Ship a stable first release that clearly solves the core problem.

### Deliverables

* first stable public release
* polished store or distribution metadata
* release notes
* issue triage process
* short post-v1 roadmap

### Exit Criteria

* MovePause solves ad hoc move-versus-pause timing for a defined set of runners and devices
* the project has a stable baseline for future improvements

## Post-v1 Directions

These are plausible next steps, but they are not committed scope for the first release.

### Priority Candidates

* short-pause filtering threshold
* additional display modes
* broader device support
* optional custom FIT fields for post-run analysis
* stronger device-specific layout tuning

### Lower-Priority or Speculative Ideas

* automatic interval detection
* richer training analytics
* companion tooling outside Garmin
* a fuller custom activity experience

## What We Are Deliberately Not Doing Yet

To protect the project from scope creep, the following are explicitly out of scope for the early roadmap:

* replacing structured workouts
* building a general workout engine
* inventing custom movement detection
* supporting every Garmin watch from the outset
* adding cloud sync or external analytics platforms

## Risks to Watch

### Device Fragmentation

Different watches may vary in layout constraints and behaviour.

### Activity Semantics

Manual pause, Auto Pause, and timer state may behave differently across device families.

### UI Overload

Trying to show too much at once may reduce usefulness.

### Scope Creep

The idea is powerful precisely because it is focused.

## Success Measures

A strong early outcome would look like this:

* runners can use the field in unstructured sessions without reaching for a phone
* current recovery duration is obvious while paused
* move and pause periods feel trustworthy
* previous-move comparison is useful for improvised reps
* early testers describe the field as simple and useful rather than clever and fiddly

## Suggested Issue Buckets

To keep the roadmap actionable, issues can be grouped under:

* timing engine
* move/pause periods
* UI and layout
* pacing and alerts
* device compatibility
* documentation
* beta feedback

## Suggested Release Rhythm

A sensible cadence would be:

* core scaffold and timing engine
* period model
* maintainer prototype
* maintainer field testing
* small beta
* v1

That keeps the project grounded in real usage rather than abstract completeness.
