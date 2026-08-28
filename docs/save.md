# Save- & Persistence-System (`mklib.save.*`)

Das Modul **`mklib.save`** bietet ein plattformübergreifendes, leichtgewichtiges und flexibles Persistenzsystem für HaxeFlixel- und LDtk-Spiele. Es verbindet automatische Zustandserfassung für Entities, Multi-Level-Session-Caching (ideal für Metroidvanias und offene Welten), globale Key-Value-Speicher und persistente Checkpoints via `FlxSave`.

---

## 💾 Überblick der Klassen & Schnittstellen

| Modul / Typ | Zweck |
| :--- | :--- |
| **`mklib.save.SaveManager`** | Statische Fassade zur Steuerung von Checkpoints, Multi-Level-Caching, Entity-Tracking und globalen Werten. |
| **`mklib.save.ISaveable`** | Interface für Entities und Spielobjekte zur Definition eigener `saveState()`- und `loadState()`-Logik. |
| **`mklib.save.SaveData`** | Typdefinitionen für `CheckpointMeta`, `LevelSaveState`, `SaveProfile` und `SaveConfig`. |

---

## 🕹️ `SaveManager` (`mklib.save.SaveManager`)

Die statische Fassade `SaveManager` ist der zentrale Einstiegspunkt für alle Speicher- und Ladeoperationen.

### Eigenschaften (Properties)

| Eigenschaft | Typ | Standard | Beschreibung |
| :--- | :--- | :--- | :--- |
| `config` | `SaveConfig` | `{ saveName: "mklib_save", obfuscate: false, salt: "..." }` | Konfiguration für Speichernamen und Verschleierung. |
| `playTime` | `Float` | `0.0` | Akkumulierte Gesamtspielzeit in Sekunden. |
| `globals` | `Map<String, Dynamic>` | `new Map()` | Globale spielübergreifende Variablen (Flags, Inventar, Highscores). |
| `levelStates` | `Map<String, LevelSaveState>` | `new Map()` | Session-Cache aller besuchten Level im RAM. |
| `lastCheckpointMeta` | `Null<CheckpointMeta>` | `null` | Metadaten des zuletzt geladenen oder erstellten Checkpoints. |
| `onSave` | `Null<CheckpointMeta -> Void>` | `null` | Optionaler Callback nach erfolgreicher Checkpoint-Speicherung. |
| `onLoad` | `Null<CheckpointMeta -> Void>` | `null` | Optionaler Callback nach erfolgreichem Laden eines Checkpoints. |

---

### Methoden (Methods)

#### Checkpoint-Verwaltung
```haxe
// Speichert den aktuellen Zustand (Globals, besuchtes Level & Session-Cache) als Checkpoint
SaveManager.saveCheckpoint(?customMeta:Dynamic, ?targetState:State<Dynamic>):Bool;

// Lädt den gespeicherten Checkpoint und stellt alle Daten wieder her
SaveManager.loadCheckpoint():Bool;

// Prüft, ob ein gespeicherter Checkpoint auf dem Gerät/Browser existiert
SaveManager.hasCheckpoint():Bool;

// Löscht den persistenten Checkpoint
SaveManager.clearCheckpoint():Void;

// Ruft die Metadaten des Checkpoints ab (Timestamp, Spielzeit, Level-Name etc.)
SaveManager.getCheckpointMeta():Null<CheckpointMeta>;
```

#### Globale Key-Value-Datenbank
```haxe
// Setzt eine globale Variable
SaveManager.setGlobal("gold", 250);
SaveManager.setGlobal("hasDoubleJump", true);

// Liest eine globale Variable typisiert aus
var gold:Int = SaveManager.getGlobal("gold", 0);
var hasDJ:Bool = SaveManager.getGlobal("hasDoubleJump", false);

// Prüft und entfernt Schlüssel
if (SaveManager.hasGlobal("boss_defeated")) { ... }
SaveManager.removeGlobal("temp_flag");
```

#### Entity-IID & Zerstörungs-Tracking
```haxe
// Markiert eine LDtk-Entity (über ihre IID) als zerstört/aufgesammelt
SaveManager.markEntityDestroyed(entity.iid);

// Prüft, ob eine Entity im aktiven oder angegebenen Level als zerstört vermerkt ist
var isGone:Bool = SaveManager.isEntityDestroyed(entity.iid);

// Speichert oder liest benutzerdefinierte Zustandsdaten für eine spezifische IID
SaveManager.setEntityData(entity.iid, { health: 50, phase: 2 });
var data = SaveManager.getEntityData(entity.iid);
```

---

## 🧩 Das `ISaveable`-Interface

Um benutzerdefinierten Zustand (z. B. verbleibende HP, Zustand von Hebeln, Dialog-Fortschritte) automatisch speichern zu lassen, implementieren Entities das Interface `ISaveable`:

```haxe
package entities;

import mklib.entity.EntitySprite;
import mklib.save.ISaveable;

class Chest extends EntitySprite implements ISaveable {
    public var isOpened:Bool = false;

    public function saveState():Dynamic {
        return {
            isOpened: this.isOpened
        };
    }

    public function loadState(data:Dynamic):Void {
        if (data != null && data.isOpened != null) {
            this.isOpened = data.isOpened;
            if (this.isOpened) {
                animation.play("open_idle");
            }
        }
    }

    public function open():Void {
        if (!isOpened) {
            isOpened = true;
            animation.play("open");
            // Optional: Speichert Zerstörung/Einmaligkeit direkt
            // markDestroyed(false);
        }
    }
}
```

---

## 🔄 Automatisches Zerstörungs-Tracking (`markDestroyed`)

In `EntitySprite` und `EntityNapeSprite` steht die Hilfsmethode `markDestroyed()` zur Verfügung:

```haxe
class Coin extends EntityNapeSprite {
    public function collect():Void {
        // Markiert die Münze im SaveManager als zerstört und ruft sofort kill() auf:
        markDestroyed(true);
    }
}
```

Wenn der Spieler den Raum verlässt und später zurückkehrt, filtert `EntityLayer` diese Münze anhand ihrer LDtk-`iid` automatisch heraus, sodass sie **nicht erneut gespawnt** wird!

---

## 🗺️ Multi-Level Session-Caching (Metroidvania-Support)

`mklib.state.State` synchronisiert Level-Zustände automatisch:

1. **Beim Betreten (`create`)**: `SaveManager.restoreLevel(this)` stellt alle gespeicherten Entity-Zustände für das aktive Level wieder her.
2. **Beim Verlassen (`destroy`)**: `SaveManager.captureLevel(this)` speichert alle `ISaveable`-Entities im RAM-Session-Cache ab.
3. **Beim Checkpoint (`saveCheckpoint`)**: Der gesamte Session-Cache aller bisher besuchten Level wird zusammen in `FlxSave` geschrieben.

Möchtest du die automatische Persistenz für einen bestimmten State deaktivieren (z. B. Hauptmenü), setze einfach:
```haxe
autoPersistLevel = false;
```

---

## 🔒 Datenverschleierung (Obfuscation)

Um einfache Manipulationen von Savegame-Dateien im `LocalStorage` oder Dateisystem zu verhindern, kann die integrierte XOR/Base64-Verschleierung aktiviert werden:

```haxe
SaveManager.config.obfuscate = true;
SaveManager.config.salt = "mein_geheimes_spiel_salt_2026";
SaveManager.config.saveName = "mein_spiel_save";
```

---

## 🚀 Praxisbeispiel: Vollständiger Spielablauf

```haxe
package;

import flixel.FlxG;
import mklib.state.State;
import mklib.layer.TileLayer;
import mklib.layer.EntityLayer;
import mklib.save.SaveManager;

class PlayState extends State<Data.Data_Level> {
    override public function create():Void {
        super.create(); // Stellt automatisch Level-Zustände wieder her

        napeInit(0, 400);

        // Kacheln & Entities laden (zerstörte Entities werden übersprungen!)
        add(new TileLayer(data.l_Tiles.identifier));
        add(new EntityLayer(data.l_Entities));

        // Globales Gold anzeigen
        var gold:Int = SaveManager.getGlobal("gold", 0);
        trace('Aktuelles Gold: $gold');
    }

    public function onReachCheckpoint():Void {
        // Checkpoint mit Metadaten anlegen
        var success = SaveManager.saveCheckpoint({ chapter: 1, difficulty: "Normal" });
        if (success) {
            trace("Checkpoint gespeichert!");
        }
    }
}
```
