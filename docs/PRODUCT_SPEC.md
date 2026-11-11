# GreyskullLP — product specification (v1 target)

**Sanction:** Official Greyskull LP program (Johnny Pain).  
**Positioning:** Free, open-source workout app published by [Suncoast Servers](https://github.com/suncoast-servers).  
**Ryan provides:** Store account ownership, merge/release approval. **Authoritative program text:** [`docs/reference/Greyskull_LP_3rd_edition.pdf`](../reference/Greyskull_LP_3rd_edition.pdf) (in repo; see `docs/reference/README.md`).

## Brand & visual direction

- Aesthetic: rugged, minimal **black / white / gray**; Greyskull / Skeletor motif consistent with Johnny Pain’s books and [Greyskull Nation](https://greyskullnation.com/) web presence.
- Contractor delivers **2–3 theme/skin options** (Flutter `ThemeData` + optional asset packs). Ryan may refine visuals later with separate design tools.
- Respect trademark/attribution in-app and in store listings.

## Store distribution

| Platform | Owner | Contractor delivers |
|----------|--------|---------------------|
| **Apple App Store** | Ryan (paid Apple Developer) | Release build, signing checklist, TestFlight-ready artifact process |
| **Google Play** | Ryan (account TBD) | Release build (`appbundle`), Play Console upload checklist; Ryan creates/owns Play Developer account |

No signing keys or store API JSON in the repository.

## Core program (from book)

1. **Barbell templates** — Simple Greyskull LP weight templates with user customization and **accessory exercises** per book guidance (non-trivial UX).
2. **Calisthenics — three methods** (must be first-class, not afterthoughts):
   - **Frequency method**
   - **Ladder method**
   - **Total work method**
3. **Progress analytics** — Volume and method-appropriate metrics over time (charts, history, stats screens). Users should see progression when they add weight work, switch methods, or increase complexity.
4. **Progressive UX** — Default path: basic weight program + frequency method; allow graduation to ladder/total work and richer accessories without breaking prior data.

**Baseline in repo:** Scaffold screens exist (`workout_page_*.dart`, `training_state.dart`); fidelity to the book is the main delivery gap.

## Integrations

| Integration | Goal |
|-------------|------|
| **Greyskull Nation forum** | WordPress-based; plug-and-play URLs + auth hooks when API keys exist; embedded experience in-app today |
| **Founder storefront** | Research embed (likely Shopify / [store.greyskullnation.com](https://store.greyskullnation.com/)); configurable URL in settings |
| **Forum accountability** | Optional posts after workouts / end of day (manual, on-complete, or scheduled); depends on forum auth/API when available |
| **Social sharing** | Optional share sheet after workout (image/caption/location where platform allows) — no dark patterns |

## Data & privacy

- **Default:** Local-first on device (current SharedPreferences; propose SQLite/drift migration in ADR).
- **Optional future:** Ryan-hosted sync on Hetzner VPS — contractor writes **ADR** with cost (order-of-magnitude), security, and opt-in model.
- **Marketing angle:** Open source + local-first + no silent cloud exfiltration.
- **User responsibility:** Export/backup before uninstall; improve backup UX vs. unofficial apps that rely on sloppy export-only flows.

## Out of scope for contractor without Ryan sign-off

- Publishing to stores under Ryan’s accounts
- Changing bundle IDs / production IDs
- Committing forum API secrets or store keys

## Issue tracker

Execution breakdown: GitHub milestone **GreyskullLP v1** and linked issues (see [ROADMAP.md](ROADMAP.md)).
