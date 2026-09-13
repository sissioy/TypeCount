# TypeCount

TypeCount is a small macOS 13+ menu bar utility that estimates how many characters you type each day.

It shows only a keyboard icon in the menu bar. Hover over the icon for today's total, or click it for a seven-day view, pause control, and permission status.

## Counting rules

- English input sources: letters, numbers, punctuation, and spaces count as one character.
- Chinese input sources: every two letter keys count as one estimated character; numbers, punctuation, and spaces count as one.
- Command and Control shortcuts, Return, Delete, Tab, navigation keys, and function keys are ignored.
- Paste, dictation, autocomplete, and deletions do not affect the total.

TypeCount never stores characters, key sequences, application names, or text field contents. It has no networking or telemetry.

## Build and install

```sh
swift test
./scripts/build-app.sh
cp -R dist/TypeCount.app /Applications/
open /Applications/TypeCount.app
```

Grant Input Monitoring when macOS asks. Permission is tied to the installed app location, so install the app before granting access.

If TypeCount still says `Needs access` after its switch is enabled, the permission belongs to an older build. In System Settings > Privacy & Security > Input Monitoring, select the old TypeCount entry and remove it with the minus button. Add `/Applications/TypeCount.app` again, enable it, and reopen TypeCount.

The build is ad-hoc signed for local use with a stable designated requirement so later local rebuilds keep the same Input Monitoring identity. Add TypeCount to Open at Login in System Settings if desired.

## Implementation references

The project is an independent implementation informed by the event monitoring, persistence, and menu bar patterns in the MIT-licensed [KeyStats](https://github.com/debugtheworldbot/keyStats) and [Activity Bar](https://github.com/SuveenE/activity-bar) projects.
