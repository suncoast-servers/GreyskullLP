# AGENTS.md — GreyskullLP (Flutter)

Guidance for **Cursor**, **Claude Code**, **Codex**, and human contributors.

## Product context

Open-source **Flutter** app for the official **Greyskull LP** program (sanctioned by Johnny Pain). Goal: **Google Play** and **Apple App Store** releases under **Suncoast Servers** ownership.

## Program fidelity (required reading)

- **Authoritative text (in repo):** `docs/reference/Greyskull_LP_3rd_edition.pdf` — barbell templates, methods, and rules must align with this edition unless an issue says otherwise.
- **Pointer / edition constant:** `lib/program/program_source.dart`
- **Do not** invent program variants; use book templates plus user customization hooks defined in issues/PRs.
- **4th edition:** Not in repo yet — follow the TODO in `program_source.dart` when Johnny Pain releases it.

## Ownership

| Role | Who |
|------|-----|
| **Repo & product owner** | Ryan (@TheDevWhoSaysNi) — merges, store accounts, release go/no-go |
| **Delivery lead (contractor)** | Umer (@umerwaqas92) — feature branches, PRs, store-readiness implementation |

## Git rules

1. **Never push to `main`.** Use `feat/...` or `fix/...`.
2. Open a **PR**; fill the template; link the issue.
3. Ryan (or delegate) **merges** after review.
4. No signing keys, keystore, App Store Connect API keys, or Play service JSON in git.

## Flutter commands (run before every PR)

```bash
flutter pub get
dart format .
flutter analyze
flutter test
```

Note target platform in PR (Android emulator, iOS simulator — iOS requires macOS).

## Store / release

- Bundle IDs, signing, and store listings are coordinated with Ryan.
- Do not publish to stores or change production IDs without explicit approval in writing (Upwork + GitHub issue).

## More detail

- Org workflow: https://github.com/suncoast-servers/.github/blob/main/CONTRIBUTING.md
- This repo: `docs/COLLABORATOR.md`, `docs/ROADMAP.md`, `CONTRIBUTING.md`
