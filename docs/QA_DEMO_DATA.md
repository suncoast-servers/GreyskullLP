# QA Demo Data

Debug-only fixtures so **Stats** and **History** can be reviewed at real-world
scale without waiting months for real logs.

## Product policy (owner)

**Scenario A** (newbie) and **Scenario B** (cutting) must **stay in the app for
all future builds** so Ryan can **switch between the two trainees** and compare
Stats/History side by side over time. Do not remove `DemoSeedService`, the
Settings picker, or either fixture without explicit owner approval. Store
releases may hide the picker; owner QA builds must keep both scenarios
(debug/profile, or release with `--dart-define=ENABLE_DEMO_DATA=true`).

> These fixtures never ship enabled in store builds. The entry point is hidden
> unless the app is built in debug/profile (`kDebugMode`) or compiled with
> `--dart-define=ENABLE_DEMO_DATA=true`.

## Retention policy (issue #89)

Owner decision: **Scenario A and Scenario B stay available in every owner QA
build** so Stats and History can be compared side by side. `DemoSeedService`,
the `scenarios` list and the Settings picker must not be removed without
explicit owner approval.

| Build | Demo import visible? |
|---|---|
| `flutter build apk --debug` / `flutter run` | Yes (`kDebugMode`) |
| Owner/QA release build | Yes with `--dart-define=ENABLE_DEMO_DATA=true` |
| Store build (no flag) | No |

Example owner build:

```bash
flutter build apk --release --dart-define=ENABLE_DEMO_DATA=true
```

## Scenario A — 90-day newbie (OG → Villain → Gladiator)

Issue: [#55](https://github.com/suncoast-servers/GreyskullLP/issues/55)

| Days | Program level | Barbell template | Calisthenics method |
|------|---------------|------------------|---------------------|
| 1–30 | Foundation | OG Base | Frequency |
| 31–60 | Villain | Villain | Ladder (chin-up ladders) |
| 61–90 | Gladiator | Gladiator | Total Work (push-ups) |

- Barbell sessions on Mon/Wed/Fri with A/B(/C) rotation and linear overload
  (+2.5 lb upper, +5 lb lower), AMRAP final sets, accessories from the book
  templates.
- Calisthenics logged six days a week, diet logs four days a week.
- Numbers ramp across the block so trend lines and volume badges have something
  to show (~167 history entries).

## How to load it

### On a device / emulator (recommended)

1. Install a debug build:
   ```bash
   flutter run -d <device-id>
   ```
2. Open **Settings** (gear icon, top right).
3. Scroll to **QA / Demo Data**.
4. Tap **Scenario A — 90-day newbie (OG → Villain → Gladiator)**.
5. Confirm **Import demo data** (this replaces current app data — export a
   backup first if you have real logs).

Then open **Stats** and **History** to review charts, PRs, and method
transitions.

### From a backup file

```bash
# not exposed yet; use the in-app entry above
```

The payload is a normal `schemaVersion: 2` backup, so
**Settings → Backups → Restore from Pasted Backup** accepts it too.

## Scenario B — 90-day cut (Frequency → Ladder → Total Work)

Issue: [#56](https://github.com/suncoast-servers/GreyskullLP/issues/56)

| Days | Barbell | Calisthenics method |
|------|---------|---------------------|
| 1–40 | OG Base, 2x/week (Tue/Sat) | Frequency |
| 41–70 | Villain, 2x/week | Ladder |
| 71–90 | Two-Day Split, 2x/week | Total Work |

- Overweight trainee in a **calorie deficit** (`nutritionMode: cutting`,
  1,850 kcal target), with a **falling bodyweight note** on every diet entry
  (≈118.0 kg → ≈111.6 kg).
- Barbell loads **stall and take a 10% reset** every fifth session, which is
  what cutting trainees actually see.
- Calisthenics volume is ~80% of Scenario A so recovery-limited progress and
  declining trends are visible on Stats.

Use the same **Settings → QA / Demo Data** picker; both scenarios share one
import path.
