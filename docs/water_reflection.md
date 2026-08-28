# Wasser-Reflexions- & Wellen-Shader-System (`mklib.effect.*`)

Das **Wasser-Reflexions- & Wellen-Shader-System** von `mklib` bietet hardwarebeschleunigte 2D-GPU-Shader und spezialisierte Spielobjekte für HaxeFlixel. Es ermöglicht dynamische Wasserspiegelungen, organische Wellenverzerrungen, horizontale/vertikale Achsenspiegelungen sowie automatische Wasser-Begleiter-Reflexionen für Spielfiguren und Entities.

---

## 🌟 Features & Highlights

- **⚡ Hardwarebeschleunigter GPU-Fragment-Shader (`WaterReflectionShader`)**:
  - Berechnet Multi-Frequenz-Sinus- und Cosinus-Wellenverzerrungen direkt auf der Grafikkarte.
  - Extrem ressourcensparend (nur wenige trigonometrische Rechenschritte pro Pixel).
- **🔄 3 Flexible Betriebsmodi (`WaterReflectionMode`)**:
  - `VERTICAL_WATER_PLANE`: Klassische Wasseroberfläche – spiegelt die Szene oberhalb der Wasserlinie vertikal nach unten.
  - `HORIZONTAL_MIRROR`: Horizontale Spiegelung links/rechts an einer vertikalen Spiegelachse (z. B. für magische Spiegel, Portale oder seitliche Wasserwände).
  - `WAVE_DISTORTION_ONLY`: Organische Texturverzerrung ohne Achsenspiegelung (für animierte Wasseroberflächen, Pfützen oder bereits geflippte Sprites).
- **🌊 Ästhetische Wasser-Effekte**:
  - **Wassertönung (`u_waterColor`)**: Frei wählbare RGB-Farbe mit kontinuierlichem Mischfaktor.
  - **Tiefenausblendung (`u_fadeDepth`, `u_minAlpha`)**: Reflexion wird mit zunehmender Wassertiefe weich transparenter.
  - **Schaum- / Gischt-Kante (`u_foamThickness`, `u_foamColor`)**: Akzentuierte Lichtkante an der Wasseroberfläche.
- **🎥 Vollautomatische Kamera- & Weltsynchronisation**:
  - Bei Nutzung von `syncWithCamera(worldY, camera)` bleibt die Wasserlinie bei Scrolling und Zoom exakt an ihrer Position im Level verankert.
- **🦆 Entity-Begleiter (`EntityWaterReflection`)**:
  - Spiegelt beliebige `FlxSprite`- oder `EntitySprite`-Objekte automatisch unterhalb der Spielfigur, synchronisiert Frames/Animationen und wendet Wellenverzerrung an.

---

## 🏛️ Klassen- und Typenübersicht

| Klasse / Typ | Erbt von / Art | Beschreibung |
| :--- | :--- | :--- |
| `WaterReflectionShader` | `FlxShader` | Der GLSL-GPU-Shader für Wellenbewegung, Spiegelung, Tönung, Tiefenabnahme und Schaumkanten. |
| `WaterReflectionPlane` | `FlxSprite` | Fertig konfiguriertes Wasserflächen-Spielobjekt mit automatischem Shader-, Zeit- und Kamera-Management. |
| `EntityWaterReflection` | `FlxSprite` | Begleiter-Sprite für einzelne Spielfiguren (`Hero`, NPCs), das sich unterhalb platziert und gespiegelt mit animiert. |
| `WaterReflectionMode` | `enum abstract` | Aufzählung der Modi (`VERTICAL_WATER_PLANE`, `HORIZONTAL_MIRROR`, `WAVE_DISTORTION_ONLY`). |

---

## 🚀 Schnelleinstieg & Code-Beispiele

### 1. Kamera- / Vollbild-Filter (Post-Processing)

Wendet den Wasser-Spiegelungseffekt auf die gesamte Kamera an – alle sichtbaren Tiles und Entities oberhalb der Wasserlinie werden automatisch gespiegelt:

```haxe
package;

import flixel.FlxG;
import openfl.filters.ShaderFilter;
import mklib.state.State;
import mklib.effect.shader.WaterReflectionShader;

class PlayState extends State<Data.Data_Level> {
    public var waterShader:WaterReflectionShader;

    override public function create():Void {
        super.create();

        waterShader = new WaterReflectionShader();
        
        // Wasserlinie bei 70% der Bildschirmhöhe
        waterShader.setWaterLevel(0.70);
        
        // Sanfte Wellen konfigurieren: speed=2.5, frequency=30.0, amplitude=0.01
        waterShader.setWaveParams(2.5, 30.0, 0.01, 0.5);
        
        // Bläuliche Wassertönung mit Schaumkante
        waterShader.setWaterColor(0x3366AA, 0.45);
        waterShader.setFoam(0.006, 0xFFFFFF);

        // Als Kamerafilter aktivieren (FlxG.camera.filters ist standardmäßig null)
        FlxG.camera.filters = [new ShaderFilter(waterShader)];
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Zeit für kontinuierliche Wellenbewegung hochzählen
        waterShader.update(elapsed);
    }
}
```

---

### 2. Platzierte Wasserfläche im Level (`WaterReflectionPlane`)

Ein eigenständiges Spielobjekt, das an festen Weltkoordinaten (z. B. einem See) liegt und automatisch mit der Kamera synchronisiert wird:

```haxe
import mklib.effect.WaterReflectionPlane;

// Wasserfläche bei X=0, Y=320 mit 640px Breite und 160px Tiefe
var water = new WaterReflectionPlane(0, 320, 640, 160, 0x66103560);
water.setWaveParams(3.0, 35.0, 0.008);
water.setFoam(0.008, 0xEEFFFF);
add(water);
```

---

### 3. Entity-Wasserreflexion (`EntityWaterReflection`)

Erzeugt eine dynamische Wasser-Reflexion für den Spieler (`Hero`) oder NPCs:

```haxe
import entities.Hero;
import mklib.effect.EntityWaterReflection;

// Spielfigur erstellen
var hero = new Hero(data.l_Entities.all_Hero[0]);
add(hero);

// Automatische Wasserreflexion unter dem Spieler erzeugen
var heroReflection = new EntityWaterReflection(hero, 0.55, 0x44205080);
heroReflection.setWaveParams(3.5, 20.0, 0.012);
add(heroReflection);
```

---

### 4. Horizontaler Spiegel-Modus (`HORIZONTAL_MIRROR`)

Für magische Spiegel, Raumportale oder seitliche Wasserwände:

```haxe
var mirrorShader = new WaterReflectionShader();
mirrorShader.setMode(HORIZONTAL_MIRROR);
mirrorShader.setWaterLevel(0.5); // Spiegelachse in der Bildschirmmitte (X = 50%)
mirrorShader.setWaveParams(2.0, 25.0, 0.006);

FlxG.camera.filters = [new ShaderFilter(mirrorShader)];
```

---

## ⚙️ Shader-Parameter & Uniforms

| Uniform / Eigenschaft | Methode | Typ / Bereich | Standard | Beschreibung |
| :--- | :--- | :--- | :--- | :--- |
| `u_time` | `update(elapsed)` | `Float` | `0.0` | Fortlaufender Zeitzähler in Sekunden für die Wellenanimation. |
| `u_mode` | `setMode(mode)` | `Int (0..2)` | `0` | Betriebsmodus: Vertikal (0), Horizontal (1) oder Verzerrung (2). |
| `u_waterLevel` | `setWaterLevel(val)` | `Float (0.0..1.0)` | `0.65` | Normierte Position der Wasser- oder Spiegelachse im Viewport. |
| `u_waveSpeed` | `setWaveParams(...)` | `Float` | `2.8` | Geschwindigkeit der Hauptwellenbewegung. |
| `u_waveFrequency` | `setWaveParams(...)` | `Float` | `35.0` | Raumfrequenz (Dichte der Wellenkämme). |
| `u_waveAmplitude` | `setWaveParams(...)` | `Float` | `0.008` | Maximale Verzerrungsstärke (Auslenkung der Pixel). |
| `u_secondaryWave` | `setWaveParams(...)` | `Float` | `0.5` | Wichtung der überlagerten Kreuzwelle für natürlichere Bewegung. |
| `u_waterColor` | `setWaterColor(...)` | `vec4 (RGBA)` | `[0.08, 0.35, 0.65, 0.4]` | RGB-Farbfilter und Mischfaktor der Wassertiefe. |
| `u_fadeDepth` | `setFade(...)` | `Float` | `2.0` | Dämpfungsfaktor für das Ausblenden der Reflexion mit zunehmender Tiefe. |
| `u_minAlpha` | `setFade(...)` | `Float (0.0..1.0)` | `0.15` | Minimale Resttransparenz der Reflexion. |
| `u_foamThickness` | `setFoam(...)` | `Float` | `0.006` | Breite der Schaumkante an der Wasseroberfläche (`0.0` = aus). |
| `u_foamColor` | `setFoam(...)` | `vec4 (RGBA)` | `[0.95, 0.98, 1.0, 0.75]` | Farbe und Deckkraft der Schaumlinie. |
