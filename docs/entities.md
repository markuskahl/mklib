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
| `new` | `(entity:ldtk.Entity)` | `Void` | Erstellt eine neue Instanz von `EntitySprite`, setzt Position (`pixelX`, `pixelY`), `width`, `height`, `iid`, bindet den aktuellen `State` und initialisiert `graphicPath` sowie `hasGraphic`. |
| `getGraphicPath` | `()` | `Null<String>` | Ermittelt und normalisiert den Pfad zur Grafikdatei (beginnend mit `assets/`), falls ein Tile in LDtk definiert ist, und setzt `hasGraphic`. |
| `getField` | `(identifier:String)` | `Dynamic` | Liest den Wert eines benutzerdefinierten LDtk-Feldes (`fieldInstances`) aus oder `null`. |
| `hasField` | `(identifier:String)` | `Bool` | Prüft, ob ein benutzerdefiniertes LDtk-Feld für diese Entity existiert. |

### Beispiel: Animierte Feuer-Dekoration (`Fire.hx`) mit `AnimationRegistry`

```haxe
package entities;

import flixel.FlxG;
import mklib.entity.EntitySprite;
import mklib.animation.AnimationTypes.SpriteSheetData;
import mklib.animation.AnimationTypes.AnimationClip;
import AnimationRegistry;
import ldtk.Entity;

@:keep
class Fire extends EntitySprite {
    public function new(entity:ldtk.Entity) {
        super(entity);

        // Animationsdaten aus der Compile-Time-Registry abrufen
        var spritesheetData:SpriteSheetData = AnimationRegistry.db.get(getField("Animations"));
        if (spritesheetData != null) {
            for (clip in spritesheetData.animations) {
                animation.add(clip.name, clip.frames, clip.fps, clip.loop, clip.flipX, clip.flipY);
            }
            animation.play(spritesheetData.defaultAnimation);
        }
    }
}
```

---

## ⚡ `EntityNapeSprite` (`mklib.entity.EntityNapeSprite`)

Erbt von `flixel.addons.nape.FlxNapeSprite` und erweitert dieses um Methoden zur nahtlosen Kopplung an LDtk-Felder, LDtk-Tags (`CbType`), Sensoren und Nape-Schwerpunkte.

### Eigenschaften (Properties)

| Eigenschaft | Typ | Modifizierer | Beschreibung |
| :--- | :--- | :--- | :--- |
| `_entity` | `ldtk.Entity` | `public` | Die zugrundeliegende LDtk-Entity-Instanz mit Rohdaten und Feldern. |
| `iid` | `String` | `public` | Die eindeutige Instanz-ID (IID) der Entity aus LDtk. |
| `state` | `mklib.state.State` | `public` | Referenz auf den aktuellen `mklib.state.State`. |
| `graphicPath` | `Null<String>` | `public` | Der aufgelöste Pfad zur Grafikdatei (beginnend mit `assets/`, z. B. `assets/tilesets/Platform.png`), falls ein Tile zugewiesen ist, sonst `null`. |
| `hasGraphic` | `Bool` | `public` | Gibt an, ob der Entity in LDtk eine gültige Grafikdatei zugewiesen ist (`true`), andernfalls `false`. |
| `body` | `nape.phys.Body` | `public` | *(Ererbt von FlxNapeSprite)* Der physikalische Nape-Körper der Entity. |
| *Ererbte Felder* | `Float`, `Bool` etc. | `public` | Alle Standardfelder von `flixel.addons.nape.FlxNapeSprite` und `flixel.FlxSprite`. |

### Methoden (Methods)

| Methode | Signatur | Rückgabewert | Beschreibung |
| :--- | :--- | :--- | :--- |
| `new` | `(entity:ldtk.Entity)` | `Void` | Erstellt eine neue Instanz von `EntityNapeSprite`, initialisiert `_entity`, `iid`, Position, den `state`, `graphicPath` und `hasGraphic`. |
| `getGraphicPath` | `()` | `Null<String>` | Ermittelt und normalisiert den Pfad zur Grafikdatei (beginnend mit `assets/`), falls ein Tile in LDtk definiert ist. |
| `getField` | `(identifier:String)` | `Dynamic` | Liest den Wert eines benutzerdefinierten LDtk-Feldes (`fieldInstances`) aus oder `null`. |
| `hasField` | `(identifier:String)` | `Bool` | Prüft, ob ein benutzerdefiniertes LDtk-Feld für diese Entity existiert. |
| `sensorEnabled` | `(?enable:Null<Bool>)` | `Void` | Setzt die `sensorEnabled`-Eigenschaft für alle Shapes. Ohne Parameter wird der Wert aus dem LDtk-Feld `"sensorEnabled"` ausgelesen. |
| `addCbType` | `(name:String = null)` | `Void` | Weist dem Nape-Physikkörper (`body`) CbType-Tags zu. Ist `name == null`, werden die Entity-Felder `Tag` bzw. `Tags` aus LDtk automatisch ausgelesen. Setzt zudem `body.userData.instance = this`. |
| `updateShapePosition` | `()` | `Void` | Positioniert den Nape-Körper im Mittelpunkt der LDtk-Entity (`pixelX + width/2`, `pixelY + height/2`), um die Nape-Schwerpunktsausrichtung auszugleichen. |

### Detailerklärung der Methoden

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
