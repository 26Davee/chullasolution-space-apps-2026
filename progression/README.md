# progression/

| File | Purpose |
|---|---|
| `mission_manager.gd` | The 16 missions: activation, triggers, completion, failure messages. |
| `run_session.gd` | One expedition: inventory, rewards, Cadet checkpoints, Engineer full restart, saving. |
| `save_manager.gd` | Three save slots in `user://`, with validation and backup recovery. |
| `tech_tree.gd` | Upgrade tree bought with stars. |

Mission and upgrade data live in `data/missions/`. A detailed API guide written during the hackathon is in `docs/team/PROGRESSION_API.md`.
