# Greyskull LP — Forum Accountability Posts Architecture

**Owner / Product Authority:** [@TheDevWhoSaysNi](https://github.com/TheDevWhoSaysNi)  
**Delivery Lead:** [@umerwaqas92](https://github.com/umerwaqas92)  
**Repository:** [suncoast-servers/GreyskullLP](https://github.com/suncoast-servers/GreyskullLP)  
**Related Issue:** Closes #21  

---

## 1. Overview & Objectives

In the Greyskull LP philosophy, consistency and community accountability are central to long-term strength and conditioning progress. 

This feature allows lifters to effortlessly share formatted workout logs, calisthenics milestones, and daily summaries with the **Greyskull Nation Forum** team room, while strictly respecting privacy and providing **graceful degradation** while direct WordPress API credentials are pending from the founder.

---

## 2. Posting Modes (Configurable in Settings)

Located in [lib/pages/settings_page.dart](file:///Users/umerwaqas/Downloads/ryan_ellenburg/GreyskullLP/lib/pages/settings_page.dart), lifters can select one of four modes:

| Mode | Behavior | UX / Flow |
|---|---|---|
| **`Off`** | Disabled | No accountability prompts or draft creation on workout completion. |
| **`Manual`** *(Default)* | Opt-in per workout | Shows a subtle **"Post to Forum"** action on the workout completion SnackBar. Tapping opens the draft bottom sheet. |
| **`On Workout Complete`** | Automatic draft sheet | Immediately presents the **Accountability Post Bottom Sheet** upon logging a barbell or calisthenics session. Auto-copies to clipboard. |
| **`End-of-Day Summary`** | Daily compilation | Compiles all barbell lifts, daily push-up/chin-up totals, and optional nutrition targets logged during the current date into a cohesive summary. Triggerable anytime in Settings. |

---

## 3. Post Body Templates & Privacy Guarantee

### A. Barbell Weight Program Log
```text
[b]Greyskull LP — Workout Accountability Log[/b]
📅 Date: 2026-11-11
🏋️ Session Type: Barbell Strength Training
👤 Lifter: JohnnyFan99

[b]Core Lifts:[/b]
Bench Press: 200 lbs x 5, 5, 8 (AMRAP)
Squat: 275 lbs x 5, 5, 6 (AMRAP)

[b]Accessory Work:[/b]
Barbell Row, Romanian Deadlift

📊 Total Session Volume: 3,250.0 lbs

📝 Notes:
Solid AMRAP reps today. Good bar speed.

— Logged with the Official Greyskull LP App
https://store.greyskullnation.com/
```

### B. Daily Calisthenics Log
```text
[b]Greyskull LP — Daily Calisthenics Accountability[/b]
📅 Date: 2026-11-11
💪 Method: Frequency Method
👤 Lifter: JohnnyFan99

[b]Reps Completed:[/b]
• Push-ups: 60 reps
• Chin-ups: 25 reps
• Optional: Dips, Plank

— Logged with the Official Greyskull LP App
https://store.greyskullnation.com/
```

### C. End-of-Day Summary
```text
[b]Greyskull LP — End-of-Day Accountability Summary[/b]
📅 Date: 2026-11-11
👤 Lifter: JohnnyFan99

[b]🏋️ Strength Work:[/b]
• Weight Program Session:
Bench Press, Squat

[b]💪 Daily Calisthenics Totals:[/b]
• Push-ups: 60 / 50 reps target
• Chin-ups: 25 / 20 reps target

[b]🥗 Daily Nutrition:[/b]
• Protein: 185g
• Calories: 2,210 kcal

— Logged with the Official Greyskull LP App
https://store.greyskullnation.com/
```

### Privacy & PII Guarantee:
- **Zero forced personal data**: No email, phone number, location, device model, or identifiers are included.
- **Opt-in handle**: Only the user's voluntary `forumDisplayName` is attached if configured in Settings.
- **Pre-publish editing**: Every draft is fully editable inside `AccountabilityPostSheet` before copying or posting.

---

## 4. Graceful Degradation & Founder Auth Blueprint

Because WordPress REST API application credentials or JWT tokens have not yet been provisioned by the founder:

1. **Clipboard & Web Composer Flow (Current Phase):**
   - Opening the draft automatically writes the formatted BBCode / Markdown to `Clipboard`.
   - The user can tap **"Open Forum"** to launch `https://forum.greyskullnation.com/` directly.
   - The draft is preserved locally in `trainingState.accountabilityDrafts` (viewable and manageable in Settings).
2. **Direct REST API Integration (Future Phase):**
   - When Ryan obtains credentials (via WordPress Application Passwords or JWT plugin):
   ```text
   POST /wp-json/wp/v2/posts (or custom forum REST endpoint)
   Authorization: Basic <base64(user:application_password)>
   Content-Type: application/json
   
   {
     "title": "Workout Accountability Log — 2026-11-11",
     "content": "<p>...</p>",
     "status": "publish",
     "categories": [forum_accountability_category_id]
   }
   ```
   - `TrainingState` and `AccountabilityPostSheet` will simply dispatch via this endpoint without modifying template generation or storage models.

