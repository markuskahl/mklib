# Entities & Spielobjekte (`mklib.entity.*`)

`mklib` bietet zwei Basisklassen für Spielobjekte, die aus LDtk geladen werden:
1. **`EntitySprite`**: Für rein grafische Sprites ohne Physik (z. B. Partikel, Dekorationen, einfache Gegner).
2. **`EntityNapeSprite`**: Für physikfähige Spielobjekte mit Nape-Physikkörpern, Formen und automatischen Tags.

---

## 🎨 `EntitySprite`

Erbt von `flixel.FlxSprite`. Position (`pixelX`, `pixelY`), Abmessungen (`width`, `height`), Instanz-ID (`iid`) und der Bezug zum aktuellen `State` werden automatisch zugewiesen.

### API-Definition

```haxe
package mklib.entity;

class EntitySprite extends flixel.FlxSprite {
    public var _entity:ldtk.Entity;
    public var iid:String;
    public var state:mklib.state.State;

    public function new(entity:ldtk.Entity);
}
```

### Beispiel: Animierte Feuer-Dekoration

```haxe
package entities;

import flixel.FlxG;
import mklib.entity.EntitySprite;
import ldtk.Entity;

@:keep
class Fire extends EntitySprite {
    public function new(entity:ldtk.Entity) {
        super(entity);

        loadGraphic("assets/tilesets/Fire.png", true, 16, 16);
        animation.add("burn", [0, 1, 2, 3], 12);
        animation.play("burn");
    }
}
```

---

## ⚡ `EntityNapeSprite`

Erbt von `flixel.addons.nape.FlxNapeSprite` und erweitert dieses um Methoden zur Integration mit LDtk-Feldern und -Tags.

### API-Definition

```haxe
package mklib.entity;

class EntityNapeSprite extends flixel.addons.nape.FlxNapeSprite {
    public var _entity:ldtk.Entity;
    public var iid:String;
    public var state:mklib.state.State;

    public function new(entity:ldtk.Entity);
    public function addCbType(name:String = null):Void;
    public function updateShapePosition():Void;
}
```

### Wichtige Methoden im Detail

- **`addCbType(?name:String)`**:
  - Wenn `name` angegeben ist: Fügt den spezifischen Tag (z. B. `"Solid"`) zum Nape-Körper hinzu.
  - Wenn `name == null`: Durchsucht die LDtk-JSON-Felder der Entity nach einem Feld namens `Tag` oder `Tags` (Array oder Einzelfeld) und fügt alle passenden `CbType`-Instanzen automatisch hinzu.
  - Setzt außerdem `body.userData.instance = this`, sodass in Kollisions-Callbacks direkt auf das Haxe-Objekt zugegriffen werden kann.

- **`updateShapePosition()`**:
  - Setzt die Position des Nape-Körpers auf den Mittelpunkt der LDtk-Entity (`pixelX + width/2`, `pixelY + height/2`). Dies ist notwendig, da Nape-Körper standardmäßig im Schwerpunkt verankert sind.

---

## 💡 Code-Beispiel: Plattform & Spieler mit Nape

### Statische Plattform (`Platform.hx`)

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
        body.allowMovement = false; // Statischer Körper

        // Form exakt auf LDtk-Koordinaten zentrieren
        updateShapePosition();

        // Tags aus LDtk-Feldern ("Tag" / "Tags") automatisch übernehmen
        addCbType();
    }
}
```

### Dynamischer Spieler (`Hero.hx`)

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
        body.allowRotation = false;

        updateShapePosition();
        addCbType("Player"); // Explizit Tag "Player" zuweisen
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
            body.velocity.y = -200; // Sprung
        }
    }
}
```
