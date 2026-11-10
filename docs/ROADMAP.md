# GreyskullLP — product roadmap

**Owner / merge authority:** [@TheDevWhoSaysNi](https://github.com/TheDevWhoSaysNi)  
**Delivery lead:** [@umerwaqas92](https://github.com/umerwaqas92)  
**Organization:** [suncoast-servers](https://github.com/suncoast-servers)  
**Spec:** [PRODUCT_SPEC.md](PRODUCT_SPEC.md)

Open-source, **free** Greyskull LP app — flagship public project for Suncoast Servers.

## North star

Ship to **Google Play** and **Apple App Store** with program fidelity to Johnny Pain’s Greyskull LP (weights + three calisthenics methods), local-first privacy, and plug-and-play forum/store integrations.

## Milestone: GreyskullLP v1

All active delivery issues are tagged in GitHub milestone **[GreyskullLP v1](https://github.com/suncoast-servers/GreyskullLP/milestone/1)**.

| Track | Issues (epic) |
|-------|----------------|
| Store release | Apple + Play readiness, Ryan-owned accounts |
| Brand / UX | Theme skins (B/W/gray, Greyskull motif) |
| Program | Templates, accessories, three methods, charts |
| Integrations | Forum, store, accountability posts, social share |
| Data | Local-first ADR + backup; optional Hetzner sync proposal |

## Phase order (suggested)

1. **Stabilize & ship path** — CI green, release builds documented, store checklists (#12–#13).
2. **Book fidelity** — Templates, methods, statistics (#14–#17).
3. **Look & feel** — Theme proposals (#18); Ryan can polish later.
4. **Integrations** — Forum/store research, accountability, social (#19–#22).
5. **Data architecture** — ADR and migration plan (#23).

Contractor may parallelize research spikes (store platform, forum stack) early while Ryan creates Play Developer account if missing.

## Ryan-owned actions

- Provide PDF ebook to contractor (secure channel, not git).
- Apple Developer / App Store Connect.
- Google Play Developer account (create when ready).
- Approve store listings, privacy policy URL, and attribution copy.
- **Pin repos** on [profile](https://github.com/TheDevWhoSaysNi) and [org](https://github.com/suncoast-servers) (no public API — use “Customize your pins”).

## How work is assigned

1. Issues define acceptance criteria.
2. Branch `feat/<issue>-short-name` → PR → Ryan merges.
3. Scope changes: comment on issue or Upwork; update PRODUCT_SPEC if material.
