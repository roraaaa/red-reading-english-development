# RED — Reading English Development

A Flutter app for building English reading comprehension, starring RED the red
panda. It is meant for students, ESL learners and anyone practising at their own
pace, and for the teachers and tutors who work with them.

- **Assess**: pick Easy / Medium / Hard and get a random topic card (8 cards per
  difficulty). Reading is timed quietly in the background, then the reader
  answers questions without looking back. Results show the score, reading
  time, words per minute, the correct answers, advice based on the skills they
  missed, and a "Save as PDF" option.
- **Materials**: six colour levels, from Green (easiest) to Orange (hardest),
  with 6 topic cards each (never the same topics as Assess). Reading is untimed,
  the story stays on screen while answering, and readers earn up to 3 stars and
  can retry. Every card can be printed or saved as a PDF worksheet.
- **Read-aloud**: uses the device's built-in voice (free, via `flutter_tts`).
  In Materials, **Listen to the story** reads it paragraph by paragraph and
  highlights each word as it is spoken; a player bar keeps Pause/Stop in
  reach. In both Materials and Assess, tapping any word speaks just that word.
  Assess has no full read-aloud, so reading time and speed stay fair.
  Voice quality depends on the device; if no voice is installed the app says
  read-aloud isn't available.
- **Accounts**: readers log in; every attempt is saved to their account and
  shown on the **My progress** screen. The **Account** screen (the circle with
  your initial, on the home screen) holds the privacy policy and a
  "Delete my account" button that removes the account and every saved score.

## Running the app

Flutter is installed at `C:\flutter` (not on PATH), so call it directly:

```bash
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat run -d chrome
```

To run on an Android phone or emulator, install Android Studio (it installs the
Android SDK), then `C:\flutter\bin\flutter.bat run`.

Run the tests (answer grading, scoring, read-aloud, content checks):

```bash
C:\flutter\bin\flutter.bat test
```

## Offline demo mode vs Firebase

Until Firebase is configured the app runs in **offline demo mode**: accounts and
scores are stored on the device only, the stories bundled in the app are used,
and the login screen says so.

To switch on real accounts, cloud-saved scores and cloud-published stories:

1. Create a project at <https://console.firebase.google.com>.
2. **Authentication → Sign-in method**: enable **Email/Password**.
3. **Firestore Database**: create a database.
4. Install the FlutterFire CLI and connect the app (this replaces
   `lib/firebase_options.dart`):
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
5. Publish the security rules in `firestore.rules` (Firestore → Rules → paste →
   Publish). Readers can read and add only their own scores, saved scores
   cannot be edited, and stories can be read but not changed from the app.
6. Publish the stories to Firestore (see below).

Data layout:

| Path | Contents |
| --- | --- |
| `users/{uid}` | Profile |
| `users/{uid}/attempts/{attemptId}` | Saved Assess / Materials results |
| `content/meta` | `version` of the published stories |
| `levels/{levelId}` | Materials colour levels |
| `passages/{passageId}` | Stories (`level`) and assessment cards (`difficulty`) |

## Privacy policy and account deletion

Both app stores require a reachable privacy policy URL and a way to delete an
account from inside the app. RED has both.

- The policy lives in [`docs/index.html`](docs/index.html). The contact address
  on it is also the deletion route for people who have uninstalled the app,
  which Google Play asks for, so that inbox needs watching.
- Publish it with GitHub Pages: **Settings → Pages → Source: Deploy from a
  branch → `main` / `/docs`**. The repository has to be public for Pages on the
  free plan; otherwise put the single file in a small public repository instead.
- Put the resulting URL in `lib/ui/core/app_links.dart`, in the Play Console
  listing and in App Store Connect. The **Account** screen links to it.

**Delete my account** (Account screen) signs the reader in again with their
password, deletes the profile and every saved score, then deletes the account
itself. In offline demo mode it clears the same things from the device.

A saved score still cannot be edited, so a low score can never become a high
one. Deleting is allowed because account deletion needs it; someone using the
Firestore SDK by hand could therefore delete a single score. Closing that last
gap needs a Cloud Function on the Blaze plan that deletes the data server-side
when an account goes.

## Signing a release build

Every build so far has been signed with the throwaway debug key, which is fine
on your own phone and rejected by both stores. To make a real one:

1. Create a keystore **outside this repository** and back it up. Losing it means
   never being able to publish an update to the same app again:
   ```bash
   keytool -genkey -v -keystore C:\Users\<you>\keys\red-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias red
   ```
2. Copy `android/key.properties.example` to `android/key.properties` and fill in
   the path and the two passwords you chose. Both files stay out of git.
3. Build:
   ```bash
   C:\flutter\bin\flutter.bat build appbundle --release
   ```
   The `.aab` lands in `build/app/outputs/bundle/release/` and is what Google
   Play wants. For a file testers can sideload, use
   `C:\flutter\bin\flutter.bat build apk --release --split-per-abi` instead and
   send them the `arm64-v8a` APK.

Without `android/key.properties` the release build still works, but it is signed
with the debug key — useful for testing, never for uploading.

## The red panda logo

Save the logo as `assets/images/red_panda.png` (square, transparent background).
Until then the app draws a placeholder panda.

## Adding or editing stories

The JSON files in `assets/content/` are the master copy of every story:

| File | Contents |
| --- | --- |
| `levels.json` | The colour levels (name, colour, icon, description) |
| `materials/<levelId>.json` | Stories for one level, in display order |
| `assessments/<easy\|medium\|hard>.json` | The random assessment cards |

### 1. Edit the JSON

Each passage has `id`, `title`, `topic`, `icon`, `paragraphs` and `questions`.
Questions are either:

```json
{ "id": "q1", "type": "choice", "skill": "details",
  "prompt": "Mars was named after the Roman god of what?",
  "options": ["Beauty", "War", "The sea"], "answer": 1 }
```

```json
{ "id": "q2", "type": "text", "skill": "details",
  "prompt": "Where is Intramuros located?",
  "accepted": [["manila"], ["philippine", "philippines"]],
  "answerText": "Manila, Philippines" }
```

For typed answers, each inner list in `accepted` is a group of alternatives and
the answer must match one item from **every** group. Grading ignores case,
punctuation, accents and plurals, accepts number words ("two" = "2") and allows
small typos in longer words. `skill` is one of `details`, `vocabulary`,
`mainIdea`, `sequence`, `inference` and decides which advice is shown.
`icon` is one of the names in `lib/ui/core/widgets/app_icons.dart`.

### 2. Check it

```bash
C:\flutter\bin\dart.bat run tool/upload_content.dart --dry-run
```

This checks every level, story and question and uploads nothing. For example,
each typed question's model answer must be accepted by its own keywords, and
assessment topics must stay exclusive: a Materials story whose title shares a
topic word with an assessment card (say, "Mars" in both) is rejected. Common
title words such as "amazing" or "your" are ignored. The check only compares
titles, so still read new stories with a teacher's eye for overlapping topics.

### 3. Publish it

1. Firebase Console → **Project settings → Service accounts → Generate new
   private key**. Save the file somewhere private, e.g.
   `tool\keys\service-account.json`. This key has full access to your Firebase
   project: never share it or commit it (`.gitignore` already excludes it).
2. Run:
   ```bash
   C:\flutter\bin\dart.bat run tool/upload_content.dart --key tool\keys\service-account.json
   ```

The tool refuses to publish if the check fails. Otherwise it uploads all levels
and passages, removes any that were deleted from the JSON, and then bumps
`content/meta.version`.

**How the app picks up changes (no app update needed):** after a reader signs
in, the app checks `content/meta` (at most every 5 minutes), downloads the
stories if a newer version is published, checks them, and caches them on the
device so they also work offline. Pulling down on **My progress** checks
immediately. If nothing has been published, or the device is offline, the app
keeps using its cached or bundled stories. Scores already saved for a deleted
story stay in the reader's history.

## Project structure

```text
lib/
├── data/          services (Firebase, local storage, PDF, speech, content) and repositories
├── domain/        models and use cases (answer grading, scoring, content checks)
├── routing/       go_router routes and the login redirect
└── ui/
    ├── core/      theme, colours and shared widgets (buttons, animations, logo)
    └── features/  splash, auth, home, assess, materials, session, progress
tool/
└── upload_content.dart   checks and publishes assets/content to Firestore
```
