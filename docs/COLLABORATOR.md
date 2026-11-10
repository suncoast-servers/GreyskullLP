# GreyskullLP — contractor onboarding

Welcome, **Umer** ([@umerwaqas92](https://github.com/umerwaqas92)).

You are the **delivery lead** for Flutter work toward **Google Play** and **App Store** releases. **Ryan** ([@TheDevWhoSaysNi](https://github.com/TheDevWhoSaysNi)) retains organization, repository, store accounts, and **merge authority**.

## Access model (recommended)

You are an **outside collaborator** on **this repository only** with **`push`** permission — **not** a full `suncoast-servers` organization member. That limits blast radius while still letting you create branches and open pull requests.

After accepting Ryan’s GitHub invitation, confirm access:

```bash
git ls-remote https://github.com/suncoast-servers/GreyskullLP.git HEAD
```

## Clone

```bash
git clone https://github.com/suncoast-servers/GreyskullLP.git
cd GreyskullLP
flutter pub get
flutter doctor -v
```

## Workflow (required)

`main` is **protected**: no direct pushes, PR + approval required, CODEOWNERS review.

1. Pick a **GitHub Issue** (see milestone **Store readiness**) or ask Ryan to create one.
2. Sync and branch:

   ```bash
   git fetch origin
   git checkout main && git pull
   git checkout -b feat/12-short-description
   ```

3. Implement; before every PR:

   ```bash
   dart format .
   flutter analyze --fatal-infos
   flutter test
   ```

4. Push and open a **Pull Request** into `main` (use the template).
5. Address review comments. **Do not merge** unless Ryan explicitly asks.

Branch names: `feat/<issue>-short-name` or `fix/<issue>-short-name`.

## Where direction lives

| Channel | Use for |
|---------|---------|
| **GitHub Issues** | Scoped tasks, acceptance criteria, technical discussion |
| **Pull requests** | Code review, design notes, test evidence |
| **Upwork** | Contract, schedule, rates, confidential product decisions |
| **Email** | info@suncoastservers.com — escalations |

Read [docs/ROADMAP.md](ROADMAP.md) for phases and priorities.

## AI coding tools

If you use Cursor or similar, follow **[`AGENTS.md`](../AGENTS.md)** in the repo root (no secrets in chat, no push to `main`).

## Security

- Do not commit keystores, Play/App Store API JSON, `.env`, or production tokens.
- Store signing and bundle IDs change only with Ryan’s written approval (Upwork + linked issue).

## Offboarding

When the engagement ends, Ryan removes collaborator access and rotates any shared credentials you had.
