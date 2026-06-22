# Task 10: Media review fix

## Summary

- Changed `MediaController.active()` to snapshot each available source's `nowPlaying()` exactly once per call, then select the first playing snapshot or the first track snapshot in source order.
- Updated `MediaModule` refresh state to retain the current active `MediaSource` so transport buttons can reuse it instead of re-probing all sources on every action.
- Added Media tests covering single-probe snapshotting, source-order tie-breaking for playing and paused tracks, and `NowPlaying.progress` clamping below `0` and above `1`.

## Verification

- `swift run MacNotchTests`
  - Pass: `151 checks, 0 failure(s)`

## Notes

- Left the AppleScript delimiter brittleness unchanged, per the review scope.
