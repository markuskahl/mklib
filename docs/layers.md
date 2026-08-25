# Layer-System (`mklib.layer.*`)

Das Layer-System von `mklib` wandelt Ebenen aus LDtk in darstellbare HaxeFlixel-Gruppen (`FlxSpriteGroup`) um. Es unterteilt sich in Kachelebenen (`TileLayer`) und Entity-Ebenen (`EntityLayer`).

---

## 🧱 `TileLayer`

`mklib.layer.TileLayer` rendert statische oder automatische Kachelebenen (`Layer_Tiles` / `Layer_AutoLayer`) aus deinem LDtk-Projekt.

### API-Definition

```haxe
package mklib.layer;

class TileLayer extends flixel.group.FlxSpriteGroup {
    public var levelName:String;
    public var layerName:String;
    public var state:mklib.state.State;

    public function new(LayerName:String);
    public function render():FlxSpriteGroup;
}
```

### Verwendung

```haxe
// Erzeugt die Kachelebene und rendert sie sofort
var tileLayer = new TileLayer(data.l_Tiles.identifier);
add(tileLayer);

// Bei Bedarf manuell neu rendern:
tileLayer.render();
```

---

## 👾 `EntityLayer`

`mklib.layer.EntityLayer` dient der automatischen Instanziierung von Spielobjekten anhand von LDtk-Entities via Haxe-Reflection.

### API-Definition

```haxe
package mklib.layer;

typedef EntityLayerSource<T = Dynamic> = {
    var identifier:String;
    function getAllUntyped():Array<T>;
}

class EntityLayer extends flixel.group.FlxSpriteGroup {
    public var layerName:String;
    public var packageName:String;
    public var state:mklib.state.State<Dynamic>;

    public function new(layer:EntityLayerSource<Dynamic>, packageName:String = "entities");
    public function addEntities(entities:Array<ldtk.Entity>):Void;
}
```

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

        // 3. Interaktive Objekte (z. B. Schalter, Truhen)
        interactiveLayer = new EntityLayer(data.l_Interactive, "entities.interactive");
        add(interactiveLayer);

        // 4. Spielfiguren & Gegner (z. B. Hero, Slime)
        actorsLayer = new EntityLayer(data.l_Actors, "entities.actors");
        add(actorsLayer);
    }
}
```

> [!WARNING]
> Denke daran, alle Entity-Klassen mit `@:keep` zu versehen, damit sie bei Release-Builds nicht durch Dead-Code-Elimination (DCE) entfernt werden.
