# Random Picker

A small SwiftUI iPhone app for picking a random winner among numbered participants.

Everyone picks a number in real life. Enter how many people are playing, spin the wheel, and the app announces the winning number.

## Features

- Pick 2–100 participants with − / + buttons or by typing the number
- A colorful wheel with an eased spin that lands on a random number
- Winner card with confetti and a vibration
- **Remove** the winner and keep drawing, for picking 1st, 2nd, 3rd…, with the drawn numbers listed in order and a **Reset** button

## Build

The Xcode project is generated with [Tuist](https://tuist.dev):

```bash
tuist generate
```

Then open `RandomPicker.xcworkspace`, set your own development team under Signing & Capabilities, and run. Requires iOS 17+.
