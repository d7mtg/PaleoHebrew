# Paleo Pro — App Behavior Reference

A functional map of every screen: what it contains and what each tap, gesture, and control does. Behavior only — no styling/visual notes.

App: a Paleo‑Hebrew learning app (iOS 26 deployment target) with a main app and a custom keyboard extension (Paleo Pro). Root is a 4‑tab `TabView`. The full alphabet is 22 letters; each letter has a `paleo` glyph, a `modern` Hebrew letter, and a `name`.

---

## 1. App entry & global behavior

- Entry: `PaleoProApp` → single `WindowGroup` hosting `ContentView`.
- **Accent color**: stored in `@AppStorage("selectedAccentColor")`, default `"teal"`. Applied app‑wide via `.tint(...)` and to UIKit chrome (`UINavigationBar`/`UITabBar` `tintColor`) at launch and on every change. Name→color map: blue, neutral (=label/systemGray3), green, orange, pink, purple, red, teal, indigo (default blue/teal).
- `ThemeManager` exposes the same `"selectedAccentColor"` key but with a different default (`"blue"`) and resolves it as a named asset color rather than a system color — a latent inconsistency (see Appendix).

## 2. Root tab bar (`ContentView`)

`TabView` with `.tabBarMinimizeBehavior(.onScrollDown)`. Tabs in order (default = Learn):

| # | Title | Symbol | Screen |
|---|-------|--------|--------|
| 1 | Learn | `book` | CheatSheetView |
| 2 | Play | `play.circle` | GameView |
| 3 | Convert | `arrow.left.arrow.right` | ConverterView |
| 4 | Settings | `gear` | SettingsView |

No selection binding — always opens on Learn.

---

## 3. Learn tab (`CheatSheetView`)

**Content:** fixed header "Paleo Pro" + a scrolling collection of all 22 letters. Grid cell shows modern / paleo glyph / NAME; list row shows paleo glyph · NAME · modern. A segmented toggle (`isGridView`, default grid) switches grid ↔ list.

**Interactions:**
- **View toggle (Picker):** switches layout (animated). Re‑selecting the current mode is a no‑op. Distinct haptic per direction (grid = 4 decreasing rigid impacts; list = soft + selection + medium).
- **Tap a letter:** copies the **Paleo glyph** to the clipboard; toast "COPIED"; medium impact haptic; tapped cell highlights for 0.15s.
- **Long‑press a letter (context menu):**
  - Copy Paleo "{paleo}" → copies paleo glyph, toast "PALEO COPIED".
  - Copy Modern "{modern}" → copies modern letter, toast "MODERN COPIED".
  - Advanced ▸ Copy Unicode → copies `U+%04X` of the first scalar (e.g. `U+05D0`), toast "UNICODE COPIED".
  - Advanced ▸ Copy HTML Entity → copies `&#x<HEX>;` (e.g. `&#x5D0;`), toast "HTML COPIED" (no‑op if no scalar).

**Side effects (every copy):** writes `UIPasteboard.general.string`; shows toast (auto‑hides 1.5s after the latest copy); increments `UserDefaults` `"copyCount"`; at counts **10 / 30 / 100** requests an App Store review (`SKStoreReviewController`).

---

## 4. Play tab (`GameView`)

A 10‑question quiz with a 4‑phase state machine (`gamePhase`): **splash → question → loading → summary**. Uses `InteractiveBackgroundView` on the splash.

**Splash:** title "Learn Paleo Hebrew" + subtitle.
- **Start Game:** light haptic; generates 10 questions, resets score/outcomes, → question phase.
- **View History:** presents `HistoryView` as a sheet.

**Question phase:**
- Shows "{n} of {total}" counter, a per‑question progress bar strip (green=correct, red=wrong, gray=unanswered), and the prompt glyph (paleo or modern depending on the question type).
- **4 answer options** (1 correct + 3 unique distractors, shuffled). Each is a single glyph.
- **Tap an option:** records the answer; correct → score +1, success haptic, and **auto‑advances after 3s**; incorrect → error haptic, no auto‑advance. All options disable once answered (correct option fills green, your wrong pick fills red).
- **X (close) button:** `resetGame()` → back to splash (clears all quiz state). Accessibility label "End Quiz".
- **Next button:** enabled only after answering; cancels the 3s auto‑advance and advances immediately.
- **Question generation:** random letter + random direction (paleo→modern or modern→paleo); correct answer is the opposite glyph; 3 distinct distractors. Letters may repeat across questions.

**Loading phase:** "Calculating Results…" ring fills over ~1.7s (timer +0.03 every 0.05s), then → summary after 0.3s.

**Advance side effect:** every `goToNextQuestion()` increments `"copyCount"` and fires the **10/30/100** review prompt (shared counter — see Appendix).

## 5. Summary (`SummaryView`, the `.summary` phase — not a sheet)

**Content:** performance title that varies by % (Excellent ≥0.9 / Well Done ≥0.7 / Good Job ≥0.5 / Keep Practicing), "{score} out of {total} correct", and a per‑question results list (type header, letter pair, Correct ✓ or your‑answer vs correct).

**Interactions:**
- **X (close):** calls `onExit` → resets the game (back to splash).
- **Primary button** (title varies: Play Again ≥0.8 / Try Again ≥0.5 / Practice More): `onPlayAgain` → new round, same length.
- **View History:** presents `HistoryView` sheet.

**Persistence (on appear, `saveResults`):**
- `letterPerformance` (`@AppStorage`): per letter‑pair key `"{paleo}_{modern}"` → cumulative `{correct, total}`.
- `quizHistory` (`@AppStorage`): appends a `QuizResult{date, score, total, letterResults}`; **capped at the 20 most recent** (oldest dropped).
- Note: a wrong answer's recorded "your answer" is a heuristic (first non‑correct option), not the actual tapped option (see Appendix).

## 6. History (`HistoryView`, presented as a sheet)

**Content:** list of past quizzes (newest first), each row showing date/time, "{score} out of {total} correct", and a % ring (color thresholds: <40% red, <70% orange, <90% blue, ≥90% green). Empty state: icon + "No Quiz History" + "Start a Quiz" CTA.

**Interactions:**
- **Tap a row →** `QuizDetailView`: a sectioned list — "Quiz Summary" (date, score, %) and "Letter Results" (per letter‑pair "paleo → modern" with ✓/✗; alphabetical by key). It does **not** show which wrong answer was picked.
- **Done** (top‑right): dismiss.
- **Clear** (top‑left, only when non‑empty): confirmation alert → wipes `quizHistory` entirely.
- **"Start a Quiz"** (empty state): just dismisses the sheet (does not launch a quiz).

Data source: `@AppStorage("quizHistory")` decoded on appear; decode failure leaves the list empty silently.

---

## 7. Convert tab (`ConverterView`)

**Content:** an editable **input** area (top) and a read‑only **output** area (bottom), separated by a swap button. Direction is `isModernTopaleo` (default modern→paleo). Both fields are RTL (`RTLTextEditor`, a UITextView wrapper). Placeholders differ per direction.

**Live conversion:** every keystroke re‑converts immediately (no debounce). Conversion splits on spaces, maps each char against the `paleoLetters` table, passes unmapped chars through, and rejoins.
- **Modern→Paleo:** maps modern letters (incl. final/sofit forms via `mapFinalLetterToRegular`) to paleo glyphs. Word separator is `·` if "Replace spaces with dots" is on, else a space.
- **Paleo→Modern:** normalizes `· • .` separators to spaces, collapses whitespace, maps paleo→modern; if "Auto‑detect final letters" is on, the last letter of each word becomes its sofit form.

**Interactions:**
- **Swap button:** toggles direction, re‑converts the (now) input into the output, dismisses keyboard, medium haptic. Text is re‑converted in the new direction, not literally moved.
- **Copy result** (shown only when output non‑empty): copies output to clipboard; toast "COPIED"; success haptic; increments `"copyCount"` → **10/30/100** review prompt.
- **Paste** (shown only when clipboard has text): replaces input with clipboard text (re‑converts); light haptic.
- **Clear** (shown only when input non‑empty): empties the input (and output).
- **Done** (toolbar, only while editing): dismisses the keyboard. The Return key inserts a newline; it does not dismiss.
- **"…" options menu** (direction‑dependent): modern→paleo shows "Replace spaces with dots"; paleo→modern shows "Convert dots to spaces" and "Auto‑detect final letters". (Changing a toggle does not re‑convert existing text until the next edit/swap; "Convert dots to spaces" currently has no effect — see Appendix.)

---

## 8. Settings tab (`SettingsView`)

Grouped form, title "Settings". Sections: header, Accent Color, (conditional) Debug Info, Keyboard, About, footer.

**Header:** "Paleo Pro" + tagline, with a `FakeAppIconView`. **Triple‑tap the header** reveals the Debug Info section.

**Accent Color:** horizontal swatches `[teal, blue, neutral, green, orange, pink, purple, red, indigo]`. **Tap a swatch:** saves `selectedAccentColor`, retints the nav bar, and changes the **app icon** to match (`AppIcon-<color>`, teal = default). Medium haptic on a successful icon change; an "Icon Change Failed" alert if unsupported/failed.

**FakeAppIconView (the header icon):** long‑press toggles a jiggle/edit state; drag follows the finger then springs back; while jiggling a delete (–) badge appears. Delete → a joke alert ("LOL — You can't actually delete me", button "Fine"). Context menu: **Delete App** (same joke), **Share App** (shares the App Store URL `…id6743683727`), **Show Debug Menu** (reveals Debug section).

**Keyboard section:** one button.
- If keyboard detected as set up → label "…is Set Up" + green check → opens the **test** sheet.
- If not → "Set Up Paleo Hebrew Keyboard" → opens the **setup** sheet.
- Both present `KeyboardTestView`:
  - 3 steps: **Add Keyboard** (instructions + "Open Keyboard Settings" → opens iOS Settings, then advances after 1s) → **Switch to Paleo Hebrew** (a text field; trouble link resets to step 1) → **Complete** ("Complete" button sets the setup flag and dismisses).
  - On appear, if iOS `AppleKeyboards` contains `com.d7mtg.paleopro`, jumps straight to Complete. Typing a Paleo‑Hebrew‑range character (U+10900–U+1091F) also jumps to Complete.
  - Setup state is read on appear from app‑group suite `group.com.d7mtg.paleopro` key `keyboardHasLaunched`. A `ShowKeyboardTest` notification can open this sheet externally.

**About section:** "More tools like this one" → `https://aleph.d7mtg.com`; "Privacy Policy" → `https://d7mtg.com/privacy`; "Rate Paleo Pro" → App Store write‑review deep link.

**Debug Info (conditional):** shows device/iOS/Info.plist diagnostics + buttons: Test Icon Change (Red), Refresh, Close, Copy Logs to clipboard, Share Logs.

**Footer:** "Designed by D7mtg" → `https://d7mtg.com?utm_…`.

---

## 9. Paleo Pro Keyboard (`KeyboardViewController`, extension)

**Layout:** 3 letter rows (9 keys each) + 1 bottom function row.
- Row 1: ק ר א ט ו ן ם פ + **⌫** (backspace).
- Row 2: ש ד ג כ ע י ח ל ך.
- Row 3: ז ס ב ה נ מ צ ת ץ.
- Final/sofit forms (ך ם ן ץ) reuse the same paleo glyph as their medial forms.

**Letter keys:**
- **Tap:** inserts the **paleo glyph** (always, regardless of mode) via `textDocumentProxy.insertText`. Tap haptic (light) + key‑click sound (1104).
- **Press:** shows a key‑preview popup of the current primary glyph; light haptic.
- **Hint:** each key shows a secondary (other‑script) glyph; a hints toggle exists in code but no button is wired to it.

**Bottom function row (left→right):**
- **Globe / next keyboard:** standard `handleInputModeList` on all touch events — **tap advances** to the next keyboard, **long‑press shows the keyboard list**. Always shown so no device is trapped. *(This was recently added — it fixes the reported "no globe on iPhone SE" bug.)*
- **Mode toggle** (`arrow.up.arrow.down.circle`): switches which script is shown as the **primary** label on every key (paleo‑primary ↔ modern‑primary). Does **not** change what's inserted (still paleo). Medium haptic + sound 1156.
- **Space:** inserts `" "`; light haptic; sound 1104.
- **Return:** inserts `"\n"`; light haptic; sound 1156.
- **Backspace:** tap = delete one char; **long‑press (≥0.4s)** = repeat‑delete every 0.15s until release. Sound 1155.

**Mechanics:** `textInputMode` is forced to Hebrew (he‑IL) for RTL context. Accessibility labels on all keys (letters announce "paleo, modern"; function keys have localized labels). Mode/hint state is in‑memory only (not persisted). The keyboard does **not** write any shared/app‑group flag.

---

## 10. Shared background & data

- **`InteractiveBackgroundView`** (used on the Play splash): a tiled grid of 22 Paleo glyphs with a parallax tilt driven by Core Motion (device gravity, updated 10×/s). Frozen when **Reduce Motion** is on. *(Requires `NSMotionUsageDescription` on device — recently added.)*
- **`PaleoLetter`** = `{paleo, modern, name}`; `paleoLetters` = the 22 letters in alphabetical order (Aleph…Tav).
- **`QuizResult`** = `{id, date, score, total, letterResults: [String:Bool]}`. **`LetterPerformance`** = `{correct, total}`.

---

## Appendix — notable behaviors & quirks

- **`"copyCount"` is shared** across Learn copies, Convert copies, **and** every Play question advance — all three increment the same key, and the App Store review prompt fires at the lifetime totals 10 / 30 / 100. (So gameplay alone can trigger the "rate us" prompt.)
- **Keyboard mode toggle is display‑only:** keys always insert the paleo glyph regardless of which script is shown as primary.
- **Keyboard never sets `keyboardHasLaunched`**, and the code reads it from app‑group suite `group.com.d7mtg.paleopro` while the entitlement declares `group.com.d7mtg.PaleoHebrew` (name mismatch) — so the Settings "is set up" detection via the app group never flips on device. (Settings also detects setup via the `AppleKeyboards` list and via typing a Paleo character, which do work.)
- **Convert:** the "Convert dots to spaces" toggle has no functional effect (dots are always normalized to spaces); toggles don't re‑convert existing text until the next edit.
- **Summary "your answer"** for a wrong question is a heuristic (first non‑correct option), not the actual option tapped — the real selection isn't persisted.
- **`ThemeManager`** defaults the accent to `"blue"` and resolves it as a named asset color, while the app entry defaults to `"teal"` and resolves via system colors — same key, two code paths/defaults.
