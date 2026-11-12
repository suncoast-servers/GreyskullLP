# QA Review Pass (issue #58)

Structured review of the app on device with demo history loaded, before the
v0.1 / store-candidate sign-off.

- **Owner:** Ryan (sign-off), Umer (fix list)
- **Build under review:** `release/v1.2.0-staging` after #46–#57
- **Platform:** Android 16 (Redmi 23090RA98G) — iOS pass still required
- **Demo data:** see `docs/QA_DEMO_DATA.md`

## 1. Load demo data

Settings (gear) → scroll to **QA / Demo Data** → pick a scenario → **Import demo data**.

| Scenario | What it exercises |
|---|---|
| **A — 90-day newbie** | OG → Villain → Gladiator, Frequency → Ladder → Total Work, bulking diet |
| **B — 90-day cut** | stalled/reset barbell loads, falling bodyweight notes, later method transitions |

Both replace existing data; export a backup first if needed.

## 2. Route checklist

Mark each after looking at it with demo data loaded.

### Home / navigation
- [ ] Bento menu tiles all open the right section
- [ ] Bottom nav labels/icons align with the Workout branding
- [ ] Settings gear reachable from every tab

### Workout
- [ ] Program level card, Adjust Level dialog, level cards readable
- [ ] Weight Program: 1 / 2 / 5+ circles, NEXT badge, AMRAP amber ring, volume total, log + share
- [ ] Custom program editor (build from zero, reorder, delete)
- [ ] Frequency: accessories inside Today's Accumulated Volume, tap-to-log (planks in seconds), chips in the log card
- [ ] Ladder: rung taps, wave/ladder completion, history save
- [ ] Total Work: daily/weekly targets, set breakdown, history save

### Stats
- [ ] 7d / 30d / 90d / All filters
- [ ] Resistance tab: volume series, PRs, session list
- [ ] Calisthenics tab: rep trend, method breakdown
- [ ] Nutrition tab: protein/calories averages
- [ ] **Bodyweight Trend** card (from #57) with delta colour
- [ ] Method transitions & milestones list
- [ ] Metric Definitions sheet

### History
- [ ] Category filters (All / Daily / Resistance / Diet)
- [ ] View details, share
- [ ] **Edit** a barbell session (title, lifts, volume, notes) → Stats updates
- [ ] **Edit** a Frequency/Ladder/Total Work entry via its method editor
- [ ] **Delete** with confirmation → Stats updates
- [ ] Search/filter behaviour with 150+ entries

### Diet
- [ ] Macro card, calorie deficit/surplus copy
- [ ] Body Measurements card: add / edit / delete, latest values
- [ ] Food search (Open Food Facts) with real results, add item to macros
- [ ] No roadmap/placeholder copy

### Settings
- [ ] Theme switching: Iron & Bone, Skeletor Havoc, Chalk & Steel
- [ ] Program level switching preserves history
- [ ] Preferred daily method, targets
- [ ] Barbell template selection
- [ ] Forum accountability posts mode + pending drafts
- [ ] Social share settings
- [ ] Backups: share file, copy JSON, restore from pasted JSON
- [ ] Privacy / data ownership copy
- [ ] **No** Forum/Store/USDA integration blocks

### Forum / Store
- [ ] Forum page opens external site in app browser, no credentials stored
- [ ] Store page opens the storefront URL
- [ ] Both readable on all skins

## 3. Cross-cutting checks

- [ ] **Contrast:** every screen readable in Iron & Bone (dark) and Chalk & Steel (light)
- [ ] **Empty states:** fresh install shows helpful copy, not blank cards
- [ ] **Orientation:** portrait; landscape does not break layouts
- [ ] **Text scale:** system font size 1.3× does not clip critical controls
- [x] **Overnight rollover:** verified on device 2026-11-12 — a day-old tally (2 sets, Planks 60 s) auto-saved to History as "Frequency Method Day Summary" dated 11/11 with the rollover note, and Today's Frequency tally reset to 0 / 50 reps
- [ ] **Backup round-trip:** export → clear data → import → history, measurements and settings return

## 4. Known limitations to accept or file

| Item | Status |
|---|---|
| Midnight frequency rollover | **verified on device** 2026-11-12 (auto-saved summary + tally reset) |
| iOS pass | not run in this cycle (macOS simulator available) |
| Flutter 3.50 `material_ui` migration | CI pinned to 3.41.2; file a follow-up issue |
| Barcode scanning | not implemented; search only |
| Cloud sync | out of scope for v0.1 |

## 5. Sign-off

| Reviewer | Date | Result | Notes |
|---|---|---|---|
| Umer | 2026-11-12 | pass with fix list | #46–#57 verified on Redmi (PRs #59–#72), rollover device proof included |
| Ryan | | | |

File any new findings as issues and link them here before merging
`release/v1.2.0-staging` → `main` (#43).
