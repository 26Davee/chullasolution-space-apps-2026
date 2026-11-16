# Use of AI

## Team authorship

Killawasi is a student project created by the six members of ChullaSolution. The team chose the challenge and audience, designed the gameplay and mission structure, selected the NASA science references, created the characters and visual direction, and developed the project collaboratively. AI tools did not create the game as a whole or make the team's final design decisions.

The team used AI as a development aid for some code and integration work, debugging and review, editing or translating selected text, and generating several marked illustrations. Team members directed the work, reviewed and revised the results, and tested the version they published. The per-person logs link to the relevant files and describe the checks performed.

## Tools and assistance

| Tool | Assistance provided | Team review and project areas |
|---|---|---|
| **OpenAI Codex** | Helped with selected implementation and integration tasks, debugging, interface refinements, documentation, and automated playtest support. | Team members decided what to keep and reviewed the changes. See `docs/team/registro/puesto-3.md` and `puesto-6.md`. |
| **Google Antigravity (Gemini)** | Helped review and refine child-friendly mission and science text, consider upgrade balance, and assist with selected progression code. | The mission author checked the factual framing, wording, balance, and automated results. See `docs/team/registro/puesto-5.md`. |
| **Anthropic Claude** | Assisted with some planning and documentation, visual-guideline material, quality checks, and scripts used during trailer production. | Claude is an AI tool, not a ChullaSolution teammate or project owner. The team reviewed the resulting materials. |
| **ChatGPT image generation** | Generated seven activity illustrations and the portrait, lander, and Moon-base images listed below. | Team members chose where to use the images and marked them visibly as AI-generated. |

## Images

The AI-generated images included in the game are marked **"AI-generated"**:

- `assets/ui/activities/`: seven activity illustrations for the solar panel, ice processor, oxygen generator, garden, ice map, repair scene, and playfield.
- `assets/ui/timmy.png`, `assets/ui/lander.png`, and `assets/ui/moon_base.png`.

The team created the original 3D models and scenes inside Godot. AI-assisted code work is documented in the individual logs; no image-to-3D service was used. Earlier concept images in `assets/3d/revision/` served as references and are not game assets.

## Audio and trailer

- In-game character speech uses the player's operating-system text-to-speech voices. The game does not include recorded or AI-generated voice files.
- Trailer narration uses Microsoft Edge neural text-to-speech (`en-US-EmmaNeural` and `es-MX-DaliaNeural`).
- The trailer music was synthesized with a Python script developed with Claude assistance; no music-generation model or pre-existing song was used. The trailer footage was captured from the game and edited with helper scripts.

## Human review

Team members selected and shaped the game, chose what NASA science to teach, reviewed AI-assisted material, corrected issues, and tested the playable build. This document records AI as a set of tools used during that team process, separate from the six human team members listed in the [README](../README.md).

Detailed per-person logs of AI use, third-party material, and NASA data are in [`docs/team/registro/`](team/registro/).
