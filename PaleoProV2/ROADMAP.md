# Paleo Pro — What's Next

A roadmap for after 2.1. Themed sections, then a suggested order at the end. Patterns referenced from leading apps were researched on Mobbin (links inline).

## Where the app stands after 2.1

Paleo Pro is now a polished reference and a light learning tool:

- Learn: the 22-letter grid, and a page per letter tracing its history to modern Hebrew
- Play: a 10-question quiz, both directions, with per-letter mastery tracking
- Convert: modern to Paleo and back, plus a Share extension for text from any app
- Keyboard: a system-wide Paleo keyboard with the chosen letterform
- Learning Center: real inscriptions you can zoom into and copy
- Letterforms: historical scribal hands applied everywhere
- Platform: widgets (Letter of the Day, evolution, Quick Open), Spotlight, Siri Shortcuts, Handoff, quick actions, Control Center, iCloud-ready

The honest gap: the app is strong as a **reference** and as a **good iOS citizen**, but lighter as a **learning product** (no structured progression, no retention loop, limited practice variety) and there is still platform headroom (Watch, Live Activities, tracing). The roadmap below leans into those.

## 1. Deeper Apple platform integration

- **Apple Watch app.** A Letter of the Day complication, a glanceable quiz, and a quick converter. watchOS was deferred for launch; it is the natural next platform and a strong differentiator for a glanceable reference.
- **Live Activity / Dynamic Island.** A quiz-in-progress activity (question x of 10), or a daily streak / Letter of the Day activity.
- **Interactive widgets.** Use `Button(intent:)` so a widget can flip a flashcard, reveal a letter, or start a quiz inline without launching the app.
- **More Control Center controls and App Shortcuts.** Add Letter of the Day and Start Quiz controls; donate activities and add a parameterized "Convert [text] to Paleo" intent with natural Siri phrases.
- **Apple Pencil / Scribble on iPad.** Trace letters with the Pencil; ties directly into the tracing feature below.
- **TipKit.** In-context tips for setting up the keyboard and discovering the letterform picker.
- **App Store In-App Events.** A recurring "Letter of the Week" or seasonal event to drive re-engagement and earn extra store surface.

## 2. Learning depth (turn a reference into a curriculum)

- **Letter tracing / writing practice.** A "Trace the Paleo letter" mode with stroke-order guides. This teaches the form, not just recognition, and is an obvious fit for an ancient-script app. Apple-quality precedent: Duolingo's [Trace the letter](https://mobbin.com/screens/206d849a-feec-4364-ae45-28e3c5d8bb0c) and [Duolingo ABC](https://mobbin.com/screens/2b76e86d-0a83-49ed-9f71-fe505c116d9b) both use an animated dotted path with a directional guide, including for non-Latin scripts.
- **Spaced repetition (SRS).** Schedule reviews of the letters a user is weakest on, using the `LetterStat` mastery data the app already records. This is the single biggest learning-quality upgrade.
- **A structured path.** Group letters into short lessons (4 at a time), unlocked progressively, so there is a sense of beginning, middle, and end rather than a flat grid.
- **More quiz modes.** Audio (hear the letter name), trace-to-answer, match-the-pairs, fill-in-the-blank, and a timed mode.
- **Audio and pronunciation.** Spoken letter names (Aleph, Bet, ...), ideally recorded. Doubles as an accessibility win.
- **Reading practice.** Short real inscriptions to read and transliterate (Siloam, Tel Dan are already in the app), as a guided "read this" mode.

## 3. Engagement and retention

- **Onboarding.** A short, friendly first-run flow: what brings you here, prior familiarity, set a daily goal, and opt in to a reminder. Duolingo's [onboarding](https://mobbin.com/flows/ac9d2f58-868d-4fd3-a79c-9655ce6b1522) is the reference: a few quick choices (goal, skill level, minutes per day) and, notably, a step that prompts the user to add the Home Screen widget. Keep it to four or five taps.
- **Streaks and a daily goal.** A streak counter and a simple daily goal (one quiz, or five letters a day). This is the highest-leverage retention mechanic in learning apps.
- **Local notifications, done right.** An opt-in daily "Letter of the Day" and gentle streak reminders, building on the provisional notification system already in place.
- **Achievements and milestones.** "Learned all 22," "7-day streak," "first inscription read."
- **Progress dashboard.** A mastery overview with history and stats, so progress is visible.

## 4. Content and credibility

- **Richer per-letter history.** Add dates, a small map of where each inscription was found, and one-line context per stage in the existing timeline.
- **Expanded Learning Center.** More inscriptions, a glossary of terms, a short illustrated history of the script, and sources.

## 5. Sharing and growth

- **Shareable alphabet poster.** The per-letter share card already exists; add a full-alphabet card and a "what I learned" progress card.
- **App Store In-App Events.** See platform section; these drive both retention and discovery.

## 6. Monetization (optional)

- **Paleo Pro+.** Premium letterforms, advanced practice modes, themes, and unlimited history, with the core experience staying free. A one-time unlock may suit this audience better than a subscription. Keep it tasteful given the educational and religious context.

## 7. Accessibility and internationalization

- **Hebrew (and possibly Yiddish) UI localization.** The audience is Hebrew-literate; localizing the interface is a natural fit and widens reach.
- **Deeper VoiceOver and audio.** Spoken letter names tie accessibility and learning together.
- **Continue the Dynamic Type pass** already started.

## 8. Technical foundation

- **Tests.** `ConversionEngine` is pure and trivial to unit-test; add coverage there, plus quiz scoring and any SRS scheduling.
- **Privacy-respecting analytics.** Opt-in, aggregate, just enough to see which features are used.
- **CI.** Build and test on every PR.
- **Keep watching launch performance** (font registration, store setup) now that the earlier hangs are fixed.

## Suggested order

1. **Retention foundation (highest leverage).** Onboarding, daily goal, streaks, and an opt-in daily reminder. This is what turns installs into a habit.
2. **Learning depth.** Letter tracing with stroke order, spaced repetition, a couple more quiz modes, and audio letter names.
3. **Platform reach.** Apple Watch app, a Live Activity, and an interactive widget.
4. **Content and growth.** Expanded reading practice, In-App Events, shareable posters, Hebrew localization.
5. **Ongoing.** Tests, analytics, accessibility, and polish.

The theme: 2.x made Paleo Pro a beautiful reference and a model iOS citizen. The next arc is making it a place people return to daily and genuinely learn from, starting with the retention loop and the tracing/SRS practice that a script app is uniquely suited to.
