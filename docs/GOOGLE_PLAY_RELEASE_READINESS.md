# Google Play Release Readiness & Play Console Setup

> **Issue reference:** Closes [#13](https://github.com/suncoast-servers/GreyskullLP/issues/13)  
> **App:** Greyskull LP (Official Johnny Pain program)  
> **Publisher:** Suncoast Servers ([@suncoast-servers](https://github.com/suncoast-servers))  
> **Account Owner / Signer:** Ryan ([@TheDevWhoSaysNi](https://github.com/TheDevWhoSaysNi))  
> **Delivery Lead:** Umer ([@umerwaqas92](https://github.com/umerwaqas92))

---

## 1. Ryan Action List: Google Play Developer Account Setup

Ryan needs to register the publisher account on Google Play Console (one-time $25 fee).

### Registration Steps
1. **Navigate to Google Play Console**:
   - Go to [play.google.com/console/signup](https://play.google.com/console/signup).
   - Sign in with your designated Suncoast Servers Google account (or primary admin account).
2. **Choose Account Type**:
   - Select **Organization** (recommended for Suncoast Servers) or **Personal**.
   - For Organization accounts, Google requires a D-U-N-S number, official address, and business verification documents. If speed is preferred, a Personal account can be upgraded later.
3. **Pay Registration Fee**:
   - Pay the one-time $25 registration fee.
4. **Complete Identity Verification**:
   - Complete Google's developer identity verification (government ID upload + contact phone/email).
5. **Create the Application in Play Console**:
   - Click **Create app**.
   - **App name**: `Greyskull LP`
   - **Default language**: English (United States) - `en-US`
   - **App or game**: App
   - **Free or paid**: Free
   - Accept declarations (Developer Program Policies, US export laws).
   - Click **Create app**.

---

## 1b. Package name in this repo

- **Current `applicationId`:** `com.app.greyskull` (`android/app/build.gradle`).
- Play Console app creation must use this package name unless Ryan opens an issue to change it before the first upload.
- Align with iOS bundle ID strategy in [`APPLE_RELEASE_READINESS.md`](APPLE_RELEASE_READINESS.md) before v1 store release.

---

## 2. Release Signing Pattern (Local-First Keystore)

> **Security Rule:** The upload keystore and passwords must NEVER be committed to git. Both `key.properties` and `*.jks`/`*.keystore` are strictly ignored in `.gitignore`.

### Step 1: Generate the Upload Keystore (One-time, by Ryan)
Run the following command on your local machine (macOS / Linux):
```bash
keytool -genkey -v \
  -keystore ~/suncoast-greyskull-upload.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```
*Note: Securely back up `suncoast-greyskull-upload.jks` and passwords into a password manager (e.g., 1Password, Bitwarden). If this key is lost, Google Play App Signing key reset requires Google Support.*

### Step 2: Configure `android/key.properties` (Local Only)
Create `android/key.properties` (modeled after `android/key.properties.example`):
```properties
storePassword=YOUR_SECURE_STORE_PASSWORD
keyPassword=YOUR_SECURE_KEY_PASSWORD
keyAlias=upload
storeFile=/absolute/path/to/suncoast-greyskull-upload.jks
```

### Step 3: Build the Android App Bundle (`.aab`)
With `android/key.properties` in place:
```bash
# Clean and verify
flutter clean
flutter pub get
dart format .
flutter analyze --fatal-infos
flutter test

# Build production app bundle
flutter build appbundle --release
```
*Output location:* `build/app/outputs/bundle/release/app-release.aab`.

*(Note: If `android/key.properties` is omitted on a development machine, `android/app/build.gradle` safely falls back to debug signing so developer builds never break).*

---

## 3. Google Play Data Safety Form Draft

Google Play requires completing the **Data Safety** questionnaire in the Play Console under **Policy > App content**.

| Question | Answer | Rationale |
| :--- | :--- | :--- |
| **Does your app collect or share any of the required user data types?** | **No** | All workout sessions, weight progression, and diet tallies are stored 100% locally on-device using local storage (`SharedPreferences`). No server sync or telemetry exists. |
| **Is all user data collected by your app encrypted in transit?** | **Yes** (N/A) | Any network calls (USDA API queries or external forum browsing) use secure HTTPS. |
| **Do you provide a way for users to request that their data be deleted?** | **Yes** | Users can delete individual history entries, clear tallies, or clear all app storage directly from their device settings or in-app reset. |

---

## 4. Google Play Policy Items for Health & Fitness Apps

Google Play enforces strict guidelines for apps in the Health & Fitness category:

1. **Non-Medical Device Declaration**:
   - The app must clearly declare that it is a strength training utility and **not a medical device or healthcare provider**.
   - Recommended in-app / store disclaimer:
     > *"Greyskull LP is an athletic conditioning and workout tracking tool. Consult a qualified physician before undertaking any rigorous barbell or calisthenics training program. This app does not provide medical advice, diagnosis, or treatment."*
2. **Health Content & Services Declaration**:
   - In Google Play Console under **App content > Health apps declaration**:
   - Declare: *"My app is not a medical app, does not access health records, and does not provide clinical or telehealth services."*
   - Select: **Fitness & Sports Tracking**.
3. **Target Audience & Families Policy**:
   - Target age: **18 and older** (or 13+ if open to teens, with no child-directed content).
   - Declare: App does not target children under 13.
4. **Third-Party Advertising Policy**:
   - Declare: *"Does your app contain ads?"* -> **No**.

---

## 5. Google Play Store Listing Draft & Graphical Assets

### Text Metadata
- **App title**: `Greyskull LP — Workout Tracker` (max 30 chars)
- **Short description**: `Official Johnny Pain Greyskull LP strength and calisthenics workout companion.` (max 80 chars)
- **Full description**: (Same comprehensive copy as in `docs/APPLE_RELEASE_READINESS.md`).

### Required Graphic Assets
| Asset Type | Dimension / Specs | Requirements |
| :--- | :--- | :--- |
| **App Icon** | 512 x 512 px (PNG 32-bit) | Max 1 MB, no alpha transparency |
| **Feature Graphic** | 1024 x 500 px (JPEG or 24-bit PNG) | Banner displayed on top of the Play Store listing |
| **Phone Screenshots** | Min 2, max 8 (16:9 or 18:9) | Minimum 1080 x 1920 px (or 1080 x 2400 px) |
| **7-inch Tablet Screenshots** | Optional but recommended | Min 320 px, max 3840 px |
| **10-inch Tablet Screenshots** | Optional but recommended | Min 1080 px |

---

## 6. Internal Testing Track Upload Workflow

1. In Google Play Console, open **Greyskull LP**.
2. In the left navigation, go to **Release > Testing > Internal testing**.
3. Click **Create new release**.
4. Upload `build/app/outputs/bundle/release/app-release.aab`.
5. Enter **Release name**: `1.0.0 (1)`.
6. Enter **Release notes**:
   ```text
   Initial internal test build for Greyskull LP v1:
   - Official barbell linear progression tracker with 5+ AMRAP sets
   - Calisthenics: Frequency, Ladder, and Total Work methods
   - Local-first session history and method metadata editing
   ```
7. Click **Save** > **Review release** > **Start rollout to Internal testing**.
8. Under the **Testers** tab, create an email list with Ryan and contractor to test on physical Android hardware.
