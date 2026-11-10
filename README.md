# GreyskullLP
App development for the official Greyskull LP workout program.

**Organization:** [suncoast-servers](https://github.com/suncoast-servers) Â· **Project lead / merge authority:** [@TheDevWhoSaysNi](https://github.com/TheDevWhoSaysNi)

## Description
GreyskullLP is a fitness app designed to help users track their workout routines and progress. The app offers customizable exercises and allows users to monitor their improvements over time. This project has been sanctioned by Johnny Pain, the author of the official workout plan, and I am working on this with his permission.

## Features
- User-friendly interface for inputting workouts.
- Progress tracking with graphs and charts.
- Customizable exercises based on user preferences.
- Option to track additional metrics (e.g., sets, reps, weights).

## Technologies Used
- **Front End**: Dart (Flutter)
- **Back End**: Dart (Flutter)
- **Local Storage**: SharedPreferences (JSON, on-device)

## Installation Instructions
1. Clone the repository:
   ```bash
   git clone https://github.com/suncoast-servers/GreyskullLP.git
   cd GreyskullLP
   ```
2. Set up the Flutter environment:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## Usage Instructions
- Once the app is running, follow the on-screen prompts to input exercises and track your progress.

## Data Storage Transparency
- User data is stored locally on-device in SharedPreferences as JSON.
- Data currently stored: workout settings, daily targets, forum/store URLs, sign-in flag, diet totals, and activity history.
- No cloud sync is enabled yet.
- Planned migration path: SQLite (`sqflite`/`drift`) once multi-table querying, backups, and analytics become larger in scope.
- Backup support: export/share backup JSON and restore from backup JSON in Settings.

## Integration Notes
- Forum page is prepped for WordPress flow with configurable forum URL/login URL from settings.
- Store page currently supports direct embedded storefront loading and can point to [GREYSKULLNATION STORE](https://store.greyskullnation.com/).
- Diet search uses free sources: Open Food Facts first, with optional USDA fallback key.
- TODO: sync food/workout results to forum posts for accountability updates.

## Quick Emulator Verification
Use this checklist before adding new features so the scaffold stays healthy.

1. Confirm Flutter tooling:
   ```bash
   flutter doctor -v
   flutter devices
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run static checks:
   ```bash
   flutter analyze
   flutter test
   ```
4. Run on Android emulator/device:
   ```bash
   flutter run -d android
   ```
5. Run on iOS simulator (macOS + Xcode only):
   ```bash
   flutter run -d ios
   ```

### iOS Readiness Notes
- Open `ios/Runner.xcworkspace` in Xcode for signing setup.
- Set your Team and Bundle Identifier in the Runner target.
- Verify deployment target and run once directly from Xcode if Flutter CLI fails.

## Contributing (contractors & collaborators)

This repo uses **pull requests into `main`**. Direct pushes to `main` are blocked.

1. Read [docs/COLLABORATOR.md](docs/COLLABORATOR.md) and org [CONTRIBUTING.md](https://github.com/suncoast-servers/.github/blob/main/CONTRIBUTING.md).
2. Branch: `feat/<issue>-short-description` or `fix/...`.
3. Open a PR; wait for review from **@TheDevWhoSaysNi** before merge.

Using AI coding tools? See [AGENTS.md](AGENTS.md).

## License
This project is licensed under the GNU GPL License.

## Contact
For inquiries or feedback, please reach out to info@suncoastservers.com.
