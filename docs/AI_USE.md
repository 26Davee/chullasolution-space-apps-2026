# Use of AI

NASA Space Apps asks every team to disclose how it used artificial intelligence. This is our full disclosure.

**In short:** the idea, the game design, the target audience, the choice of NASA data and every decision about what goes into the game are the team's. We used AI tools as assistants to write and fix code, to draft and review text, and to generate images. Every AI-generated image shown in the game carries a visible **"AI-generated"** mark. Each team member reviewed and tested what the tools produced.

## AI tools we used

| Tool | Used for | Where it shows up |
|---|---|---|
| **OpenAI Codex** | Code for the 3D models, landing cinematic, lunar terrain and shaders. Code for the interface, tutorial, HUD, translations and UI tests. Integration of the final build. | `assets/3d/`, `world/`, `ui/`, `i18n/`, `ui/tests/`. Logs: `docs/team/registro/puesto-3.md`, `puesto-6.md` |
| **ChatGPT / Codex image generation** | The 7 activity illustrations, Timmy's portrait, the lander and the Moon base image | `assets/ui/` (prompts in `assets/ui/activities/generation.json`) |
| **Google Antigravity (Gemini)** | Writing and proofreading the 16 missions and the science cards for children; balancing upgrade costs; code for missions, upgrades and saving | `data/missions/`, `progression/`. Log: `docs/team/registro/puesto-5.md` |
| **Anthropic Claude (Claude Code)** | Repository setup and planning documents; style guides for the 3D art (`.claude/skills/`); final quality assurance: automated playtests of the full campaign, bug fixes, science fact-checking against NASA sources, web export, fallback fonts and image marks. Commits made with Claude carry a `Co-Authored-By: Claude` line. | `docs/`, `.claude/skills/`, commit `34027c0` |
| **ChatGPT and Claude, before the event** | Planning notes, team presentation and concept images. Concept images were used only as visual reference; they are not in the game. | `assets/3d/revision/` (marked "IA") |

## Images

Every image generated with AI that appears in the game has a visible "AI-generated" mark:

- `assets/ui/activities/`: solar panel, ice processor, oxygen generator, garden, ice map, repair scene, playfield.
- `assets/ui/timmy.png`, `assets/ui/lander.png`, `assets/ui/moon_base.png`.

The 3D models (astronaut, vicuña, modules, terrain) are not AI images: they are built from code inside Godot. That code was written with AI assistance, as listed above. We did not use any image-to-3D service.

## Voices and audio

- **Timmy's voice in the game** is the text-to-speech engine of the player's own operating system (for example Microsoft Zira or Sabina on Windows). The game ships no recorded or AI-generated audio.
- **Trailer narration:** Microsoft Edge neural text-to-speech (voices `en-US-EmmaNeural` and `es-MX-DaliaNeural`).
- **Trailer music:** original music synthesized by a Python script written with Claude. We did not use any music-generation model or any existing piece of music.
- **Trailer video:** recorded from the game itself and edited with scripts written with Claude.

## What the team did

- Chose the problem and the audience: children aged 7–12, with two difficulty modes.
- Designed the game: the Moon base, the three resources, ice trips, solar storms, the 16 missions and Timmy the astronaut vicuña, inspired by the Andean vicuña.
- Chose the NASA data and checked each science card against its source (`docs/DATA_PROVENANCE.md`).
- Reviewed, played and corrected everything the tools produced.

Detailed per-person logs written during the hackathon are in [`docs/team/registro/`](team/registro/).
