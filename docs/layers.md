# Layer-System (`mklib.layer.*`)

Das Layer-System von `mklib` wandelt Ebenen aus LDtk in performante HaxeFlixel-Gruppen (`FlxSpriteGroup`) um. Es unterteilt sich in Kachelebenen (`TileLayer`) und Entity-Ebenen (`EntityLayer`).

---

## 🧱 `TileLayer` (`mklib.layer.TileLayer`)

`TileLayer` erbt von `flixel.group.FlxSpriteGroup` und rendert statische Kachel- (`Layer_Tiles`) oder automatische Ebenen (`Layer_AutoLayer`) aus deinem LDtk-Projekt direkt in die Spielwelt.

### Eigenschaften (Properties)

| Eigenschaft | Typ | Modifizierer | Beschreibung |
| :--- | :--- | :--- | :--- |
| `levelName` | `String` | `public` | Der Name des aktiven LDtk-Levels (z. B. `"Level_0"`). |
| `layerName` | `String` | `public` | Der Bezeichner des LDtk-Tile-Layers (z. B. `"Tiles"`, `"Background"`). |
| `state` | `mklib.state.State` | `public` | Referenz auf den aktuellen `mklib.state.State`. |
| *Ererbte Felder* | `Float`, `Array` etc. | `public` | Alle Eigenschaften von `flixel.group.FlxSpriteGroup` (`x`, `y`, `members`, `length`, `visible`, `alpha`, `camera`, `scrollFactor` etc.). |

### Methoden (Methods)

| Methode | Signatur | Rückgabewert | Beschreibung |
| :--- | :--- | :--- | :--- |
| `new` | `(LayerName:String)` | `Void` | Erstellt einen neuen `TileLayer`, übernimmt den aktuellen State/Levelnamen, setzt `layerName` und führt sofort `render()` aus. |
| `render` | `()` | `flixel.group.FlxSpriteGroup` | Leert die Gruppe (`clear()`), löst den Layer anhand von `layerName` aus `state.data` auf und zeichnet alle Kacheln neu. Gibt `this` zurück (Fluent Interface). |

### Code-Beispiel

```haxe
// Erzeugt die Kachelebene und rendert sie sofort
var tileLayer = new TileLayer(data.l_Tiles.identifier);
add(tileLayer);

// Bei Bedarf zur Laufzeit manuell neu rendern:
tileLayer.render();
```

---

## 👾 `EntityLayer` (`mklib.layer.EntityLayer`)

`EntityLayer` erbt von `flixel.group.FlxSpriteGroup` und dient der automatischen Instanziierung von Spielobjekten anhand von LDtk-Entities via Haxe-Reflection.

### Typedef: `EntityLayerSource<T = Dynamic>`

Struktureller Typ für LDtk-Entity-Layer-Quellen:

| Feld | Typ | Beschreibung |
| :--- | :--- | :--- |
| `identifier` | `String` | Der Layer-Bezeichner (z. B. `"Entities"`, `"Interactive"`, `"Actors"`). |
| `getAllUntyped` | `() -> Array<T>` | Methode, die alle Entities des Layers als ungetyptes Array zurückgibt. |

### Eigenschaften (Properties)

| Eigenschaft | Typ | Modifizierer | Beschreibung |
| :--- | :--- | :--- | :--- |
| `layerName` | `String` | `public` | Der Bezeichner des LDtk-Entity-Layers aus dem Editor. |
| `packageName` | `String` | `public` | Das Haxe-Package, in dem nach passenden Entity-Klassen gesucht wird (Standard: `"entities"`). |
| `state` | `mklib.state.State<Dynamic>` | `public` | Referenz auf den aktuellen `mklib.state.State`. |
| *Ererbte Felder* | `Float`, `Array` etc. | `public` | Alle Eigenschaften von `flixel.group.FlxSpriteGroup` (`members`, `length`, `x`, `y` etc.). |

### Methoden (Methods)

| Methode | Signatur | Rückgabewert | Beschreibung |
| :--- | :--- | :--- | :--- |
| `new` | `(layer:EntityLayerSource<Dynamic>, packageName:String = "entities")` | `Void` | Erstellt einen neuen `EntityLayer`, setzt `packageName`, bindet den `state`, liest alle Entities aus `layer.getAllUntyped()` aus und ruft `addEntities()` auf. |
| `addEntities` | `(entities:Array<ldtk.Entity>)` | `Void` | Durchläuft das Entity-Array, ermittelt für jede Entity per Reflection die passende Klasse (`packageName.EntityName`), instanziiert sie mit `[entity]` als Konstruktor-Argument und fügt sie dieser Gruppe hinzu (`add()`). |

### Wie funktioniert das automatische Mapping?

1. `EntityLayer` liest alle Entities aus der übergebenen LDtk-Quelle (z. B. `data.l_Entities` oder `data.l_Interactive`).
2. Für jede Entity wird der Bezeichner (`entity.identifier`) ermittelt, z. B. `"Hero"`, `"Platform"`, `"Coin"`.
3. Zusammen mit dem `packageName` (Standard: `"entities"`) wird der vollqualifizierte Klassenname gebildet:
   - `Hero` -> `entities.Hero`
   - `Platform` -> `entities.Platform`
4. Über `Type.resolveClass()` und `Type.createInstance(cls, [entity])` wird eine neue Instanz der Klasse erzeugt und der `FlxSpriteGroup` hinzugefügt.

---

## 💡 Code-Beispiel: Mehrere Layer trennen

In komplexeren Spielen kannst du deine Ebenen in LDtk strukturieren und in HaxeFlixel separat verwalten (z. B. für Z-Ordering oder Parallax):

```haxe
package;

import mklib.state.State;
import mklib.layer.TileLayer;
import mklib.layer.EntityLayer;

class PlayState extends State<Data.Data_Level> {
    public var bgLayer:TileLayer;
    public var solidLayer:TileLayer;
    public var interactiveLayer:EntityLayer;
    public var actorsLayer:EntityLayer;

    override public function create():Void {
        super.create();
        napeInit(0, 300);

        // 1. Hintergrund-Kacheln (liegt ganz hinten)
        bgLayer = new TileLayer(data.l_Background.identifier);
        add(bgLayer);

        // 2. Feste Level-Kacheln
        solidLayer = new TileLayer(data.l_Tiles.identifier);
        add(solidLayer);

        // 3. Interaktive Objekte (z. B. Schalter, Truhen) im Package "entities.interactive"
        interactiveLayer = new EntityLayer(data.l_Interactive, "entities.interactive");
        add(interactiveLayer);

        // 4. Spielfiguren & Gegner (z. B. Hero, Slime) im Package "entities.actors"
        actorsLayer = new EntityLayer(data.l_Actors, "entities.actors");
        add(actorsLayer);
    }
}
```

> [!WARNING]
> Denke daran, alle Entity-Klassen mit `@:keep` zu versehen, damit sie bei Release-Builds nicht durch Dead-Code-Elimination (DCE) entfernt werden.
