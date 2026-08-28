# Animationssystem & Makros (`mklib.animation.*` & `mklib.macro.*`)

`mklib` enthält ein automatisiertes, makro-basiertes Animationssystem zur schnellen und typsicheren Einbindung von Spritesheet-Animationen. JSON-Animationsdefinitionen werden zur Compile-Zeit eingelesen, normalisiert und in eine globale typisierte `Map<String, SpriteSheetData>` kompiliert – ohne manuelles Parsen zur Laufzeit.

---

## 🏗️ Architektur & Funktionsweise

```mermaid
graph LR
    JSON[assets/data/animations/*.json] -->|Zur Compile-Zeit| Macro[AnimationBuilder.buildDatabase]
    Macro -->|Generiertes Map-Literal| Registry[AnimationRegistry.db]
    Registry -->|Typsicherer Zugriff| Entity[EntitySprite / Fire.hx]
    Entity -->|Flixel Animation| Display[HaxeFlixel Animation Controller]
```

1. **JSON-Animationsdateien** definieren Kachelgrößen, Bilddateipfade und Animationsclips.
2. **`AnimationBuilder.buildDatabase`** liest zur Compile-Zeit alle `.json`-Dateien aus dem Projektverzeichnis, bereinigt absolute Pfade in relative `assets/...`-Pfade und baut eine vorkompilierte `Map`.
3. **`AnimationRegistry.db`** stellt alle geladenen `SpriteSheetData`-Objekte zur Laufzeit blitzschnell zur Verfügung.
4. **Entities** wie `Fire.hx` rufen ihre Animationsdaten über das LDtk-Feld (`getField("Animations")`) aus der Registry ab und weisen sie Flixel zu.

---

## 📄 JSON-Dateiformat (`assets/data/animations/*.json`)

Jede Animationsdatei beschreibt ein Spritesheet und beliebig viele Animationsphasen:

```json
{
  "imagePath": "C:\\Users\\...\\assets\\tilesets\\Fire.png",
  "config": {
    "width": 16,
    "height": 16,
    "spacing": 0,
    "margin": 0
  },
  "animations": [
    {
      "name": "burn",
      "fps": 10,
      "loop": true,
      "flipX": false,
      "flipY": false,
      "frames": [0, 1, 2, 3]
    }
  ],
  "defaultAnimation": "burn"
}
```

> [!NOTE]
> Das Makro `AnimationBuilder` wandelt absolute Pfade in `imagePath` automatisch in relative Pfade beginnend mit `assets/` um.

---

## 🧩 Datenstrukturen (`mklib.animation.AnimationTypes`)

### 1. `FrameConfig`
Beschreibt das Kachel-Layout des Spritesheets.

| Eigenschaft | Typ | Optional | Beschreibung |
| :--- | :--- | :--- | :--- |
| `width` | `Int` | Nein | Breite eines einzelnen Frames in Pixeln. |
| `height` | `Int` | Nein | Höhe eines einzelnen Frames in Pixeln. |
| `spacing` | `Int` | Ja | Abstand zwischen benachbarten Frames in Pixeln (Standard: `0`). |
| `margin` | `Int` | Ja | Äußerer Rand des Spritesheets in Pixeln (Standard: `0`). |

### 2. `AnimationClip`
Definiert einen konkreten Animationsablauf.

| Eigenschaft | Typ | Optional | Beschreibung |
| :--- | :--- | :--- | :--- |
| `name` | `String` | Nein | Eindeutiger Bezeichner des Clips (z. B. `"burn"`, `"idle"`, `"walk"`). |
| `fps` | `Int` | Nein | Abspielgeschwindigkeit in Frames pro Sekunde. |
| `loop` | `Bool` | Nein | Gibt an, ob die Animation in Endlosschleife läuft. |
| `flipX` | `Bool` | Nein | Horizontale Spiegelung der Frames. |
| `flipY` | `Bool` | Nein | Vertikale Spiegelung der Frames. |
| `frames` | `Array<Int>` | Nein | Array der Frame-Indizes auf dem Spritesheet. |

### 3. `SpriteSheetData`
Vollständiger Datensatz eines animierten Spritesheets.

| Eigenschaft | Typ | Optional | Beschreibung |
| :--- | :--- | :--- | :--- |
| `imagePath` | `String` | Nein | Normalisierter Asset-Pfad zur Bilddatei (z. B. `"assets/tilesets/Fire.png"`). |
| `config` | `FrameConfig` | Nein | Kachel- und Rastereinstellungen des Spritesheets. |
| `animations` | `Array<AnimationClip>` | Nein | Liste aller definierten Clips. |
| `defaultAnimation` | `String` | Nein | Name der Standardanimation, die direkt abgespielt werden soll. |

---

## ⚙️ Makro-Kompilierung (`mklib.macro.AnimationBuilder`)

### Methoden

| Methode | Signatur | Rückgabewert | Beschreibung |
| :--- | :--- | :--- | :--- |
| `buildDatabase` | `(folderPath:String):Expr` | `Expr` *(Makro)* | Scannt das Verzeichnis zur Compile-Zeit nach `.json`-Dateien, parst die Daten und erzeugt ein typisiertes `Map<String, SpriteSheetData>`-Literal. Der Schlüssel entspricht dem Dateinamen ohne Erweiterung (z. B. `"Fire"`). |

### Setup der `AnimationRegistry` (`source/AnimationRegistry.hx`)

```haxe
package;

import mklib.animation.AnimationTypes;
import mklib.macro.AnimationBuilder;

class AnimationRegistry {
    // Liest alle JSON-Dateien aus "assets/data/animations" zur Compile-Zeit ein
    public static var db:Map<String, SpriteSheetData> = AnimationBuilder.buildDatabase("assets/data/animations");
}
```

---

## 🎮 Entity-Integration & Verwendung

### 1. LDtk-Workflow: Das Enum `Animations` (Best Practice)

Um Tippfehler im Level-Editor zu vermeiden, empfiehlt sich in LDtk folgende Vorgehensweise:

1. **Enum anlegen:** In LDtk unter *Project Settings &rarr; Enums* ein Enum namens `Animations` erstellen. Als Werte die Namen der Animationsdateien eintragen (z. B. `Fire`, `Hero`, `Platform`).
2. **Entity-Feld definieren:** Bei der Entity-Definition ein Custom Field namens `Animations` vom Typ `Enum.Animations` anlegen.
3. **Im Level zuweisen:** Beim Platzieren der Entity im Level-Editor einfach die gewünschte Animation aus dem Dropdown-Menü auswählen.

> [!NOTE]
> `EntitySprite` und `EntityNapeSprite` prüfen im Konstruktor automatisch mit `hasField("Animations")`, lesen den Wert als String aus und initialisieren die passenden Animationen direkt aus `AnimationRegistry.db`.

### 2. Automatisch im Code (`source/entities/Fire.hx`)

```haxe
package entities;

import mklib.entity.EntitySprite;
import ldtk.Entity;

/**
 * Visuelle animierte Feuer-Dekoration, die von EntitySprite erbt.
 */
@:keep
class Fire extends EntitySprite {
    public function new(entity:ldtk.Entity) {
        // super(entity) liest automatisch das LDtk-Enum-Feld "Animations"
        // und lädt die Clips aus AnimationRegistry.db!
        super(entity);
    }
}
```

### 3. Manuelles Laden / Wechseln auf Entities


`initAnimation(?animKey:String)` kann jederzeit manuell aufgerufen werden:

```haxe
// Manuelles Laden / Wechseln der Animationen:
myEntity.initAnimation("Fire");

// Clip manuell wechseln:
myEntity.animation.play("burn");
```

### 3. Direkter Zugriff auf die Rohdaten (`AnimationRegistry.db`)

Für eigene Flixel-Sprites oder benutzerdefinierte Logik kann direkt auf die vorkompilierte Map zugegriffen werden:

```haxe
import AnimationRegistry;

var fireData = AnimationRegistry.db.get("Fire");
if (fireData != null) {
    trace("Grafikpfad: " + fireData.imagePath);          // "assets/tilesets/Fire.png"
    trace("Frame-Breite: " + fireData.config.width);     // 16
    trace("Standard-Clip: " + fireData.defaultAnimation); // "burn"
}
```

