# One-shot backlog seed for GreyskullLP v1 — run from repo root with gh auth / git credential token.
$ErrorActionPreference = 'Stop'
$cred = @"
protocol=https
host=github.com

"@ | git credential fill 2>$null
$env:GH_TOKEN = (($cred | Where-Object { $_ -match '^password=' }) -replace '^password=','')
$gh = 'C:\Program Files\GitHub CLI\gh.exe'
$owner = 'suncoast-servers'
$repo = 'GreyskullLP'

$labels = @(
  @{ name = 'epic'; color = '5319E7'; description = 'Epic / parent issue' },
  @{ name = 'store-release'; color = '0E8A16'; description = 'App Store / Play Store' },
  @{ name = 'ux-theme'; color = 'FBCA04'; description = 'Visual design and themes' },
  @{ name = 'workouts'; color = '1D76DB'; description = 'Weight templates and accessories' },
  @{ name = 'calisthenics'; color = '006B75'; description = 'Frequency, ladder, total work' },
  @{ name = 'stats'; color = 'C5DEF5'; description = 'Charts and analytics' },
  @{ name = 'integration'; color = 'D93F0B'; description = 'Forum, store, external services' },
  @{ name = 'social'; color = 'E99695'; description = 'Sharing and accountability posts' },
  @{ name = 'data'; color = 'BFD4F2'; description = 'Persistence, sync, privacy' }
)
foreach ($l in $labels) {
  $body = @{ name = $l.name; color = $l.color; description = $l.description } | ConvertTo-Json -Compress
  try { $body | & $gh api -X POST "repos/$owner/$repo/labels" --input - 2>$null } catch { }
}

$patch = @{
  title = 'GreyskullLP v1'
  description = 'Open-source store release: program fidelity, integrations, local-first data. See docs/PRODUCT_SPEC.md.'
  due_on = '2026-04-01T12:00:00Z'
} | ConvertTo-Json -Compress
$patch | & $gh api -X PATCH "repos/$owner/$repo/milestones/1" --input - | Out-Null
$ms = 1

function New-GhIssue($title, $body, [string[]]$issueLabels) {
  $payload = @{
    title = $title
    body = $body
    milestone = $ms
    labels = $issueLabels
  } | ConvertTo-Json -Compress
  return ($payload | & $gh api -X POST "repos/$owner/$repo/issues" --input - | ConvertFrom-Json)
}

$issues = @(
  @{
    title = 'Apple App Store release readiness (Ryan owns account)'
    labels = @('store-release')
    body = @'
## Context
Ryan has a **paid Apple Developer** account. Contractor prepares the app; Ryan publishes.

## Acceptance criteria
- [ ] Document bundle ID, signing (Team), and `ios/` release build steps — no certs in git
- [ ] TestFlight upload checklist for Ryan (or successful archive documented on macOS)
- [ ] App privacy labels draft (data collected = on-device; integrations documented)
- [ ] Store listing draft placeholders (screenshots sizes, description) in issue/PR

## References
`docs/PRODUCT_SPEC.md`, `ios/Runner.xcworkspace`
'@
  },
  @{
    title = 'Google Play release readiness + Ryan Play Console setup'
    labels = @('store-release')
    body = @'
## Context
Ryan may **not yet** have a Google Play Developer account. Contractor delivers build artifacts and a **Ryan action list** to create account and upload.

## Acceptance criteria
- [ ] `flutter build appbundle` documented; release signing pattern documented (keystore local-only)
- [ ] Checklist for Ryan: Play Developer registration, app create, internal testing track
- [ ] Data safety form draft aligned with local-first storage
- [ ] Note any Play policy items for fitness / health apps

## Ryan action
Create Google Play Developer account ($one-time fee) when checklist is ready.
'@
  },
  @{
    title = 'Greyskull LP barbell templates + accessories customization'
    labels = @('workouts')
    body = @'
## Context
Book defines simple barbell work plus **accessory exercises** — users must customize without breaking program logic.

## Acceptance criteria
- [ ] Official Greyskull LP weight templates modeled from Ryan-provided PDF (Ryan shares PDF off-repo)
- [ ] User can add/reorder accessory exercises per book rules
- [ ] Changes persist and survive app restart
- [ ] Tests for template load/save and at least one accessory flow

## Technical notes
`lib/models/training_state.dart`, workout pages under `lib/pages/`
'@
  },
  @{
    title = 'Calisthenics: Frequency, Ladder, and Total Work (book fidelity)'
    labels = @('calisthenics', 'workouts')
    body = @'
## Context
Three methods are core to the program. Scaffold UI exists; behavior must match book.

## Acceptance criteria
- [ ] Each method has complete log/edit/history flow
- [ ] Method selection and switching preserve history
- [ ] UX copy/metrics align with PDF spec (contractor notes ambiguities in issue)
- [ ] Widget or unit tests per method where practical

## Baseline
`workout_page_frequency.dart`, `workout_page_ladder.dart`, `workout_page_totalwork.dart`
'@
  },
  @{
    title = 'Progress analytics: volume, charts, and method transitions'
    labels = @('stats', 'calisthenics', 'workouts')
    body = @'
## Context
Users need graphs and readouts (volume, trends) including when they **graduate** between methods or add weight work.

## Acceptance criteria
- [ ] Stats/history screens show meaningful time series (per method and combined where sensible)
- [ ] Document metric definitions in PR (what is "volume" for each method)
- [ ] Empty states and first-time user experience handled
- [ ] Performance acceptable on mid-range Android device

## Baseline
`lib/pages/stats_page.dart`, `lib/pages/history_page.dart`
'@
  },
  @{
    title = 'Progressive UX: simple start path to advanced programming'
    labels = @('workouts', 'calisthenics', 'ux-theme')
    body = @'
## Context
New users start with **basic weight training + frequency method**; over time add accessories, other calisthenics methods, or complexity.

## Acceptance criteria
- [ ] Onboarding or defaults reflect simple starter path
- [ ] Users can enable features without data loss
- [ ] UI makes current program level clear (what is active)
- [ ] Contractor proposes 1–2 flows in PR description before full polish

## Product
See `docs/PRODUCT_SPEC.md` — Ryan approves UX direction in PR review.
'@
  },
  @{
    title = 'Theme system: Greyskull skins (black / white / gray, Skeletor motif)'
    labels = @('ux-theme')
    body = @'
## Context
Brand: Johnny Pain Greyskull — rugged, **black, white, gray**, Skeletor/Greyskull logo language (see greyskullnation.com). Ryan may refine visuals later; contractor ships **2–3 theme options**.

## Acceptance criteria
- [ ] Central theme API (`ThemeData` + optional assets) with swappable skins
- [ ] 2–3 distinct but on-brand skin proposals in app (selector in Settings or debug)
- [ ] No copyrighted assets committed without Ryan approval — use placeholders if needed
- [ ] Screenshots in PR for each skin

## Note
Not pixel-perfect glam required; coherent, clean, on-theme.
'@
  },
  @{
    title = 'Greyskull Nation forum: WordPress plug-and-play integration'
    labels = @('integration')
    body = @'
## Context
Forum is WordPress-based (Greyskull Nation). **No API key from founder yet** — design for plug-and-play when available.

## Acceptance criteria
- [ ] Document forum stack (WordPress plugin/theme) from public site + signup flow
- [ ] Settings: forum URL, login URL (existing pattern extended)
- [ ] In-app forum experience stable (WebView or better if auth API later)
- [ ] Architecture note for future REST/auth when Ryan obtains credentials

## Baseline
`lib/pages/forum_page.dart`
'@
  },
  @{
    title = 'Founder storefront: identify platform and in-app store experience'
    labels = @('integration')
    body = @'
## Context
Sales page likely Shopify ([store.greyskullnation.com](https://store.greyskullnation.com/)) — confirm and embed.

## Acceptance criteria
- [ ] Identify storefront tech and best embed approach for Flutter
- [ ] Configurable store URL in settings
- [ ] WebView or plugin approach documented with trade-offs
- [ ] Handles offline/slow network gracefully

## Baseline
`lib/pages/store_page.dart`
'@
  },
  @{
    title = 'Forum accountability posts (manual, on-complete, end-of-day)'
    labels = @('integration', 'social')
    body = @'
## Context
After workouts / daily calisthenics, user may post progress to forum for team accountability.

## Acceptance criteria
- [ ] Settings: off | manual | on workout complete | end-of-day summary
- [ ] Post body template includes day/workout summary (no PII beyond user chooses)
- [ ] Clear UX when forum auth unavailable (queue/draft/copy — no silent failure)
- [ ] Hook in `training_state` / workout completion paths

## Depends on
Forum auth API may be limited until WordPress credentials exist — implement graceful degradation.
'@
  },
  @{
    title = 'Social share after workout (multi-platform share sheet)'
    labels = @('social')
    body = @'
## Context
Optional share for free promotion: workout complete → share to X, Facebook, Instagram, etc. (OS share sheet).

## Acceptance criteria
- [ ] Share action from workout completion (optional)
- [ ] Default caption mentions Greyskull LP app + attribution
- [ ] Optional image/selfie via platform picker where supported (no forced permissions)
- [ ] Privacy: user opts in; no auto-posting without consent

## Flutter
`share_plus` already in project — extend with branded templates.
'@
  },
  @{
    title = 'Data architecture ADR: local-first vs optional Hetzner sync'
    labels = @('data')
    body = @'
## Context
Today: SharedPreferences JSON. Unofficial apps use sloppy SQLite export. We want **local-first** open-source story + optional Ryan-hosted sync.

## Acceptance criteria
- [ ] ADR in `docs/adr/` comparing: local SQLite/drift only | optional sync to Hetzner VPS
- [ ] Cost order-of-magnitude (bandwidth/storage) for modest user base
- [ ] Security: auth model if sync; default remains no cloud
- [ ] Migration plan from SharedPreferences
- [ ] Backup/export UX so users do not lose data on uninstall

## Product angle
Advertise: we do not steal data; user controls export/share.
'@
  }
)

$created = @()
foreach ($i in $issues) {
  $r = New-GhIssue $i.title $i.body $i.labels
  Write-Host "Created #$($r.number): $($r.title)"
  $created += $r
}

$childList = ($created | ForEach-Object { "- #$($_.number) $($_.title)" }) -join "`n"
$epicBody = @"
# Epic: GreyskullLP v1 (open-source store release)

Track **Product spec:** [docs/PRODUCT_SPEC.md](https://github.com/suncoast-servers/GreyskullLP/blob/main/docs/PRODUCT_SPEC.md)

## Child issues
$childList

## Definition of done (epic)
- [ ] Testable on Apple (TestFlight) and Google (internal testing) with Ryan-owned accounts
- [ ] Book-faithful workouts + three calisthenics methods + useful charts
- [ ] Forum/store plug-and-play; accountability/social opt-in
- [ ] ADR for data; local-first default with strong backup story
"@

$epic = New-GhIssue 'Epic: GreyskullLP v1 — free open-source store release' $epicBody @('epic')
Write-Host "Created epic #$($epic.number)"

# Link children to epic in comments
foreach ($c in $created) {
  $comment = "Part of epic #$($epic.number)"
  $p = @{ body = $comment } | ConvertTo-Json -Compress
  $p | & $gh api -X POST "repos/$owner/$repo/issues/$($c.number)/comments" --input - | Out-Null
}

# Pin epic on repo (works via API)
$pin = @{ query = "mutation { pinIssue(input: {issueId: `"$($epic.node_id)`"}) { issue { number title } } }" } | ConvertTo-Json -Compress
$pin | & $gh api graphql --input - | Out-Null
Write-Host "Pinned issue #$($epic.number)"

# Supersede early placeholder issues
foreach ($n in 1..11) {
  & $gh issue close $n --repo "$owner/$repo" --comment "Superseded by epic #$($epic.number) and GreyskullLP v1 backlog (issues #$($created[0].number)+). See docs/PRODUCT_SPEC.md." 2>$null
}

Write-Host "Done."
