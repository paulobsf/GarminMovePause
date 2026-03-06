# Roadmap

This roadmap translates the current MovePause direction into a practical delivery plan.

It is intentionally narrow. The aim is to solve one clear problem well before expanding scope.

This roadmap is directional rather than fixed. It may change as simulator and device testing reveal platform constraints, device-specific behaviour, or better ways to keep v1 focused.

The initial repository foundation is already in place. Phase 1 has now been validated in the simulator and on an Epix Pro (Gen 2, 47mm). The repository also contains an initial phase-2 lap-tracking implementation, so the active work has moved on to validating lap behaviour and then improving the UI.

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
* total moving time accumulated correctly
* total paused time accumulated correctly
* pause and resume transitions handled safely
* lightweight debug logging added

### Notes

This phase should not try to solve UI polish, configuration, or broad device support.

### Exit Criteria

* totals behave correctly in the simulator
* totals behave correctly on at least one real watch
* no obvious drift or double-counting across repeated pause and resume cycles

## Phase 2: Lap Tracking

### Objective

Support rep-like usage by tracking moving and paused time within the current lap.

### Deliverables

* lap moving time
* lap paused time
* lap reset model defined
* manual-lap reset implemented cleanly
* repeated pause and resume within a lap handled correctly

### Notes

The first lap model should stay simple: activity start and manual laps.

### Exit Criteria

* runners can use the field for improvised intervals or hill reps without confusion
* lap totals remain trustworthy across several laps in one run

## Phase 3: Usable UI

### Objective

Make the field genuinely useful at a glance during a real run.

### Deliverables

* running-state layout
* paused-state layout
* hierarchy for key metrics
* initial support for a small device subset
* typography and spacing refined for quick readability

### Notes

Prioritise the paused state. That is where the runner most needs help.

### Exit Criteria

* while paused, the runner can instantly see how long recovery has lasted
* while moving, the runner can understand current lap and total breakdowns without effort
* layouts remain legible on the chosen launch devices

## Phase 4: Recovery Targets

### Objective

Support practical standing recoveries without requiring a phone.

### Deliverables

* configurable default target duration
* optional remaining-time display while paused
* optional vibration when target is reached
* no repeated buzzing during a single pause

### Notes

Keep configuration modest. A few sensible defaults are better than a large settings surface.

### Exit Criteria

* a runner can manage a 60, 90, or 120 second recovery from the watch alone
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

* MovePause solves ad hoc pause-versus-move timing for a defined set of runners and devices
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

Manual pause, Auto Pause, lap events, and timer state may behave differently across device families.

### UI Overload

Trying to show too much at once may reduce usefulness.

### Scope Creep

The idea is powerful precisely because it is focused.

## Success Measures

A strong early outcome would look like this:

* runners can use the field in unstructured sessions without reaching for a phone
* current recovery duration is obvious while paused
* moving and paused totals feel trustworthy
* lap tracking is good enough for improvised reps
* early testers describe the field as simple and useful rather than clever and fiddly

## Suggested Issue Buckets

To keep the roadmap actionable, issues can be grouped under:

* timing engine
* lap tracking
* UI and layout
* recovery targets
* device compatibility
* documentation
* beta feedback

## Suggested Release Rhythm

A sensible cadence would be:

* core scaffold and timing engine
* lap tracking
* maintainer prototype
* maintainer field testing
* small beta
* v1

That keeps the project grounded in real usage rather than abstract completeness.
