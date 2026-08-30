# 🗺️ LDtk Level-Editor Guide & Property-Referenz

Dieses Handbuch ist die vollständige und lückenlose Referenz aller **Eigenschaften**, **Felder (Custom Fields)**, **Enums** und **Layer-Typen**, die du im [LDtk Level-Editor](https://ldtk.io/) anlegen kannst, und wie **mklib** diese vollautomatisch in **HaxeFlixel**, **Nape 2D Physik**, das **GPU-Lighting-System**, den **SaveManager** und das **A* Pathfinding** übersetzt.

---

## 📑 Inhaltsverzeichnis

1. [Architektur & Funktionsweise in mklib](#1-architektur--funktionsweise-in-mklib)
2. [Projektweite Enums (Tags)](#2-projektweite-enums-tags)
3. [Layer-Typen in LDtk](#3-layer-typen-in-ldtk)
4. [Vollständige Entity-Feld-Referenz (Custom Fields)](#4-vollst%C3%A4ndige-entity-feld-referenz-custom-fields)
5. [GPU-Lighting System Felder](#5-gpu-lighting-system-felder)
6. [Benutzerdefinierte Felder im Haxe-Code abfragen](#6-benutzerdefinierte-felder-im-haxe-code-abfragen)
7. [Speichern & Persistenz (IID-System)](#7-speichern--persistenz-iid-system)
8. [Schritt-für-Schritt-Anleitung: Von 0 zum fertigen Level](#8-schritt-f%C3%BCr-schritt-anleitung-von-0-zum-fertigen-level)
9. [Best Practices & Häufige Fehlerquellen](#9-best-practices--h%C3%A4ufige-fehlerquellen)

---

## 1. Architektur & Funktionsweise in mklib

`mklib` baut eine nahtlose Brücke zwischen LDtk-JSON-Leveldaten und HaxeFlixel:

```
┌─────────────────────────────────────────────────────────────┐
│                    LDtk Level Editor                        │
│  - Enum "Tags" (Hero, Solid, Coin...)                       │
│  - Layer "Tiles" (Grafik-Kacheln)                           │
│  - Layer "Entities" (Hero, Platform, Torch, Door...)        │
│  - Layer "Collisions" (IntGrid für Pathfinding)             │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Haxe Macro: Data.hx)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                       mklib Core                            │
│  - State.napeInit()      ──> Registriert LDtk Tags als CbType │
│  - TileLayer             ──> Rendert Grafik-Kacheln schnell │
│  - EntityLayer           ──> Instanziiert Haxe-Klassen      │
│  - LightingSystem        ──> Erzeugt Shader-Lichter aus LDtk│
│  - NavGridBuilder        ──> Erzeugt 2D A* Navigationsgrid  │
│  - SaveManager           ──> Merkt zerstörte Entities (iid) │
└─────────────────────────────────────────────────────────────┘
```

Wenn ein Level in `mklib.state.State` geladen wird:
1. `napeInit()` liest das Enum **`Tags`** aus LDtk und erzeugt automatisch alle Nape-`CbType`-Objekte.
2. `new TileLayer("LayerName")` rendert Kachelebenen direkt via FlxSpriteGroup.
3. `new EntityLayer(data.l_Entities)` durchsucht das Package `entities.*` nach passenden Klassennamen (z. B. Entity `Hero` -> `entities.Hero`).
4. Hat eine Entity physikalische Felder (`Tag`, `Tags`, `TileRect`, `sensor`, `allowMovement`), wird automatisch `EntityNapeSprite` genutzt, sonst das performantere `EntitySprite`.

---

## 2. Projektweite Enums (`Tags`)

In LDtk definierst du unter **Project Settings > Enums** ein Enum mit dem festen Namen **`Tags`**.

### Konfiguration in LDtk:
1. Klicke auf **Project Settings** (Zahnrad-Symbol oben links) -> **Enums**.
2. Erstelle ein neues Enum mit dem Bezeichner: **`Tags`** *(Groß-/Kleinschreibung beachten!)*.
3. Füge Werte für alle gewünschten Kollisions- und Objekttypen deines Spiels hinzu:
   - `Hero` oder `Player`
   - `Solid` oder `Obstacle`
   - `Platform`
   - `Enemy`
   - `Coin` / `Gem` / `Collectible`
   - `Checkpoint`
   - `Door` / `Portal`
   - `Spikes` / `Hazard`
   - `Water`
   - `Ladder`

### Was mklib damit macht:
Beim Aufruf von `napeInit(gx, gy)` oder `addCbTypes()` in deinem `State` iteriert `mklib` über alle Werte des Enums `Tags` und erzeugt für jeden Wert ein Nape-`CbType`.

Im Code kannst du diese Tags überall abfragen:
```haxe
var solidCb:CbType = Tags.get("Solid");
var heroCb:CbType  = Tags.get("Hero");

// Kollision oder Sensor-Listener registrieren:
Listener.addCollisionBeginListener(heroCb, solidCb, onHeroHitWall);
```

---

## 3. Layer-Typen in LDtk

| LDtk Layer-Typ | Empfohlener Name | mklib Klasse | Verwendung & Funktion |
|---|---|---|---|
| **Tiles** oder **AutoLayer** | `Tiles`, `Background`, `Props` | `mklib.layer.TileLayer` | Rendert visuelle Kacheln über die native LDtk-Render-Pipeline in eine performante `FlxSpriteGroup`. |
| **Entities** | `Entities`, `HeroLayer`, `Interactive` | `mklib.layer.EntityLayer` | Instanziiert automatisch HaxeFlixel-Klassen aus dem Package `entities.<EntityIdentifier>`. |
| **IntGrid** | `Collisions`, `Walls`, `Grid` | `mklib.path.NavGridBuilder` | Erzeugt das 2D-Raster für A* Pathfinding (`NavGrid`). Werte `!= 0` gelten als feste Hindernisse. |

### Beispiel im Haxe State (`PlayState.hx`):
```haxe
override public function create():Void {
    super.create();
    napeInit(0, 0); // Schwerkraft 0,0 für Top-Down (oder z. B. 0, 400 für Platformer)

    // 1. Hintergrund- und Kachelebenen
    add(new TileLayer(data.l_Tiles.identifier));
    add(new TileLayer(data.l_Props.identifier));

    // 2. Entity-Ebenen
    add(new EntityLayer(data.l_Entities));
    add(new EntityLayer(data.l_HeroLayer));

    // 3. A* NavGrid aus IntGrid & Layern
    var navGrid = NavGridBuilder.autoBuild(data);

    // 4. Beleuchtung aus LDtk-Entities
    var lighting = new LightingSystem(0xFF101018, 1.5);
    lighting.loadFromLevel(data);
    add(lighting);
}
```

---

## 4. Vollständige Entity-Feld-Referenz (Custom Fields)

Diese Felder kannst du in LDtk unter **Project Settings > Entities > (Entity auswählen) > Fields** anlegen. `mklib` erkennt sie automatisch und initialisiert Grafik, Physik, Sensoren oder Animationen:

| Feldname (Identifier) | LDtk Feldtyp | Zielklasse | Standardwert | Effekt in mklib |
|---|---|---|---|---|
| **`Tag`** | `Enum (Tags)` oder `String` | `EntityNapeSprite`, `EntityLayer` | `null` | Weist dem Nape-Physikkörper der Entity den entsprechenden `CbType` aus dem Enum `Tags` zu. Aktiviert automatisch die Nape-Physik für diese Entity. |
| **`Tags`** | `Array<Enum (Tags)>` oder `Array<String>` | `EntityNapeSprite`, `EntityLayer` | `null` | Weist dem Nape-Körper mehrere `CbType`s gleichzeitig zu (z. B. `["Solid", "Obstacle"]`). |
| **`TileRect`** *(oder `tileRect`)* | `Tile (Single value)` | `EntitySprite`, `EntityNapeSprite`, `EntityLayer` | `null` | Schneidet den im Level ausgewählten Kachelausschnitt exakt aus dem Tileset aus, weist ihn dem Sprite zu und erzeugt bei `EntityNapeSprite` automatisch einen statischen Nape-Körper (`BodyType.STATIC`). |
| **`sensor`** *(oder `sensorEnabled`)* | `Boolean` | `EntityNapeSprite`, `EntityLayer` | `false` | Schaltet alle Shapes des Nape-Körpers auf **Sensor** (`shape.sensorEnabled = true`). Erkennt Kollisionen/Überlappungen in Listenern, ohne physisch abzuprallen oder zu blockieren (z. B. für Münzen, Trigger, Checkpoints). |
| **`allowMovement`** | `Boolean` | `EntityNapeSprite`, `EntityLayer` | `true` | Setzt `body.allowMovement`. Wenn `false`, kann der Physik-Körper durch Impulse oder Gravitation nicht verschoben werden. |
| **`Animations`** *(oder `animations`)* | `String` | `EntitySprite`, `EntityNapeSprite` | `null` | Name des Animations-Schlüssels in `AnimationRegistry.db` (z. B. `"Fire"`, `"Hero"`, `"Water"`). Lädt das Spritesheet und startet die Standardanimation. |
| **`visible`** | `Boolean` | `EntitySprite`, `EntityNapeSprite` | `true` | Schaltet die Sichtbarkeit des Sprites (`sprite.visible`) beim Spawnen um. |
| **`alpha`** | `Float` (0.0 bis 1.0) | `EntitySprite`, `EntityNapeSprite` | `1.0` | Setzt die Deckkraft/Transparenz (`sprite.alpha`) des Sprites. |
| **`iid`** | `String` *(LDtk intern)* | `SaveManager`, alle Entities | UUID | Weltweit eindeutige Instanz-ID aus LDtk. Wird von `SaveManager` genutzt, um aufgesammelte/zerstörte Objekte dauerhaft zu speichern. |

---

## 5. GPU-Lighting System Felder

Das GPU-Shader-Beleuchtungssystem (`mklib.light.LightingSystem`) kann Lichter direkt aus LDtk laden:
- Rufe `lighting.loadFromLevel(data)` oder `lighting.loadFromEntityLayer(data.l_Entities)` auf.
- Alle Entities, deren Bezeichner **`light`**, **`torch`**, **`lamp`**, **`candle`**, **`glow`** oder **`spot`** enthält, oder die mindestens ein Lichtfeld (`type`, `radius` etc.) definieren, werden automatisch instanziiert.

### 💡 Übersicht aller Licht-Felder in LDtk:

| Feldname (Identifier) | Unterstützte Aliasse | LDtk Feldtyp | Standard | Beschreibung |
|---|---|---|---|---|
| **`type`** | `light_type`, `lightType` | `String` oder `Enum` | `"point"` | Typ des Lichts: `point`, `spot`, `torch`, `glow`, `directional`. Wird alternativ aus dem Entity-Namen abgeleitet. |
| **`radius`** | `light_radius`, `Radius` | `Float` | `100.0` | Radius des Lichts in Spiel-Pixeln. |
| **`intensity`** | `light_intensity`, `Intensity` | `Float` | `1.0` | Helligkeits-Multiplikator (z. B. 0.5 für schwaches Licht, 2.0 für starkes Licht). |
| **`falloff`** | `light_falloff`, `Falloff` | `Float` | `1.0` | Helligkeitsabfall-Exponent (1.0 = linearer Abfall, 2.0 = quadratischer Abfall). |
| **`color`** | `light_color`, `Color` | `Color` oder `String` (`#RRGGBB`) | Torch: `#FFAA44`<br>Glow: `#55AAFF`<br>Sonst: `#FFFFFF` | Lichtfarbe. Unterstützt den LDtk-Farbauswähler oder Hex-Strings. |
| **`active`** | `enabled`, `light_active` | `Boolean` | `true` | Schaltet das Licht beim Start ein (`true`) oder aus (`false`). |
| **`offsetX`** / **`offsetY`** | `offset_x`, `offset_y`, `pivotX`, `pivotY` | `Float` | `width/2`, `height/2` | Versatz des Lichtursprungs relativ zur oberen linken Ecke der Entity. |
| **`angle`** | `direction`, `light_angle`, `Angle` | `Float` | `0.0` | Abstrahlwinkel in Grad (für SpotLight und DirectionalLight). 0° = Rechts, 90° = Unten, 180° = Links, 270° = Oben. |
| **`spotAngle`** | `cone`, `coneAngle`, `light_spotAngle` | `Float` | `45.0` | Äußerer Öffnungswinkel des Lichtkegels bei SpotLights (in Grad). |
| **`innerAngle`** | `focusAngle`, `light_innerAngle` | `Float` | `15.0` | Innerer Kernbereich des Lichtkegels mit 100 % Helligkeit (in Grad). |
| **`innerRadius`** | `coreRadius`, `light_innerRadius` | `Float` | `0.0` | Innerer Kern-Radius bei PointLights ohne Abfall (in Pixeln). |
| **`flickerSpeed`** | `speed`, `light_flickerSpeed` | `Float` | `8.0` | Flackergeschwindigkeit bei Fackellichtern (`TorchLight`). |
| **`flickerIntensity`** | `flickerAmount`, `light_flickerIntensity` | `Float` | `0.15` | Stärke der Helligkeitsschwankung beim Flackern (0.0 bis 1.0). |
| **`flickerRadius`** | `light_flickerRadius` | `Float` | `10.0` | Radius-Schwankung beim Flackern (in Pixeln). |
| **`flameJitter`** | `jitter`, `light_flameJitter` | `Float` | `2.0` | Räumliches Zittern der Flammenposition (in Pixeln). |
| **`minRadius`** / **`maxRadius`** | `light_minRadius`, `light_maxRadius` | `Float` | `radius * 0.5`, `radius` | Minimaler und maximaler Radius beim Atmen/Pulsieren von `GlowLight`. |
| **`minIntensity`** / **`maxIntensity`** | `light_minIntensity`, `light_maxIntensity` | `Float` | `intensity * 0.4`, `intensity` | Minimale und maximale Helligkeit bei `GlowLight`. |
| **`pulseSpeed`** | `speed`, `light_pulseSpeed` | `Float` | `2.0` | Pulsier-Geschwindigkeit von `GlowLight`. |
| **`pulsePhase`** | `phase`, `light_pulsePhase` | `Float` | `0.0` | Start-Phasenverschiebung (0.0 bis 6.28), um mehrere Glow-Lichter asynchron atmen zu lassen. |

---

## 6. Benutzerdefinierte Felder im Haxe-Code abfragen

Neben den von mklib standardmäßig interpretierten Feldern kannst du in LDtk beliebige eigene Parameter anlegen (z. B. `hp: Int`, `speed: Float`, `dialogKey: String`, `targetLevel: String`, `isLocked: Bool`, `patrolPath: Array<Point>`).

### Methode 1: Dynamisch mit `getField()` und `hasField()`
Funktioniert in jeder Unterklasse von `EntitySprite` oder `EntityNapeSprite`:

```haxe
package entities;

import mklib.entity.EntitySprite;
import ldtk.Entity;

class Chest extends EntitySprite {
    public var isLocked:Bool = false;
    public var lootItemId:String = "gold_coin";
    public var lootCount:Int = 5;

    public function new(entity:ldtk.Entity) {
        super(entity);

        if (hasField("isLocked")) {
            isLocked = getField("isLocked");
        }
        if (hasField("lootItemId")) {
            lootItemId = getField("lootItemId");
        }
        if (hasField("lootCount")) {
            lootCount = getField("lootCount");
        }
    }
}
```

### Methode 2: Typsicher über das generierte LDtk-Macro
Wenn du das offizielle Haxe LDtk-Makro (`Data.hx`) nutzt:

```haxe
package entities;

import mklib.entity.EntityNapeSprite;
import ldtk.Entity;

class Enemy extends EntityNapeSprite {
    // Typisierte Referenz auf die generierte Entity-Struktur:
    public var _v:Data.Entity_Enemy;

    public function new(entity:ldtk.Entity) {
        super(entity);
        _v = cast entity;

        // Typsicherer Zugriff mit IDE-Autovervollständigung:
        var maxHp:Int = _v.f_hp;
        var moveSpeed:Float = _v.f_speed;
    }
}
```

---

## 7. Speichern & Persistenz (IID-System)

Jede in LDtk platzierte Entity-Instanz besitzt eine unveränderliche, weltweit eindeutige **`iid`** (Instance Identifier, z. B. `e3d4a5b6-7c8d-9e0f-1a2b-3c4d5e6f7a8b`).

### Zerstörte / Aufgesammelte Items merken:
Wenn der Spieler eine Münze, ein Upgrade oder eine Truhe aufsammelt:

```haxe
// In deiner Coin.hx:
public function onCollected():Void {
    markDestroyed(); // Speichert iid im SaveManager und ruft kill() auf
}
```

Wenn der Spieler das Level verlässt und später zurückkehrt:
- `EntityLayer` prüft vor dem Erzeugen jeder Entity automatisch `SaveManager.isEntityDestroyed(entity.iid)`.
- Bereits zerstörte oder aufgesammelte Entities werden **gar nicht erst instanziiert**!

---

## 8. Schritt-für-Schritt-Anleitung: Von 0 zum fertigen Level

Hier ist der komplette Workflow, um ein Level mit Physik, Plattformen, Münzen, Beleuchtung und Gegnern aufzubauen:

### Schritt 1: LDtk Projekt vorbereiten
1. Neues Projekt in LDtk anlegen und z. B. als `assets/levels/world.ldtk` speichern.
2. Unter **Tilesets** dein Tileset-Bild importieren (z. B. `assets/tilesets/tileset.png`, Kachelgröße `16x16`).

### Schritt 2: Enum "Tags" anlegen
1. Klicke auf **Project Settings** -> **Enums**.
2. Erstelle ein Enum mit Namen: **`Tags`**.
3. Füge folgende Werte hinzu:
   - `Hero`
   - `Solid`
   - `Coin`
   - `Hazard`
   - `Checkpoint`

### Schritt 3: Layer anlegen
Lege unter **Layers** folgende 3 Ebenen an (von oben nach unten):
1. **`Entities`** (Typ: *Entities*)
2. **`Tiles`** (Typ: *Tiles* oder *AutoLayer*, gebunden an dein Tileset)
3. **`Collisions`** (Typ: *IntGrid*, Kachelgröße 16x16)

### Schritt 4: Entity-Definitionen anlegen

#### A. Spieler (`Hero`):
- **Identifier:** `Hero`
- **Fields:**
  - `Tag` (Typ: *Enum Tags*, Wert: `Hero`)
  - `speed` (Typ: *Float*, Standard: `120.0`)

#### B. Feste Plattform / Hindernis (`Platform`):
- **Identifier:** `Platform`
- **Fields:**
  - `Tag` (Typ: *Enum Tags*, Wert: `Solid`)
  - `TileRect` (Typ: *Tile - Single value*, erlaubt das Zuweisen beliebiger Kacheln direkt im Level)

#### C. Aufsammelbare Münze (`Coin`):
- **Identifier:** `Coin`
- **Fields:**
  - `Tag` (Typ: *Enum Tags*, Wert: `Coin`)
  - `sensor` (Typ: *Boolean*, Wert: `true`)
  - `Animations` (Typ: *String*, Wert: `"Coin"`)
  - `value` (Typ: *Int*, Wert: `10`)

#### D. Fackel / Lichtquelle (`Torch`):
- **Identifier:** `Torch`
- **Fields:**
  - `type` (Typ: *String*, Wert: `"torch"`)
  - `radius` (Typ: *Float*, Wert: `120.0`)
  - `color` (Typ: *Color*, Wert: `#FFAA44`)
  - `flickerIntensity` (Typ: *Float*, Wert: `0.2`)

---

## 9. Best Practices & Häufige Fehlerquellen

> [!TIP]
> **Enum-Name exakt beachten:**  
> Das Enum in LDtk muss exakt `Tags` heißen (großes **T**, kleines **ags**). `mklib.state.State.addCbTypes()` sucht genau nach dieser Definition.

> [!IMPORTANT]
> **`TileRect` mit Nape STATIC Bodies:**  
> Entities mit dem Feld `TileRect` erzeugen in `EntityNapeSprite` automatisch einen statischen Nape-Körper (`BodyType.STATIC`). Statische Körper blockieren bewegliche dynamische Körper zuverlässig, ohne durch Gravitation nach unten zu fallen.

> [!NOTE]
> **Sensoren vs. Feste Körper:**  
> Wenn du möchtest, dass ein Objekt Trigger-Events auslöst, aber den Spieler **nicht** wegstößt oder blockiert, setze das Feld `sensor: true` oder `sensorEnabled: true`.

> [!WARNING]
> **Klassennamen & Package-Struktur:**  
> `EntityLayer` sucht standardmäßig im Package `entities.*`. Eine Entity mit dem Identifier `Hero` in LDtk muss als Klasse `entities.Hero` (in `source/entities/Hero.hx`) definiert und mit `@:keep` versehen sein, damit der Haxe-Compiler sie nicht durch Dead Code Elimination entfernt.
