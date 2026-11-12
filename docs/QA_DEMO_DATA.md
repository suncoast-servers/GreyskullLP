# QA Demo Data

Debug-only fixtures so **Stats** and **History** can be reviewed at real-world
scale without waiting months for real logs.

> These fixtures never ship enabled in store builds. The entry point is hidden
> unless the app is built in debug/profile (`kDebugMode`) or compiled with
> `--dart-define=ENABLE_DEMO_DATA=true`.

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

## Scenario B (issue #56)

Scenario B (overweight user cutting, Frequency → Ladder → Total Work) will reuse
the same picker and import path; only the fixture generator changes.
