# Flutter Forge 2026 — Neon Festival Animated Starting Frame

## Included
- LBRCE campus background with subtle blur
- Exact event/inauguration text used in the current Flutter Forge starting frame
- Animated neon gradient color-shifting text throughout the starting frame
- Flutter Forge 2026 branding
- 4-HOUR FLUTTER HACKATHON wording
- START HACKATHON button
- Cinematic 3 → 2 → 1 opening sequence
- Opening celebration/confetti
- Persistent 04:00:00 countdown using `shared_preferences`
- Countdown resumes after refresh, browser close/reopen, internet loss, or computer restart
- Live timer uses normal smooth number transition, not flip cards
- Netlify configuration

## Run
```powershell
flutter pub get
flutter run -d chrome
```

## Build
```powershell
flutter build web --release
```

Netlify publish directory: `build/web`.


## Reference-theme update
- Reworked the composition to match the supplied Flutter Forge 2026 reference screens.
- Uses the supplied `assets/background_campus.png` and `assets/college_logo.png`.
- Keeps the full **LAKIREDDY BALI REDDY COLLEGE OF ENGINEERING** name visible.
- Removes the in-app scroll view and scales the fixed composition to the available viewport.
- Web CSS also disables page/body scrolling, so no browser scrollbar is shown.
- The supplied campus image is retained as the background and receives a dark blue/purple cinematic + animated neon treatment.
