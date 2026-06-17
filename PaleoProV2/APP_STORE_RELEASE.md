# Paleo Pro 2.0 — App Store Release Checklist

## Pre-flight (already done)

- [x] Bundle ID matches V1 (`d7mtg.PaleoHebrew`) → this archive uploads as an **update** to app id 6743683727, not a new listing.
- [x] Keyboard extension bundle matches V1 (`d7mtg.PaleoHebrew.PaleoProKeyboard`).
- [x] App Group matches V1 (`group.com.d7mtg.PaleoHebrew`).
- [x] `MARKETING_VERSION` = **2.0**, `CURRENT_PROJECT_VERSION` = **1**.
- [x] App icon (Icon Composer `paleo-v2.icon`) wired and verified on home screen.
- [x] Build is warning-free, simulator launches all tabs.
- [x] Watch target held for a later release.
- [x] No analytics, no tracking, no third-party SDKs.

## Things only you can do

1. **Resolve the Apple ID issue** — `yitzchok@d7mtg.com` was rejected in Xcode signing earlier. Open **Xcode beta → Settings → Accounts**, sign out and back in. Without this, Archive will fail.
2. **Open the project** at `PaleoProV2/PaleoProV2.xcodeproj` in Xcode beta.
3. **Set the destination to "Any iOS Device (arm64)"**.
4. **Product → Archive**. (~2–4 min.)
5. In the Organizer that opens, click **Distribute App → App Store Connect → Upload**.
6. Open **appstoreconnect.apple.com → My Apps → Paleo Pro → 2.0** (create the 2.0 version if it doesn't auto-appear).
7. Attach the uploaded build, paste in the metadata below, upload screenshots, submit.

## App Store Connect metadata

### Promotional text (170 chars, can change without re-review)
> A full rewrite. New design built for iOS 26 Liquid Glass, a redesigned Paleo Hebrew keyboard, refined Convert and Quiz, and a richer About section.

### Description (replaces the existing 1.x copy)
```
Paleo Pro is a Hebrew learning app for the original script of Lashon HaKodesh — the 22 letters of Paleo-Hebrew, the script of the Bayis Rishon period.

LEARN  Browse all 22 letters in a clean grid or list. Tap a letter to copy the Paleo glyph. Long-press for advanced copy options (Modern, Unicode, HTML entity).

PLAY  A 10-question quiz that alternates direction (modern → paleo, paleo → modern). Track your history, see which letters you've mastered.

CONVERT  Type modern Hebrew, read Paleo. Or paste Paleo and read modern. Options for niqqud removal, word-divider dots, final letter forms, and inscription cleanup.

KEYBOARD  A system-wide Paleo Hebrew keyboard you can switch to in any app. Dual-script keys, native iOS 26 styling, full RTL support.

ABOUT  A rich background on the script — the Siloam Inscription, the Tel Dan Stele, the First Jewish War shekel — with copyable Paleo text samples from each.

Designed by D7mtg.
```

### What's New in 2.0
```
Paleo Pro 2.0 is a full rewrite.

• Redesigned for iOS 26 with Liquid Glass throughout.
• Brand-new Paleo Hebrew keyboard — taller keys, dual-script labels, teal Return.
• Quiz, Convert, and Learn all rebuilt with cleaner animations.
• Richer About section with images and copyable text from real artifacts.
• Faster, smaller, and runs natively on iPad.
```

### Keywords (100 chars total, comma-separated)
```
hebrew,paleo,torah,aleph,script,keyboard,convert,gematria,phoenician,jewish,bible,learn,language
```

### Category
- **Primary:** Education
- **Secondary:** Reference

### Age rating
- 4+ (no restricted content, no user-generated)

### Support URL
- `https://d7mtg.com`  (or a dedicated /paleopro path if you have one)

### Marketing URL (optional)
- `https://aleph.d7mtg.com`

### Privacy policy URL
- `https://d7mtg.com/privacy`

### App Privacy questionnaire
- **Data collected:** None.
- **Tracking:** No.
- Everything stored locally (SwiftData quiz history, UserDefaults preferences). No accounts, no analytics, no third-party SDKs.

## Required screenshots

The new App Store ratings policy requires screenshots for:
- **iPhone 6.9"** (iPhone 17 Pro Max / Air): 3 to 10 shots, 1320×2868
- **iPhone 6.5"** (legacy, still required if your app supported older iPhones): 1242×2688
- **iPad 13"** (iPad Pro M-series): 2048×2732

### Suggested screen list (3–5 is enough)
1. **Learn** — letter grid, dark mode
2. **Play splash** — "Learn Paleo Hebrew" with parallax
3. **Quiz mid-question** — showing the green/red feedback
4. **Convert** — Hebrew on top, Paleo below, copy button visible
5. **Keyboard** — the Paleo keyboard in use over the Convert field

### How to capture
- Boot a sim of the right device (e.g. `iPhone 17 Pro Max`).
- `xcrun simctl io <udid> screenshot path.png` from terminal, OR Cmd+S in Simulator.
- Upload directly in App Store Connect; no marketing frame required.

## After upload, before "Submit for Review"

- [ ] Confirm the build appears under 2.0 in App Store Connect (~10–30 min after upload).
- [ ] Add all required screenshots.
- [ ] Paste description + what's-new + keywords.
- [ ] Answer App Privacy as "no data collected".
- [ ] Export compliance: **No, this app does not use encryption** (we use only system HTTPS for the AsyncImage attribution).
- [ ] Content rights: **No, we have all rights** (Wikimedia images are CC BY-SA, properly attributed in-app).
- [ ] Hit **Submit for Review**.

## Known issues at submission time

- The `yitzchok@d7mtg.com` Apple ID Xcode-signing issue may resurface. If Archive fails:
  - Try signing out and back in (Settings → Accounts).
  - As a last resort, use Xcode 26.0 (stable) instead of 26 beta for the Archive step; the app targets iOS 26.0 so the stable SDK works.
- Build number bump rule: every fresh upload to App Store Connect needs a higher `CURRENT_PROJECT_VERSION` than the previous one *for the same marketing version*. Build 1 is fine for the first 2.0 upload; bump to 2 for the next, etc.
