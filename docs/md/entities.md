# Entities & Spielobjekte (`mklib.entity.*`)

`mklib` stellt zwei spezialisierte Basisklassen für Spielobjekte bereit, die aus einem LDtk-Level instanziiert werden:
1. **`EntitySprite`**: Für rein grafische Sprites ohne Physik (z. B. Partikel, Dekorationen, einfache Items).
2. **`EntityNapeSprite`**: Für physikfähige Spielobjekte mit Nape-Physikkörpern, Formen, Schwerpunktszentrierung und automatischem Tag-Mapping.

---

## 🎨 `EntitySprite` (`mklib.entity.EntitySprite`)

Erbt von `flixel.FlxSprite`. Position (`pixelX`, `pixelY`), Abmessungen (`width`, `height`), Instanz-ID (`iid`) und der Bezug zum aktuellen `State` werden beim Erstellen automatisch synchronisiert.

### Eigenschaften (Properties)

| Eigenschaft | Typ | Modifizierer | Beschreibung |
| :--- | :--- | :--- | :--- |
| `_entity` | `ldtk.Entity` | `public` | Die zugrundeliegende LDtk-Entity-Instanz mit allen Rohdaten, Feldern und Koordinaten. |
| `iid` | `String` | `public` | Die weltweit eindeutige Instanz-ID (IID) der Entity aus dem LDtk-Projekt. |
| `state` | `mklib.state.State` | `public` | Referenz auf den aktuellen `mklib.state.State`, sofern dieser aktiv ist. |
| `graphicPath` | `Null<String>` | `public` | Der aufgelöste Pfad zur Grafikdatei (beginnend mit `assets/`, z. B. `assets/tilesets/Fire.png`), falls ein Tile zugewiesen ist, sonst `null`. |
| `hasGraphic` | `Bool` | `public` | Gibt an, ob der Entity in LDtk eine gültige Grafikdatei zugewiesen ist (`true`), andernfalls `false`. |
| *Ererbte Felder* | `Float`, `Bool` etc. | `public` | Alle Standardfelder von `flixel.FlxSprite` (`x`, `y`, `width`, `height`, `velocity`, `animation`, `angle` etc.). |

### Methoden (Methods)

| Methode | Signatur | Rückgabewert | Beschreibung |
| :--- | :--- | :--- | :--- |
| `new` | `(entity:ldtk.Entity)` | `Void` | Erstellt eine neue Instanz von `EntitySprite`, setzt Position (`pixelX`, `pixelY`), `width`, `height`, `iid`, bindet den aktuellen `State`, initialisiert `graphicPath` sowie `hasGraphic` (inkl. Zuschnitt bei `TileRect`) und startet automatisch Animationen, falls das Feld `"Animations"` (oder `"animations"`) vorhanden ist (überspringt dabei temporäre LDtk-Vorschaukacheln). |
| `resolveTilesetPath` | `(tilesetUid:Int)` | `Null<String>` | Löst den relativen Asset-Pfad einer Tileset-Grafik anhand ihrer UID im LDtk-Projekt auf. |
| `loadTileRectGraphic` | `(path:String, tileX:Int, tileY:Int, tileW:Int, tileH:Int)` | `Void` | Schneidet den angegebenen Bereich aus der Tileset-Textur aus, cacht diesen in `FlxG.bitmap` und weist ihn dem Sprite zu. |
| `getGraphicPath` | `()` | `Null<String>` | Ermittelt und normalisiert den Pfad zur Grafikdatei (beginnend mit `assets/`). Bei vorhandenem `Animations`-Feld wird der tatsächliche Spritesheet-Pfad aus den Animationsdaten bezogen. |
| `getField` | `(identifier:String)` | `Dynamic` | Liest den Wert eines benutzerdefinierten LDtk-Feldes (`fieldInstances`) aus oder `null`. |
| `hasField` | `(identifier:String)` | `Bool` | Prüft, ob ein benutzerdefiniertes LDtk-Feld für diese Entity existiert. |
| `initAnimation` | `(?animKey:String)` | `Void` | Lädt und registriert alle Animationsclips via `AnimationManager` (aus `AnimationRegistry.db` oder `assets/data/animations/`), setzt `graphicPath` und startet die Standardanimation. |

### Beispiel: Animierte Feuer-Dekoration (`Fire.hx`)

Da `EntitySprite` das LDtk-Feld `"Animations"` (Typ `Enum.Animations`) automatisch über den `AnimationManager` auflöst und initialisiert, ist keine manuelle Animationslogik nötig. Im LDtk-Editor wird durch `EntityTile` das Vorschaubild aus `Animations.png` gerendert, während im Spiel nahtlos das animierte Spritesheet läuft:

```haxe
package entities;

import mklib.entity.EntitySprite;
import ldtk.Entity;

@:keep
class Fire extends EntitySprite {
    public function new(entity:ldtk.Entity) {
        // super(entity) liest automatisch das LDtk-Feld "Animations"
        // und lädt das Spritesheet aus assets/data/animations/Fire.json!
        super(entity);
    }
}
```

---

## ⚡ `EntityNapeSprite` (`mklib.entity.EntityNapeSprite`)

Erbt von `flixel.addons.nape.FlxNapeSprite` und erweitert dieses um Methoden zur nahtlosen Kopplung an LDtk-Felder, LDtk-Tags (`CbType`), Single Value Tile-Ausschnitte (`TileRect`), Sensoren und Nape-Schwerpunkte.

### Eigenschaften (Properties)

| Eigenschaft | Typ | Modifizierer | Beschreibung |
| :--- | :--- | :--- | :--- |
| `_entity` | `ldtk.Entity` | `public` | Die zugrundeliegende LDtk-Entity-Instanz mit Rohdaten und Feldern. |
| `iid` | `String` | `public` | Die eindeutige Instanz-ID (IID) der Entity aus LDtk. |
| `state` | `mklib.state.State` | `public` | Referenz auf den aktuellen `mklib.state.State`. |
| `graphicPath` | `Null<String>` | `public` | Der aufgelöste Pfad zur Grafikdatei (beginnend mit `assets/`, z. B. `assets/tilesets/Platform.png`), falls ein Tile oder `TileRect` zugewiesen ist, sonst `null`. |
| `hasGraphic` | `Bool` | `public` | Gibt an, ob der Entity in LDtk eine gültige Grafikdatei zugewiesen ist (`true`), andernfalls `false`. |
| `body` | `nape.phys.Body` | `public` | *(Ererbt von FlxNapeSprite)* Der physikalische Nape-Körper der Entity. |
| `prevBodyX` / `prevBodyY` | `Float` | `public` | Nape-Körperposition vor dem aktuellen Physik-Schritt (für jitterfreie Pixel-Kollisionsauflösung). |
| `lastCollidedObstacle` | `Null<flixel.FlxSprite>` | `public` | Zuletzt berührtes Hindernis für vorausschauende Pixel-Blockade-Prüfungen (`isPixelBlocked`). |
| `facingX` / `facingY` | `Int` | `public` | Aktuelle diskrete Blickrichtung der Entity (-1, 0, 1). |
| `gridSize` | `Int` | `public` | Standard-Rastergröße für Gitterabfragen in Pixeln (Standard: `8`). |
| `recoilTimer` | `Float` | `public` | Verbleibende Rückstoß-Dauer (Recoil / Knockback) in Sekunden. |
| `recoilVx` / `recoilVy` | `Float` | `public` | Aktuelle Rückstoß-Geschwindigkeit in X- bzw. Y-Richtung. |
| *Ererbte Felder* | `Float`, `Bool` etc. | `public` | Alle Standardfelder von `flixel.addons.nape.FlxNapeSprite` und `flixel.FlxSprite`. |

### Methoden (Methods)

| Methode | Signatur | Rückgabewert | Beschreibung |
| :--- | :--- | :--- | :--- |
| `new` | `(entity:ldtk.Entity)` | `Void` | Erstellt eine neue Instanz von `EntityNapeSprite`. Bei Vorhandensein eines nicht-leeren `TileRect`-Feldes wird der Tileset-Ausschnitt geladen, die Größe angepasst, ein statischer Nape-Körper (`BodyType.STATIC`) erzeugt und optional als Sensor konfiguriert. |
| `resolveTilesetPath` | `(tilesetUid:Int)` | `Null<String>` | Löst den relativen Asset-Pfad einer Tileset-Grafik anhand ihrer UID im LDtk-Projekt auf. |
| `loadTileRectGraphic` | `(path:String, tileX:Int, tileY:Int, tileW:Int, tileH:Int)` | `Void` | Schneidet den angegebenen Bereich aus der Tileset-Textur aus, cacht diesen in `FlxG.bitmap` und weist ihn dem Sprite zu. |
| `getGraphicPath` | `()` | `Null<String>` | Ermittelt und normalisiert den Pfad zur Grafikdatei (beginnend mit `assets/`), falls ein Tile oder `TileRect` in LDtk definiert ist. |
| `getField` | `(identifier:String)` | `Dynamic` | Liest den Wert eines benutzerdefinierten LDtk-Feldes (`fieldInstances`) aus oder `null`. |
| `hasField` | `(identifier:String)` | `Bool` | Prüft, ob ein benutzerdefiniertes LDtk-Feld für diese Entity existiert. |
| `sensorEnabled` | `(?enable:Null<Bool>)` | `Void` | Setzt die `sensorEnabled`-Eigenschaft für alle Shapes. Ohne Parameter wird der Wert aus dem LDtk-Feld `"sensor"` bzw. `"sensorEnabled"` ausgelesen. |
| `addCbType` | `(name:String = null)` | `Void` | Weist dem Nape-Physikkörper (`body`) CbType-Tags zu. Ist `name == null`, werden die Entity-Felder `Tag` bzw. `Tags` aus LDtk automatisch ausgelesen. Setzt zudem `body.userData.instance = this`. |
| `updateShapePosition` | `()` | `Void` | Positioniert den Nape-Körper im Mittelpunkt der LDtk-Entity bzw. Sprite-Maße (`pixelX + width/2`, `pixelY + height/2`), um die Nape-Schwerpunktsausrichtung auszugleichen. |
| `createShapesFromGraphic` | `(alphaThreshold:Int = 128, simplify:Float = 1.0, sensor:Bool = false, ?cbType:CbType, clearExisting:Bool = true, cellSizeVal:Float = 1.0)` | `Array<Polygon>` | Erzeugt Nape-Polygon-Shapes vollautomatisch aus der sichtbaren Pixelgrafik des Sprites via Marching Squares / Triangulation. |
| `resolvePixelCollision` | `(obstacle:flixel.FlxSprite)` | `Bool` | Löst eine pixelgenaue Überlappung (`FlxG.pixelPerfectOverlap`) verzögerungsfrei auf (Positionskorrektur, Geschwindigkeitsstopp, Wall-Sliding). Gibt `true` zurück, wenn eine Kollision vorlag. |
| `isPixelBlocked` | `(dirX:Float, dirY:Float)` | `Bool` | Prüft vorausschauend, ob eine Bewegung in die angegebene Richtung zu einer Pixel-Überlappung mit `lastCollidedObstacle` führen würde. |
| `applyRecoil` | `(dirX:Float, dirY:Float, speed:Float = 65, duration:Float = 0.12)` | `Void` | Löst einen physikalischen Rückstoß-Impuls (Recoil / Knockback / Zelda-Bounce) in die angegebene Richtung aus. |
| `isRecoiling` | `()` | `Bool` | Gibt an, ob sich die Entity aktuell in einer aktiven Rückstoß-Phase befindet (`recoilTimer > 0`). |
| `getGridX` | `(gSize:Int = -1, offsetX:Float = 0)` | `Int` | Berechnet die diskrete Raster-Spalte (X) auf Basis der Körperposition und eines optionalen Offsets. |
| `getGridY` | `(gSize:Int = -1, offsetY:Float = 0)` | `Int` | Berechnet die diskrete Raster-Zeile (Y) auf Basis der Körperposition und eines optionalen Fußpunkt-Offsets. |
| `getActiveState` | `()` | `Null<State<Dynamic>>` | Liefert dynamisch und sicher die aktive `State`-Instanz aus der Instanz-Referenz oder `FlxG.state`. |
| `hasEntityAtGrid` | `(cx:Int, cy:Int, ?tags:Dynamic, ?entityClass:Class<Dynamic>, gSize:Int = -1)` | `Bool` | Prüft, ob sich in der Rasterzelle `(cx, cy)` eine Entity mit bestimmtem Tag (String oder Array, z. B. `["Obstacle", "Platform", "Wall", "Solid"]`) oder Klassentyp befindet. |
| `hasObstacleInFacingCell` | `(dirX:Int = 0, dirY:Int = 0, ?tags:Dynamic, gSize:Int = -1, footOffsetY:Float = 0)` | `Bool` | Prüft, ob die Nachbarzelle in Blickrichtung durch ein Hindernis oder eine Wand (`tags == null` prüft standardmäßig `["Obstacle", "Platform", "Wall", "Solid"]`) belegt ist. |
| `onPositionCorrected` | `()` | `Void` | Callback-Hook nach einer Positionskorrektur durch `resolvePixelCollision` (kann in abgeleiteten Klassen überschrieben werden). |
| `getFromInteractor` | `(interactor:nape.phys.Interactor)` | `Null<EntityNapeSprite>` | Statische Hilfsfunktion: Ermittelt die `EntityNapeSprite`-Instanz aus einem Nape-`Interactor` (`userData.obj` oder `userData.instance`). |

### Detailerklärung der Methoden

#### `TileRect` Single Value Tile
Wenn in LDtk ein Single Value Tile-Feld mit dem Bezeichner `"TileRect"` definiert und nicht `null` ist:
- Der Bildausschnitt (`x, y, w, h`) aus dem referenzierten Tileset (`tilesetUid`) wird automatisch als Sprite-Grafik ausgeschnitten und zugewiesen.
- Die Abmessungen (`width`, `height`) der Entity werden exakt auf `tileW` und `tileH` angepasst.
- Es wird automatisch ein fester Nape-Physikkörper (`BodyType.STATIC`) mit den Maßen des Ausschnitts erzeugt.
- Ist zusätzlich ein Feld `sensor: true` oder `sensorEnabled: true` vorhanden, wird der Körper direkt als Sensor initialisiert (`shape.sensorEnabled = true`).

#### `addCbType(name:String = null):Void`
- **Parameter:** `name` *(optional, Standard: `null`)* – Der Name des spezifischen Tags (z. B. `"Player"` oder `"Solid"`).
- **Verhalten:**
  - Wird ein expliziter Name übergeben, wird geprüft, ob im aktuellen `State` ein entsprechender `CbType` existiert, und dieser dem `body.cbTypes`-Set hinzugefügt.
  - Wird `null` übergeben, durchsucht die Methode die LDtk-JSON-Felder (`fieldInstances`) nach Feldern mit Bezeichner `Tag` oder `Tags`. Unterstützt sowohl Einzelfelder (String) als auch Arrays von Tags.
  - Verknüpft `body.userData.instance = this`, sodass in allen Kollisions-Callbacks direkt auf die Haxe-Klasseninstanz zugegriffen werden kann.

#### `updateShapePosition():Void`
- Nape-Shapes besitzen ihren Ankerpunkt standardmäßig im geometrischen Schwerpunkt (Mittelpunkt). Da LDtk Koordinaten an der oberen linken Ecke ausrichtet, verschiebt `updateShapePosition()` die Position des Nape-Körpers exakt auf `(pixelX + width/2, pixelY + height/2)`.

---

## 💡 Code-Beispiele

### 1. Statische Plattform mit Kollision (`Platform.hx`)

```haxe
package entities;

import mklib.entity.EntityNapeSprite;
import flixel.util.FlxColor;
import ldtk.Entity;

@:keep
class Platform extends EntityNapeSprite {
    public function new(entity:ldtk.Entity) {
        super(entity);

        makeGraphic(entity.width, entity.height, FlxColor.RED);
        createRectangularBody(entity.width, entity.height);
        body.allowMovement = false; // Statischer Körper (fällt nicht herunter)

        // Form exakt auf LDtk-Koordinaten zentrieren
        updateShapePosition();

        // Tags aus LDtk-Feldern ("Tag" / "Tags") automatisch übernehmen
        addCbType();
    }
}
```

### 2. Dynamischer Spieler mit Physik & Steuerung (`Hero.hx`)

```haxe
package entities;

import mklib.entity.EntityNapeSprite;
import flixel.util.FlxColor;
import flixel.FlxG;
import ldtk.Entity;

@:keep
class Hero extends EntityNapeSprite {
    public function new(entity:ldtk.Entity) {
        super(entity);

        makeGraphic(entity.width, entity.height, FlxColor.BLUE);
        createRectangularBody(entity.width, entity.height);
        body.allowRotation = false; // Rotation bei Kollisionen sperren

        updateShapePosition();
        addCbType("Player"); // Tag "Player" manuell zuweisen
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.keys.pressed.LEFT) {
            body.velocity.x = -150;
        } else if (FlxG.keys.pressed.RIGHT) {
            body.velocity.x = 150;
        } else {
            body.velocity.x = 0;
        }

        if (FlxG.keys.justPressed.SPACE) {
            body.velocity.y = -200; // Sprungimpuls nach oben
        }
    }
}
```
