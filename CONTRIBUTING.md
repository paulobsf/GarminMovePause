# Contributing to MovePause

## Project Stage

MovePause `v0.1` has been submitted to Garmin for approval. The Connect IQ project scaffold, core timer-state handling, and current pacing UI are in place, and the current work is focused on validation on the chosen devices plus any follow-up changes that come out of review or real use.

Useful contributions at this stage include:

* device-specific observations about Garmin timer behaviour
* feedback on scope, UX priorities, and behaviour on supported devices
* documentation improvements
* small implementation ideas that help keep v1 narrow and testable

## Reporting Bugs and Device-Specific Behaviour

If you hit a reproducible issue, or you have relevant watch behaviour to report from simulator or hardware testing, open an issue using the bug report template where possible.

When reporting behaviour, focus on concrete reproduction rather than general impressions.

## What to Include

Please include as much of the following as you can:

* watch model
* firmware version
* activity type
* whether Auto Pause was enabled
* any timer, pause, or screen settings that might matter
* clear reproduction steps
* expected behaviour
* actual behaviour
* screenshots, simulator captures, or watch photos if they help

## Proposing Scope or UX Changes

Feature requests are welcome, but they are most useful when they describe:

* the runner use case
* the problem with the current design
* the proposed change
* any alternative approaches considered
* tradeoffs, especially if the idea adds settings or complexity

MovePause is intentionally narrow. Suggestions that preserve clarity and trustworthiness are more likely to fit the project than broad feature expansion.

## Pull Request Expectations

Keep pull requests small and focused.

If you are proposing a larger change, open an issue first so the intended direction can be discussed before implementation work begins.

Try to keep unrelated documentation, scope, and implementation changes in separate pull requests where possible.

## Evolving Implementation Conventions

The first code scaffold is now committed, but implementation conventions may still evolve while the early move/pause model is validated on real hardware.

If you want to contribute code at this stage, prefer discussing the change first so file layout, naming, and tooling assumptions do not drift while the early architecture is still settling.
