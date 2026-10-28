# The Chase: 8-Bit Ultimate Edition — prototype v0.2

Unofficial, unlicensed **early gameplay prototype**, for personal testing. The graphics are original CSS pixel artwork; no television audio, logos, or character likeness artwork is bundled.

## Features
- UK, GSN, ABC, Beat the Chasers, and Chaser Mode menus.
- Separate NES-inspired studio palettes for each format.
- Random Chaser selection; GSN authentic roster contains Mark only.
- UK Bradley-style *original* jokes, not transcripts.
- Save a four-person contestant team (first three used in ABC).
- Extra roster option featuring The Raven and Maverick. Maverick is the mystery sixth Chaser in BTC when that roster is selected.
- Animated intros, trivia Cash Builder, head-to-head, and simplified finals.

## Current limitations
- Not an NES ROM or a full game: Electron desktop application with pixel-art styling.
- Chaser Mode and final rounds remain simplified and not TV-accurate.
- Pixel avatars are generic placeholders, not likenesses.
- No licensed music or video included.
- BTC clocks are turn-based simulations, not actual timed buzzer mechanics.
- 36-question sample database.

## Windows testing
1. Upload the folder to a GitHub repository and enable Actions.
2. The included `.github/workflows/build.yml` packages Windows portable EXE and installer, plus a macOS DMG.
3. Download artifacts from the Actions run.

For local development: install Node.js, run `npm install` and `npm start`. End users of packaged builds do not need Node.js.

**Rights note:** This is a fan concept, not endorsed by ITV or any broadcaster. Free distribution does not guarantee immunity from IP claims.
