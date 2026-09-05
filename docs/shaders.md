# Shader- & Post-Processing-System (`mklib.effect.*`)

Das **Shader- & Post-Processing-System** von `mklib` bietet leistungsstarke, hardwarebeschleunigte 2D-GPU-Shader (`FlxShader`) und vorgefertigte Spielobjekte (`FlxSprite`) für HaxeFlixel. Es umfasst authentische Retro-Arcade-Bildschirmfilter, animierte prozedurale Lava-/Säure-Flüssigkeiten sowie dynamische Wasserspiegelungen und Wellen.

---

## 🏛️ Übersicht der Shader-Module

| Klasse / Typ | Modul | Art | Beschreibung |
| :--- | :--- | :--- | :--- |
| `CrtShader` | `mklib.effect.shader` | `FlxShader` | CRT & Retro-Arcade Post-Processing (Wölbung, Scanlines, RGB-Maske, Chromatic Aberration, Vignette, Bloom, Flimmern). |
| `HazardLiquidShader` | `mklib.effect.shader` | `FlxShader` | Prozeduraler GPU-Flüssigkeits-Shader für Lava, Säure/Slime und Giftwasser mit Kruste, Blubbern und Glühkante. |
| `HazardLiquidPlane` | `mklib.effect` | `FlxSprite` | Platzierebares Spielobjekt für Lava-/Säurebecken im Level mit automatischer Schadensberechnung. |
| `HazardLiquidType` | `mklib.effect` | `enum abstract` | Vordefinierte Flüssigkeitstypen (`LAVA`, `ACID_SLIME`, `TOXIC_WATER`, `CUSTOM`). |
| `WaterReflectionShader` | `mklib.effect.shader` | `FlxShader` | Wasserspiegelungs- und Wellenverzerrungs-Shader mit Tiefenfading und Schaumkante. |
| `WaterReflectionPlane` | `mklib.effect` | `FlxSprite` | Echtzeit-Wasserspiegelungsebene für Tiles, Deko und Entities. |
| `EntityWaterReflection` | `mklib.effect` | `FlxSprite` | Gespiegelter Wasser-Begleiter für einzelne Spielfiguren (`Hero`, NPCs). |
| `WaterReflectionMode` | `mklib.effect` | `enum abstract` | Betriebsmodi (`VERTICAL_WATER_PLANE`, `HORIZONTAL_MIRROR`, `WAVE_DISTORTION_ONLY`). |

---

## 📺 1. CRT & Retro-Arcade Shader (`CrtShader`)

Der `CrtShader` simuliert das Bild alter Röhrenmonitore und Arcade-Automaten der 80er/90er Jahre. Er kann direkt als Kamera-Filter (`ShaderFilter`) oder auf einzelnen Sprites eingesetzt werden.

### 🌟 Features
- **Bildschirmwölbung (`setCurvature`)**: Einstellbare Tonnenverzeichnung (Barrel Distortion) mit weichen Bezel-Rändern.
- **Scanlines (`setScanlines`)**: Horizontale Kathodenstrahllinien mit anpassbarer Frequenz, Dunkelheit und optionalem vertikalen Rollen.
- **RGB Phosphor Mask (`setRgbMask`)**: Authentisches Subpixel-Streifenmuster (Triad Shadow Mask).
- **Chromatische Aberration (`setChromaticAberration`)**: Farbkanalverschiebung (RGB-Split) zu den Bildschirmrändern hin.
- **Vignette & Bezel-Schatten (`setVignette`)**: Röhrentypische Randabdunkelung und Eckabrundung.
- **Bloom & Kontrast (`setBloom`)**: Strahlender Phosphor-Glow und Schärfe.
- **Analoges Rauschen & Flimmern (`setAnalogNoise`)**: 50/60Hz Netzfrequenzflimmern und Bildrauschen.
- **Schnell-Presets**: `presetSubtle()`, `presetArcade()`, `presetVhsGlitch()`.

### 🚀 Code-Beispiel: CRT auf Kamera anwenden

```haxe
package;

import flixel.FlxG;
import openfl.filters.ShaderFilter;
import mklib.state.State;
import mklib.effect.shader.CrtShader;

class PlayState extends State<Data.Data_Level> {
    public var crtShader:CrtShader;

    override public function create():Void {
        super.create();

        // 1. CRT-Shader initialisieren
        crtShader = new CrtShader();

        // 2. Wunsch-Preset oder manuelle Feineinstellung
        crtShader.presetArcade();
        // Optional individuell anpassen:
        crtShader.setCurvature(0.08, 0.08);
        crtShader.setScanlines(0.25, 240.0, 0.2);

        // 3. Auf die Kamera als Filter legen
        FlxG.camera.filters = [crtShader.filter];
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Zeit für Scanline-Scrolling und Flimmern aktualisieren
        crtShader.update(elapsed, FlxG.camera);
    }
}
```

---

## 🧪 2. Lava / Acid / Slime Liquid System (`HazardLiquid*`)

Das Hazard-Liquid-System erzeugt animierte, prozedurale Flüssigkeitsbecken direkt auf der GPU – ohne rechenintensive Texturanimationen oder große Spritesheets.

### 🌟 Features
- **GPU-Berechnete Flüssigkeit**: Prozedurales Fractional Brownian Motion (fBm) Rauschen für natürliche Strömungen und Wirbel.
- **Aufbrechende Kruste**: Realistische, treibende Krustenschollen und Magmaplatten.
- **Glühende Hitze-Adern & Blubbern**: Emissive Risse und aufsteigende Bläschen.
- **Oberflächenwellen & Glühkante**: Physikalische Sinus-/Kosinus-Kämme mit strahlendem Lichtsaum.
- **Kamera- & Levelverankerung**: Bleibt bei Kamerabewegungen und Zoom exakt an der Weltposition fixiert.
- **Schadenskomponente (`damagePerSecond`, `applyHazardDamage`)**: Integrierte Berührungsprüfung und Umweltschaden.

### 🚀 Code-Beispiel: Lava- & Säurebecken im Level platzieren

```haxe
package;

import mklib.state.State;
import mklib.effect.HazardLiquidPlane;
import mklib.effect.HazardLiquidType;

class PlayState extends State<Data.Data_Level> {
    public var lavaPool:HazardLiquidPlane;
    public var acidPit:HazardLiquidPlane;

    override public function create():Void {
        super.create();

        // 1. Lava-Becken anlegen (X, Y, Breite, Höhe, Typ)
        lavaPool = new HazardLiquidPlane(200, 450, 320, 80, HazardLiquidType.LAVA);
        lavaPool.damagePerSecond = 50.0;
        add(lavaPool);

        // 2. Säure-Grube anlegen
        acidPit = new HazardLiquidPlane(600, 450, 240, 60, HazardLiquidType.ACID_SLIME);
        acidPit.damagePerSecond = 25.0;
        add(acidPit);
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Schaden auf den Spieler anwenden, falls eingetaucht
        if (hero != null) {
            lavaPool.applyHazardDamage(hero, elapsed);
            acidPit.applyHazardDamage(hero, elapsed);
        }
    }
}
```

---

## 🌊 3. Wasser-Reflexion & Wellen (`WaterReflection*`)

Ermöglicht spiegelnde Wasserflächen, Wasserwände und Wellenverzerrungen für 2D-Plattformer und Top-Down-Spiele.

### 🌟 Features
- **Echtzeit-Spiegelung (`WaterReflectionPlane`)**: Spiegelt Tiles, Spielfiguren und Deko oberhalb der Wasserkante mit Wellenverzerrung.
- **Tiefen-Fading & Schaumkante**: Wassertönung, sanftes Verblassen nach unten und weiße Oberflächen-Gischt.
- **Entity-Begleiter (`EntityWaterReflection`)**: Spiegelt Spielfiguren dynamisch am Boden mit.

### 🚀 Code-Beispiel: Wasserfläche

```haxe
var water = new WaterReflectionPlane(0, 300, 800, 150, 0x66103560);
water.setWaveParams(3.0, 25.0, 0.03, 0.5);
water.setFoam(0.015, 0xFFFFFFFF);
add(water);
```
