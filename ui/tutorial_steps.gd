extends RefCounted
## One shared flow; mode-specific copy is resolved from the profile.
const IDS := [
    "arrival", "introduce", "name", "age", "base", "energy", "water",
    "oxygen", "health", "shield", "construction", "expedition",
    "processing", "repair", "missions", "upgrades", "science",
    "cycle", "recovery", "ready"
]
const DEFINITIONS := {
    "arrival": {"text": "v2.arrival", "typewriter": true},
    "introduce": {"text": "v2.introduce", "typewriter": true},
    "name": {"text": "v2.name", "input": "nickname"},
    "age": {"text": "tutorial.age", "input": "age"},
    "base": {"text": "tutorial.base", "hud": true},
    "energy": {"text": "tutorial.energy", "hud": true, "target": "resource:energia"},
    "water": {"text": "tutorial.water", "hud": true, "target": "resource:agua"},
    "oxygen": {"text": "tutorial.oxygen", "hud": true, "target": "resource:oxigeno"},
    "health": {"text": "tutorial.health", "hud": true, "target": "resource:vida"},
    "shield": {"text": "tutorial.shield", "hud": true, "target": "resource:escudo"},
    "construction": {"text": "tutorial.construction", "hud": true, "target": "section:construction"},
    "expedition": {"text": "tutorial.expedition", "hud": true, "target": "section:expedition"},
    "processing": {"text": "tutorial.processing", "hud": true, "target": "section:processing"},
    "repair": {"text": "tutorial.repair", "hud": true, "target": "section:repair"},
    "missions": {"text": "tutorial.missions", "hud": true, "target": "section:missions"},
    "upgrades": {"text": "tutorial.upgrades", "hud": true, "target": "section:upgrades"},
    "science": {"text": "tutorial.science", "hud": true, "target": "section:science"},
    "cycle": {"text": "tutorial.cycle", "hud": true},
    "recovery": {"text": "tutorial.recovery.{mode}", "hud": true},
    "ready": {"text": "tutorial.ready", "hud": true}
}
