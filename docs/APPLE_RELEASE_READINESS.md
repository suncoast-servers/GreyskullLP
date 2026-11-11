# Apple App Store & TestFlight Release Readiness

> **Issue reference:** Closes [#12](https://github.com/suncoast-servers/GreyskullLP/issues/12)  
> **App:** Greyskull LP (Official Johnny Pain program)  
> **Publisher:** Suncoast Servers ([@suncoast-servers](https://github.com/suncoast-servers))  
> **Account Owner / Signer:** Ryan ([@TheDevWhoSaysNi](https://github.com/TheDevWhoSaysNi))  
> **Delivery Lead:** Umer ([@umerwaqas92](https://github.com/umerwaqas92))

---

## 1. Bundle Identifier & Team Signing Configuration

### Current State vs Production ID (repo snapshot)

| Platform | ID in this repo today | Notes |
|----------|------------------------|--------|
| **iOS** | `com.example.greyskullLp` | Flutter/Xcode default in `ios/Runner.xcodeproj/project.pbxproj` — change before App Store. |
| **Android** | `com.app.greyskull` | `applicationId` in `android/app/build.gradle` (Play package name). |

**Before first store upload:** Ryan picks one production bundle/package ID (e.g. `com.suncoastservers.greyskull`) and aligns **both** platforms in a dedicated issue/PR. Per project rules, production ID changes require Ryan’s written approval (Upwork + linked issue).

### Xcode Team Configuration (Ryan Action)
1. Open `ios/Runner.xcworkspace` in Xcode on macOS.
2. Select the top-level **Runner** project in the Project Navigator.
3. Under **Targets**, select **Runner**.
4. Click the **Signing & Capabilities** tab.
5. In the **Team** dropdown, select **Suncoast Servers** (or your personal paid Apple Developer team).
6. Ensure **Automatically manage signing** is checked.
7. Ensure **Bundle Identifier** matches the App ID registered in your Apple Developer account.
8. Under the **RunnerTests** target, ensure the same Team is selected.

> **Security Rule:** No certificates, provisioning profiles (`*.mobileprovision`), `.p12`, or App Store Connect API keys (`AuthKey_*.p8`) are ever committed to git. They are ignored in `.gitignore`.

---

## 2. Release Build & Archive Workflow

### Prerequisites on macOS
- Xcode 15+ installed with iOS SDK.
- Flutter SDK configured (`flutter doctor -v` showing all green).
- CocoaPods installed (`pod --version`).

### Build Steps

1. **Fetch dependencies and clean build cache**:
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   ```

2. **Run verification gates**:
   ```bash
   dart format .
   flutter analyze --fatal-infos
   flutter test
   ```

3. **Build the release archive (`.xcarchive`)**:
   ```bash
   flutter build ipa --release
   ```
   *Output location:* `build/ios/archive/Runner.xcarchive` and `build/ios/ipa/GreyskullLP.ipa`.

4. **Alternative GUI Build via Xcode**:
   - Open `ios/Runner.xcworkspace` in Xcode.
   - Select the target **Any iOS Device (arm64)** from the device destination menu.
   - Select menu: **Product > Archive**.
   - When the build finishes, Xcode automatically opens the **Organizer** window.

---

## 3. TestFlight Upload Checklist for Ryan

Once the archive is built:

1. **Apple Developer Portal Setup**:
   - [ ] Navigate to [developer.apple.com](https://developer.apple.com/account/) > **Certificates, Identifiers & Profiles**.
   - [ ] Under **Identifiers**, create an **App ID** matching your production bundle identifier (e.g., `com.suncoastservers.greyskull`).

2. **App Store Connect App Creation**:
   - [ ] Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com/) > **Apps**.
   - [ ] Click **+ (New App)**.
   - [ ] Platform: **iOS**.
   - [ ] Name: **Greyskull LP**.
   - [ ] Primary Language: **English (US)**.
   - [ ] Bundle ID: Select the App ID created above.
   - [ ] SKU: `SUNCOAST-GSLP-001` (or custom internal ID).
   - [ ] User Access: **Full Access**.

3. **Upload to TestFlight**:
   - **Method A (Xcode Organizer - Recommended)**:
     1. In Xcode Organizer, select the latest archive.
     2. Click **Distribute App** > **App Store Connect** > **Upload**.
     3. Keep standard options enabled (Strip Swift symbols, Upload symbols).
     4. Select your distribution certificate and signing profile.
     5. Click **Upload**.
   - **Method B (Transporter App)**:
     1. Download **Transporter** from the Mac App Store.
     2. Drag and drop `build/ios/ipa/GreyskullLP.ipa` into Transporter.
     3. Click **Deliver**.

4. **Internal Testing Setup**:
   - [ ] In App Store Connect, go to **TestFlight** tab.
   - [ ] Under **Internal Testing**, click **+** and add yourself and contractor.
   - [ ] Once processing completes (usually 5–15 minutes), click the build and submit for internal testing (no App Review required for internal testers).

---

## 4. App Privacy Nutrition Labels Draft

Apple requires disclosing all data collected in the App Store privacy questionnaire.

| Category | Status | Details |
| :--- | :--- | :--- |
| **Data Collection** | **Data Not Collected** | Greyskull LP operates on a **local-first** architecture. All workout logs, history, weights, and diet logs are stored strictly on-device in local storage (`SharedPreferences`). |
| **Third-Party Tracking** | **No Tracking** | The app contains no third-party advertising SDKs, tracking pixels, or third-party analytics (no Google Analytics, Firebase, Facebook SDK). |
| **User Accounts** | **Optional / External** | The app requires no login or personal account to function. Forum links open the external community website. |
| **External Integrations** | **User-Initiated** | • **USDA Food Data API**: Optional; Trainees provide their own API key. Queries food names/macros only; no user PII is transmitted.<br>• **Store & Forum**: Open official external URLs in in-app browser or browser sheet; no cookies or session data collected by Suncoast Servers. |

**App Store Connect Questionnaire Selection:**
- *Do you or your third-party partners collect data from this app?* **No**.

---

## 5. App Store Listing Draft & Asset Guidelines

### Store Metadata
- **App Name**: `Greyskull LP — Workout Tracker` (max 30 characters)
- **Subtitle**: `Official Johnny Pain Program` (max 30 characters)
- **Category**: Health & Fitness
- **Age Rating**: 4+
- **Support URL**: `https://suncoastservers.com/support` (or `https://github.com/suncoast-servers/GreyskullLP/issues`)
- **Privacy Policy URL**: `https://suncoastservers.com/privacy/greyskull`

### Description Draft
```text
Greyskull LP is the official, sanctioned companion app for Johnny Pain’s world-renowned Greyskull Linear Progression program (3rd Edition).

Designed with a rugged, distraction-free aesthetic, Greyskull LP provides everything you need to build strength, muscle, and conditioning without paywalls, subscriptions, or invasive ads.

KEY FEATURES:
• Barbell Linear Progression: Base program and rotating workouts featuring Johnny Pain's signature 5+ AMRAP final set.
• All 3 Official Calisthenics Methods:
  - Frequency Method ("greasing the groove"): High-frequency sub-maximal sets throughout the day.
  - Ladder Method: Partner-paced density waves (up to the gold standard 5x5 benchmark).
  - Total Work Method: Daily and weekly volume accumulation across push-ups, chins, sit-ups, and burpees.
• Full Session History & Editing: Track volume, review past workouts, and adjust method metadata anytime.
• Local-First Privacy: 100% of your data stays on your device. No mandatory accounts, no cloud lock-in, and zero tracking.
• Macro & Nutrition Tracking: Integrated protein and calorie counter with optional USDA nutrition lookups.

Open-source and free, powered by Suncoast Servers.
```

### Keywords (max 100 characters)
`greyskull,strength,powerlifting,barbell,calisthenics,pushups,chinups,workout tracker,5x5,linear`

### Screenshot Asset Specifications
| Display | Target Device | Pixel Resolution |
| :--- | :--- | :--- |
| **6.9" / 6.7" Display** (Required) | iPhone 16 Pro Max / 15 Pro Max | 1320 x 2868 or 1290 x 2796 |
| **6.5" Display** (Required) | iPhone 11 Pro Max / XS Max | 1242 x 2688 |
| **5.5" Display** (Optional) | iPhone 8 Plus | 1242 x 2208 |
| **13" iPad** (If iPad supported) | iPad Pro 13-inch | 2064 x 2752 |
