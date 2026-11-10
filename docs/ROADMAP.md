# GreyskullLP — product roadmap

**Owner / merge authority:** [@TheDevWhoSaysNi](https://github.com/TheDevWhoSaysNi)  
**Delivery lead (contractor):** [@umerwaqas92](https://github.com/umerwaqas92) — Flutter implementation toward store releases  
**Organization:** [suncoast-servers](https://github.com/suncoast-servers)

This document is the **public engineering backlog**. Commercial scope, rates, and sensitive direction stay on **Upwork**; **GitHub Issues** track deliverables with acceptance criteria.

## North star

Ship **Greyskull LP** to **Google Play** and the **Apple App Store** under Suncoast Servers, with Johnny Pain’s sanction retained in store listings and in-app attribution.

## Current state (baseline)

| Area | Status |
|------|--------|
| Flutter app scaffold | In progress — workout, diet, stats, history, settings, forum/store WebViews |
| Local persistence | SharedPreferences JSON; backup export/restore in Settings |
| CI | `flutter analyze` + `flutter test` on PRs and `main` |
| Store signing / listings | Owned by Ryan — coordinate before changing bundle IDs or publishing |

## Phases

### Phase 1 — Release hygiene (now)

- Stabilize core workout logging and progression UX
- Harden diet search and daily totals
- Expand automated tests for models and critical flows
- Android release build documented (`flutter build appbundle`)
- iOS build path documented (Team, bundle ID, Xcode smoke test)

### Phase 2 — Data & integrations

- Evaluate SQLite (`sqflite` / `drift`) migration when query/backup needs grow
- Forum accountability sync (see `TODO(ForumSync)` in `lib/models/training_state.dart`)
- Polish embedded store and forum URLs from settings

### Phase 3 — Store launch

- Play Console internal testing track
- TestFlight (or equivalent) for iOS
- Store assets, privacy policy URL, and release notes — Ryan approves copy

## How work is assigned

1. Ryan creates or refines a **GitHub Issue** (acceptance criteria required).
2. Contractor branches `feat/<issue>-short-name` or `fix/...`.
3. PR references the issue; Ryan reviews and merges.

> **Ryan:** Edit the phases above or add Issues anytime. The contractor should treat **open Issues in the “Store readiness” milestone** as the active sprint unless you say otherwise on Upwork.
