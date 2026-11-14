extends RefCounted
## UI-only preview metadata from the supplied files. Never applies mission/upgrade rules.
const PREVIEW = {
    "branches": [
        {
            "id": "energia",
            "upgrades": [
                {
                    "id": "panel_extra",
                    "nivel": 1,
                    "costo": 1,
                    "requisito": null
                },
                {
                    "id": "bateria_modular",
                    "nivel": 2,
                    "costo": 2,
                    "requisito": "panel_extra"
                },
                {
                    "id": "celulas_optimizadas",
                    "nivel": 3,
                    "costo": 3,
                    "requisito": "bateria_modular"
                }
            ]
        },
        {
            "id": "vida",
            "upgrades": [
                {
                    "id": "procesar_rapido",
                    "nivel": 1,
                    "costo": 1,
                    "requisito": null
                },
                {
                    "id": "generador_eficiente",
                    "nivel": 2,
                    "costo": 2,
                    "requisito": "procesar_rapido"
                },
                {
                    "id": "jardin_lunar",
                    "nivel": 3,
                    "costo": 3,
                    "requisito": "generador_eficiente"
                }
            ]
        },
        {
            "id": "escudo",
            "upgrades": [
                {
                    "id": "reparar_barato",
                    "nivel": 1,
                    "costo": 1,
                    "requisito": null
                },
                {
                    "id": "mas_resistencia",
                    "nivel": 2,
                    "costo": 2,
                    "requisito": "reparar_barato"
                },
                {
                    "id": "alerta_temprana",
                    "nivel": 3,
                    "costo": 3,
                    "requisito": "mas_resistencia"
                }
            ]
        },
        {
            "id": "herramientas",
            "upgrades": [
                {
                    "id": "pico_geologico",
                    "nivel": 1,
                    "costo": 1,
                    "requisito": null
                },
                {
                    "id": "taladro_manual",
                    "nivel": 2,
                    "costo": 2,
                    "requisito": "pico_geologico"
                },
                {
                    "id": "taladro_mochila",
                    "nivel": 3,
                    "costo": 3,
                    "requisito": "taladro_manual"
                }
            ]
        }
    ],
    "missions": [
        {
            "id": "mision_01",
            "puntos": {
                "cadete": 1,
                "ingeniero": 1
            }
        },
        {
            "id": "mision_02",
            "puntos": {
                "cadete": 1,
                "ingeniero": 1
            }
        },
        {
            "id": "mision_03",
            "puntos": {
                "cadete": 1,
                "ingeniero": 1
            }
        },
        {
            "id": "mision_04",
            "puntos": {
                "cadete": 1,
                "ingeniero": 1
            }
        },
        {
            "id": "mision_05",
            "puntos": {
                "cadete": 1,
                "ingeniero": 1
            }
        },
        {
            "id": "mision_06",
            "puntos": {
                "cadete": 1,
                "ingeniero": 1
            }
        },
        {
            "id": "mision_07",
            "puntos": {
                "cadete": 2,
                "ingeniero": 2
            }
        },
        {
            "id": "mision_08",
            "puntos": {
                "cadete": 1,
                "ingeniero": 1
            }
        },
        {
            "id": "mision_09",
            "puntos": {
                "cadete": 1,
                "ingeniero": 1
            }
        },
        {
            "id": "mision_10",
            "puntos": {
                "cadete": 2,
                "ingeniero": 2
            }
        },
        {
            "id": "mision_11",
            "puntos": {
                "cadete": 2,
                "ingeniero": 2
            }
        },
        {
            "id": "mision_12",
            "puntos": {
                "cadete": 2,
                "ingeniero": 2
            }
        },
        {
            "id": "mision_13",
            "puntos": {
                "cadete": 2,
                "ingeniero": 2
            }
        },
        {
            "id": "mision_14",
            "puntos": {
                "cadete": 2,
                "ingeniero": 2
            }
        },
        {
            "id": "mision_15",
            "puntos": {
                "cadete": 2,
                "ingeniero": 2
            }
        },
        {
            "id": "mision_16",
            "puntos": {
                "cadete": 2,
                "ingeniero": 2
            }
        }
    ]
}
var upgrades_path := "res://data/missions/arbol_habilidades.json"
var missions_path := "res://data/missions/misiones_listas.json"
var _upgrades: Dictionary = {}
var _missions: Dictionary = {}

func set_data(upgrades: Dictionary, missions: Dictionary) -> void:
    _upgrades = upgrades.duplicate(true)
    _missions = missions.duplicate(true)

func _read(path: String) -> Dictionary:
    if path.is_empty() or not FileAccess.file_exists(path):
        return {}
    var parser := JSON.new()
    var error := parser.parse(FileAccess.get_file_as_string(path).trim_prefix("\uFEFF"))
    if error != OK or not parser.data is Dictionary:
        push_warning("P6 cannot read catalog: " + path)
        return {}
    return parser.data

func upgrades(training: bool) -> Array[Dictionary]:
    var source := _upgrades if not _upgrades.is_empty() else _read(upgrades_path)
    var tree: Dictionary = source.get("arbol_habilidades", {})
    var branches: Array = tree.get("ramas", [])
    var result: Array[Dictionary] = []
    for branch in branches:
        if branch is Dictionary:
            for upgrade in branch.get("mejoras", []):
                if upgrade is Dictionary and not str(upgrade.get("id", "")).is_empty():
                    var item: Dictionary = upgrade.duplicate(true)
                    item["branch"] = str(branch.get("id", ""))
                    result.append(item)
    if result.is_empty() and training:
        for branch in PREVIEW.branches:
            for upgrade in branch.upgrades:
                var item: Dictionary = upgrade.duplicate(true)
                item["branch"] = branch.id
                result.append(item)
    return result

func missions(training: bool) -> Array[Dictionary]:
    var source := _missions if not _missions.is_empty() else _read(missions_path)
    var result: Array[Dictionary] = []
    for mission in source.get("misiones", []):
        if mission is Dictionary and not str(mission.get("id", "")).is_empty():
            result.append(mission.duplicate(true))
    if result.is_empty() and training:
        for mission in PREVIEW.missions:
            result.append(mission.duplicate(true))
    return result

static func text(key: String, fallback := "") -> String:
    var translated: String = TranslationServer.translate(key)
    return fallback if translated == key and not fallback.is_empty() else translated
