# GPU-Shader-Lighting-System (`mklib.light.*`)

Das **GPU-Shader-Lighting-System** von `mklib` bietet eine extrem performante, hardwarebeschleunigte 2D-Echtzeitbeleuchtung und **dynamische 2D-Raymarching-Schatten** für HaxeFlixel. Es berechnet bis zu 32 dynamische Lichter gleichzeitig auf der GPU in einem einzigen Shader-Pass, unterstützt sanfte Dämpfungskurven, Lichtkegel, Fackelflackern sowie Raycast-Schattenwürfe an Hindernissen (`TileLayer`, `FlxSpriteGroup`, `FlxSprite`, Klassen).

Zusätzlich können Lichter **direkt im LDtk Level-Editor** über benutzerdefinierte Felder (Custom Properties) definiert und vollautomatisch instanziiert werden.

---

## 🌟 Features & Highlights

- **⚡ Hardwarebeschleunigter GPU-Shader**: Alle Lichter werden parallel auf der Grafikkarte mit glatten Hermite-Kurven (`smoothstep`) und Exponential-Dämpfung gerendert.
- **🌑 Dynamische 2D-Raycast-Schatten (Occlusion Shadows)**:
  - Licht prallt an Kacheln, Wänden und Spielfiguren ab und wirft dynamische Schatten.
  - Hindernisse können als `TileLayer`, `FlxSpriteGroup`, `FlxSprite`, `FlxTypedGroup` oder als `Class<FlxBasic>` übergeben werden.
  - Einstellbare Abtastpräzision (`shadowSteps`) und Halbschatten/Weichzeichnung (`shadowSoftness`).
- **🎯 5 Spezialisierte Licht-Typen**:
  - `PointLight`: Omnidirektionales 360°-Punktlicht mit anpassbarem 100%-Helligkeitskern (`innerRadius`).
  - `SpotLight`: Gerichteter Scheinwerfer mit Abstrahlwinkel, Kegelweite und weichem Randübergang (`innerAngle`).
  - `TorchLight`: Realistisches Fackelfeuer mit organischer Multi-Wellen-Oszillation und Flammendocht-Verschiebung (`flameJitter`).
  - `GlowLight`: Sanft pulsierende/atmende Magie- und Aura-Lichter mit einstellbaren Min/Max-Bereichen.
  - `DirectionalLight`: Globales Umgebungs-, Sonnen- oder Mondlicht mit konfigurierbarem Einfallswinkel.
- **🚀 Automatisches Frustum- / Viewport-Culling**: In großen Welten mit hunderten Lichtern werden pro Frame nur die aktuell im Kamerabereich sichtbaren Lichter an die GPU übergeben – für konstante 60+ FPS.
- **🧲 Zielverfolgung (`follow`)**: Lichter können an beliebige Spielfiguren oder Sprites gebunden werden (`light.follow(player, 0, 0)`).
- **🗺️ Volle LDtk-Integration**: Automatische Erkennung und Konfiguration aus LDtk-Level-Entities über Custom Properties.

---

## 🏛️ Klassen- und Typenübersicht

| Klasse / Typ | Erbt von | Beschreibung |
| :--- | :--- | :--- |
| `LightingSystem` | `FlxSprite` | Zentraler Manager und Renderer. Verwaltet Lichter, Schatten-Occluder, Culling, Shader-Uniforms und LDtk-Import. |
| `Light` | `IFlxDestroyable` | Abstrakte Basisklasse aller Lichtquellen mit Position, Radius, Farbe, Intensität und Verfolgung. |
| `PointLight` | `Light` | 360°-Punktlicht mit innerem Kern (`innerRadius`). |
| `SpotLight` | `Light` | Scheinwerferkegel mit `angle`, `spotAngle`, `innerAngle`, `pointAt()` und `lookAt()`. |
| `TorchLight` | `Light` | Fackellicht mit `flickerSpeed`, `flickerIntensity`, `flickerRadius` und `flameJitter`. |
| `GlowLight` | `Light` | Pulsierendes Magielicht mit `minRadius`, `maxRadius`, `minIntensity`, `maxIntensity`, `pulseSpeed`. |
| `DirectionalLight` | `Light` | Globales Sonnen- und Mondlicht mit `directionAngle`. |
| `LightType` | `enum abstract` | Enum der Lichtarten (`POINT`, `SPOT`, `TORCH`, `GLOW`, `DIRECTIONAL`). |
| `LightingShader` | `FlxShader` | Der GLSL-Multi-Light Fragment-Shader mit integriertem 2D-Raymarching für Schatten. |

---

## 🚀 Schnelleinstieg & Code-Beispiele

### 1. Grundlegendes Setup mit 2D-Raycast-Schatten

```haxe
package;

import mklib.state.State;
import mklib.layer.TileLayer;
import mklib.light.LightingSystem;

class PlayState extends State<Data.Data_Level> {
    public var tileLayer:TileLayer;
    public var lighting:LightingSystem;

    override public function create():Void {
        super.create();

        // 1. TileLayer für Level-Wände erstellen
        tileLayer = new TileLayer(data.l_Tiles.identifier);
        add(tileLayer);

        // 2. LightingSystem mit Hindernissen für 2D-Raycast-Schatten initialisieren
        lighting = new LightingSystem(0xFF141424, 0.2, [tileLayer]);

        // Optionale Schatten-Konfiguration:
        lighting.shadowSteps = 32;       // Raymarching-Schritte (4-64, Standard: 32)
        lighting.shadowSoftness = 0.3;    // Weiche Schattenkanten (Standard: 0.0)

        // 3. Fackellicht erstellen (wirft Schatten an Level-Wänden)
        var torch = lighting.createTorchLight(100, 100, 140, 0xFFFFAA44, 1.0);

        // 4. Scheinwerfer erstellen
        var spot = lighting.createSpotLight(200, 80, 180, 90, 50, 0xFFFFFFFF);

        // 5. Overlay zur Szene hinzufügen
        add(lighting);
    }
}
```

### 2. Schattenwerfer dynamisch registrieren

```haxe
// Ganze TileLayer oder SpriteGroups als Hindernisse:
lighting.addOccluder(tileLayer);
lighting.addOccluder(enemiesGroup);

// Oder nach Klassen filtern (sucht alle Instanzen in der Szene):
lighting.addOccluderClass(Wall);
```

### 3. Licht an Spielerfigur binden

```haxe
// Fackel folgt der Spielerfigur automatisch auf Schritt und Tritt
var playerTorch = lighting.createTorchLight(0, 0, 130, 0xFFFF9933, 1.1);
playerTorch.follow(playerSprite, 0, 0, true);
```

### 4. Scheinwerfer auf Mauszeiger oder Zielobjekt ausrichten

```haxe
// In der update()-Schleife: Scheinwerfer folgt der Maus
spot.lookAt(enemy);
// oder:
spot.pointAt(FlxG.mouse.x, FlxG.mouse.y);
```

---

## 🗺️ LDtk Custom-Properties (Editor-Steuerung)

In LDtk kannst du Licht-Entities (z. B. Entity `Light`, `Torch`, `SpotLight`, `Candle` oder jede Spielfigur) anlegen und deren Eigenschaften direkt über **Custom Fields** steuern.

`LightingSystem.loadFromLevel(data)` oder `LightingSystem.fromEntity(entity)` liest diese Felder automatisch aus:

| LDtk-Feldname | Datentyp | Betroffene Lichter | Beschreibung & Standardwert |
| :--- | :--- | :--- | :--- |
| `type` / `light_type` | `String` / `Enum` | Alle | `"point"`, `"spot"`, `"torch"`, `"glow"`, `"directional"` (Wird sonst aus Entity-Identifier abgeleitet) |
| `radius` / `light_radius` | `Float` / `Int` | Alle (außer Directional) | Licht-Radius in Pixeln (Standard: `100.0`) |
| `color` / `light_color` | `Color` / `Int` / `Hex` | Alle | Farbe des Lichts (Standard: Weiß `0xFFFFFFFF` bzw. Fackel `0xFFFFAA44`) |
| `intensity` / `light_intensity` | `Float` | Alle | Helligkeit (Standard: `1.0`) |
| `falloff` / `light_falloff` | `Float` | Alle | Dämpfungsexponent (Standard: `1.0` für weiche Kante) |
| `innerRadius` | `Float` | `PointLight` | Radius für 100% Leuchtkraft vor Beginn der Dämpfung (Standard: `0.0`) |
| `angle` / `direction` | `Float` | `SpotLight`, `Directional` | Abstrahlwinkel in Grad (0° = rechts, 90° = unten, Standard: `0.0`) |
| `spotAngle` / `coneAngle` | `Float` | `SpotLight` | Gesamtöffnungswinkel des Strahls in Grad (Standard: `45.0`) |
| `innerAngle` | `Float` | `SpotLight` | Innerer Fokuswinkel für sanfte Strahlränder (Standard: `15.0`) |
| `flickerSpeed` / `speed` | `Float` | `TorchLight` | Frequenz des Flackerns in Hz (Standard: `8.0`) |
| `flickerIntensity` | `Float` | `TorchLight` | Helligkeits-Schwankung der Flamme (Standard: `0.15`) |
| `flickerRadius` | `Float` | `TorchLight` | Radius-Schwankung in Pixeln (Standard: `10.0`) |
| `flameJitter` | `Float` | `TorchLight` | Docht-Wobble / Positionsverschiebung der Flamme (Standard: `2.0`) |
| `minRadius` / `maxRadius` | `Float` | `GlowLight` | Minimaler und maximaler Radius beim Pulsieren |
| `minIntensity` / `maxIntensity` | `Float` | `GlowLight` | Minimale und maximale Helligkeit beim Pulsieren |
| `pulseSpeed` | `Float` | `GlowLight` | Geschwindigkeit des Pulsierens (Standard: `2.0`) |
| `pulsePhase` | `Float` | `GlowLight` | Phasenverschiebung in Radiant für asynchrone Kristalle (Standard: `0.0`) |
| `active` / `enabled` | `Bool` | Alle | Ob das Licht initial aktiv ist (Standard: `true`) |
| `offsetX` / `offsetY` | `Float` | Alle | Versatz relativ zur Entity-Position (Standard: Entity-Mitte) |

---

## ⚙️ Detaillierte API-Referenz

### `mklib.light.LightingSystem`

#### Eigenschaften

| Eigenschaft | Typ | Standard | Beschreibung |
| :--- | :--- | :--- | :--- |
| `ambientColor` | `FlxColor` | `0xFF141424` | Grundfarbe der Dunkelheit / Umgebung. |
| `ambientIntensity` | `Float` | `0.2` | Grundhelligkeit der Umgebung (0.0 = stockdunkel, 1.0 = hell). |
| `autoCull` | `Bool` | `true` | Aktiviert automatisches Frustum-Culling für maximale GPU-Performance. |
| `shadowsEnabled` | `Bool` | `false` | Aktiviert Raycast-Schattenwürfe (automatisch `true`, sobald Occluder vorhanden sind). |
| `shadowSteps` | `Int` | `32` | Raymarching-Abtastschritte entlang jedes Lichtstrahls (4–64). |
| `shadowSoftness` | `Float` | `0.0` | Weichzeichnung der Schattenkanten / Halbschatten (Penumbra). |
| `occluders` | `Array<Dynamic>` | `[]` | Liste registrierter Hindernisse/Klassen für Schatten. |
| `lights` | `Array<Light>` | `[]` | Liste aller registrierten Lichtquellen. |
| `shaderInstance` | `LightingShader` | – | Die aktive Shader-Instanz auf der GPU. |

#### Methoden

| Methode | Rückgabe | Beschreibung |
| :--- | :--- | :--- |
| `new(ambientColor, ambientIntensity, ?occluders)` | `Void` | Erstellt das Lighting-System mit optionalen Schatten-Occludern. |
| `addOccluder(occluder)` | `Dynamic` | Fügt ein Hindernis (`TileLayer`, Sprite, Gruppe, Klasse) hinzu und aktiviert Schatten. |
| `addOccluders(list)` | `Void` | Fügt eine Liste von Hindernissen hinzu. |
| `addOccluderClass(cl)` | `Void` | Registriert eine Klasse (z. B. `Wall`) als Schattenwerfer. |
| `removeOccluder(occluder)` | `Dynamic` | Entfernt ein registriertes Hindernis. |
| `removeOccluderClass(cl)` | `Void` | Entfernt eine registrierte Klasse. |
| `clearOccluders()` | `Void` | Leert alle Schattenwerfer. |
| `addLight(light)` | `T` | Registriert ein Licht und gibt es zurück. |
| `removeLight(light, destroy)` | `T` | Entfernt ein Licht. |
| `clearLights(destroy)` | `Void` | Entfernt alle registrierten Lichter. |
| `createPointLight(...)` | `PointLight` | Erstellt und registriert ein `PointLight`. |
| `createSpotLight(...)` | `SpotLight` | Erstellt und registriert ein `SpotLight`. |
| `createTorchLight(...)` | `TorchLight` | Erstellt und registriert ein `TorchLight`. |
| `createGlowLight(...)` | `GlowLight` | Erstellt und registriert ein `GlowLight`. |
| `createDirectionalLight(...)` | `DirectionalLight` | Erstellt und registriert ein `DirectionalLight`. |
| `loadFromLevel(levelData)` | `Int` | Lädt alle Lichter aus einem LDtk-Level-Objekt. |
| `loadFromEntityLayer(layerSource)` | `Int` | Lädt alle Lichter aus einem bestimmten LDtk-Entity-Layer. |
| `fromEntity(entity)` | `Null<Light>` | Parst eine einzelne LDtk-Entity anhand ihrer Felder. |

---

### `mklib.light.Light` (Basisklasse)

#### Eigenschaften & Methoden

| Eigenschaft / Methode | Typ / Signatur | Beschreibung |
| :--- | :--- | :--- |
| `x`, `y` | `Float` | Weltposition der Lichtquelle in Pixeln. |
| `radius` | `Float` | Radius des Lichts in Pixeln. |
| `color` | `FlxColor` | Farbe des Lichts. |
| `intensity` | `Float` | Helligkeit / Multiplikator. |
| `falloff` | `Float` | Dämpfungskurve (1.0 = sanfter Standardabfall). |
| `active` | `Bool` | Steuert, ob das Licht aktualisiert wird. |
| `visible` | `Bool` | Steuert, ob das Licht gerendert wird. |
| `follow(target, offsetX, offsetY, center)` | `Light` | Bindet das Licht an ein `FlxObject` / `EntitySprite`. |
| `stopFollowing()` | `Light` | Löst die Bindung an das Zielobjekt. |
| `setPosition(x, y)` | `Light` | Setzt die Position manuell. |
| `setColor(color, intensity)` | `Light` | Setzt Farbe und Intensität. |
| `destroy()` | `Void` | Gibt Ressourcen frei. |
