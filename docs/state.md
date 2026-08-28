# State-Management (`mklib.state.State`)

Die Klasse `mklib.state.State<TLevel>` ist das Herzstück deiner Spielzustände in `mklib`. Sie erweitert `flixel.FlxState` und verbindet dein LDtk-Projekt mit dem HaxeFlixel-Lebenszyklus und der Nape-Physik-Engine.

---

## 🎮 `State<TLevel>` (`mklib.state.State`)

### Klassendefinition
```haxe
class State<TLevel = Dynamic> extends flixel.FlxState
```
*Typparameter `TLevel`:* Der Typ der Leveldaten aus dem Macro `Data` (z. B. `Data.Data_Level`).

---

### Eigenschaften (Properties)

| Eigenschaft | Typ | Modifizierer | Beschreibung |
| :--- | :--- | :--- | :--- |
| `project` | `ldtk.Project` | `public` | Die geladene LDtk-Projektinstanz (wird aus `Data` oder per Argument bezogen). |
| `tags` | `Map<String, nape.callbacks.CbType>` | `public` | Eine Map aller registrierten Kollisionstags aus dem LDtk-Enum `"Tags"` auf ihre Nape-`CbType`-Instanzen. |
| `levelName` | `String` | `public` | Der Name des aktuell aktiven Levels (z. B. `"Level_0"`). |
| `data` | `TLevel` | `public` | Die typisierten Leveldaten des aktiven Levels (mit direktem Zugriff auf `l_Tiles`, `l_Entities` etc.). |
| *Ererbte Felder* | `Float`, `Bool` etc. | `public` | Alle Standardeigenschaften von `flixel.FlxState` und `flixel.group.FlxGroup` (`members`, `length`, `subState`, `camera` etc.). |

---

### Methoden (Methods)

| Methode | Signatur | Rückgabewert | Beschreibung |
| :--- | :--- | :--- | :--- |
| `new` | `(LevelName:String = "Level_0", ?projectInstance:ldtk.Project)` | `Void` | Erstellt einen neuen State, instanziiert das LDtk-Projekt (falls `projectInstance == null`, via Reflection aus `Data`) und lädt das angegebene Level in `data`. |
| `create` | `()` | `Void` | Initialisiert den State (`FlxState.create()`). |
| `napeInit` | `(gx:Int, gy:Int)` | `Void` | Initialisiert den Nape-Physikraum (`FlxNapeSpace.init()`), setzt die globale Schwerkraft auf `(gx, gy)` und ruft `addCbTypes()` auf. |
| `addCbTypes` | `()` | `Void` | Liest das Enum `"Tags"` aus den JSON-Daten des LDtk-Projekts aus und erzeugt für jeden Wert einen `CbType` in der `tags`-Map. |
| `update` | `(elapsed:Float)` | `Void` | Haupt-Update-Schleife des States. Schaltet zudem die Maus auf Windows sichtbar und auf HTML5 unsichtbar. |
| `destroy` | `()` | `Void` | Wird bei `FlxG.switchState` automatisch aufgerufen. Leert den Nape-Physikraum (`FlxNapeSpace.space`), entfernt alle Nape-Listener, leert die `tags`-Map und setzt `project` & `data` auf `null`. |

---

## ⚙️ Funktionsweise im Detail

### 1. Typisierter Level-Zugriff (`data`)
Beim Instanziieren des States wird das LDtk-Projekt aufgelöst. Wenn kein eigenes `projectInstance` übergeben wird, sucht `State` per Reflection nach der Standardklasse `Data`.

Das angegebene Level (`levelName`, z. B. `"Level_0"` oder `"World_Level_1"`) wird geladen und steht in der Eigenschaft `data` typisiert zur Verfügung:

```haxe
class PlayState extends State<Data.Data_Level> {
    override public function create() {
        super.create();

        // Direkter Zugriff auf LDtk-Layer und Entities:
        trace("Levelbreite (Pixel): " + data.pxWid);
        trace("Kachelebene: " + data.l_Tiles.identifier);
    }
}
```

### 2. Nape-Physik initialisieren (`napeInit`)
Die Methode `napeInit(gx, gy)` führt alle notwendigen Schritte zur Vorbereitung des Nape-Physikraums aus:
- Startet `FlxNapeSpace.init()`
- Setzt die globale Schwerkraft (z. B. `gx = 0, gy = 300` für Platformer)
- Ruft intern `addCbTypes()` auf, um Kollisionstags zu registrieren

```haxe
// Initialisiert die Physik mit Schwerkraft nach unten
napeInit(0, 300);
```

### 3. Automatische CbTypes aus LDtk-Enums (`addCbTypes`)
In LDtk kannst du ein Enum mit dem Namen `"Tags"` anlegen (z. B. mit Werten `Player`, `Solid`, `Enemy`, `Coin`, `Hazard`).
`State.addCbTypes()` liest dieses Enum automatisch aus und erstellt für jeden Enum-Wert eine entsprechende `nape.callbacks.CbType`-Instanz in der `tags`-Map.

Diese CbTypes können später bequem über `mklib.tools.Tags.get("Player")` oder `mklib.physic.Listener` referenziert werden.

### 4. Automatischer Speicher-Cleanup (`destroy`)
Beim State-Wechsel über `FlxG.switchState(...)` ruft HaxeFlixel automatisch `destroy()` auf dem bisherigen State auf.

Die `destroy()`-Methode in `State.hx` garantiert, dass dabei auch native Nape-Physikressourcen und Projekt-Referenzen vollständig gelöscht werden:

```haxe
override function destroy():Void {
    if (FlxNapeSpace.space != null) {
        FlxNapeSpace.space.listeners.clear(); // Löscht alle Kollisions-Listener
        FlxNapeSpace.space.clear();           // Löscht alle Körper, Constraints & Shapes
    }

    if (tags != null) {
        tags.clear();
        tags = null;
    }

    project = null;
    data = null;

    super.destroy(); // HaxeFlixel räumt Sprites und SubStates auf
}
```

---

## 💻 Code-Beispiel: Level-Wechsel

```haxe
package;

import flixel.FlxG;
import mklib.state.State;
import mklib.layer.TileLayer;
import mklib.layer.EntityLayer;

class LevelState extends State<Data.Data_Level> {
    public function new(nextLevel:String = "Level_0") {
        super(nextLevel);
    }

    override public function create():Void {
        super.create();
        napeInit(0, 300);

        add(new TileLayer(data.l_Tiles.identifier));
        add(new EntityLayer(data.l_Entities));
    }

    public function goToNextLevel():Void {
        // Wechselt zu Level_1 (FlxG.switchState ruft automatisch destroy() auf!)
        FlxG.switchState(new LevelState("Level_1"));
    }
}
```
