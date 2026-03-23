# GreyskullLP
App development for the official Greyskull LP workout program.

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
- **Database**: SQL TBD

## Installation Instructions
1. Clone the repository:
   ```bash
   git clone https://github.com/thedevwhosaysni/GreyskullLP.git
   cd GreyskullLP
2. Set up the Flutter environment:
   ```bash
   flutter pub get
3. Run the application:
   ```bash
   flutter run

## Usage Instructions
- Once the app is running, follow the on-screen prompts to input exercises and track your progress.

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

## Contributing
Contributions are welcome! If you would like to contribute to the project, please follow these steps:
- Fork the repository.
- Create a new branch (git checkout -b feature/YourFeature).
- Make your changes.
- Commit your changes (git commit -m "Add some feature").
- Push to the branch (git push origin feature/YourFeature).
- Open a pull request.

## License
This project is licensed under the GNU GPL License.

## Contact
For inquiries or feedback, please reach out to info@suncoastservers.com.
