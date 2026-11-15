extends RefCounted
## One shared flow; mode-specific copy is resolved from the profile.
const IDS := [
    "arrival", "introduce", "base", "energy", "water",
    "oxygen", "shield", "robot", "construction", "expedition",
    "processing", "repair", "recharge", "missions", "alerts", "letters", "supplies", "upgrades", "science", "settings",
    "cycle", "recovery", "ending", "ready"
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
    "shield": {"text": "tutorial.shield", "hud": true, "target": "resource:escudo"},
    "robot": {"text": "tutorial.robot", "hud": true, "target": "resource:energia_robot"},
    "construction": {"text": "tutorial.construction", "hud": true, "target": "section:construction"},
    "expedition": {"text": "tutorial.expedition", "hud": true, "target": "section:expedition"},
    "processing": {"text": "tutorial.processing", "hud": true, "target": "section:processing"},
    "repair": {"text": "tutorial.repair", "hud": true, "target": "section:repair"},
    "recharge": {"text":"tutorial.recharge","hud":true,"target":"section:rest"},
    "missions": {"text": "tutorial.missions", "hud": true, "target": "section:missions"},
    "upgrades": {"text": "tutorial.upgrades", "hud": true, "target": "section:upgrades"},
    "science": {"text": "tutorial.science", "hud": true, "target": "section:science"},
    "alerts": {"text":"tutorial.alerts","hud":true,"target":"event:alert"},
    "letters": {"text":"tutorial.letters","hud":true,"target":"section:letters"},
    "supplies": {"text":"tutorial.supplies","hud":true,"target":"event:supplies","demo":"supplies"},
    "settings": {"text":"tutorial.settings","hud":true,"target":"event:settings","demo":"settings"},
    "ending": {"text":"tutorial.ending","hud":true,"target":"event:ending","demo":"ending"},
    "cycle": {"text": "tutorial.cycle", "hud": true},
    "recovery": {"text": "tutorial.recovery", "hud": true,"target":"event:recovery","demo":"recovery"},
    "ready": {"text": "tutorial.ready", "hud": true}
}
