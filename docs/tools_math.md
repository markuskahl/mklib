# Tools & Hilfsfunktionen (`mklib.tools.*` & `mklib.math.*`)

Dieses Modul beinhaltet Werkzeuge für dynamische Auflösungs- und Seitenverhältnisberechnungen sowie mathematische Rundungen.

---

## 📱 `AspectRatio` (`mklib.tools.AspectRatio`)

Berechnet dynamisch die optimale interne Spielauflösung anhand des Bildschirms-Seitenverhältnisses. Dies ist besonders wertvoll für mobile Endgeräte und unterschiedliche Breitbild-Monitore (z. B. 16:9, 18:9, 19.5:9, 20:9, 21:9), um schwarze Balken ("Letterboxing") zu vermeiden.

### Eigenschaften (Properties)

| Eigenschaft | Typ | Modifizierer | Beschreibung |
| :--- | :--- | :--- | :--- |
| `width` | `Int` | `public` | Die berechnete Spielbreite in Pixeln (z. B. `320` bis `400`). |
| `height` | `Int` | `public` | Die berechnete Spielhöhe in Pixeln (feste Design-Höhe, Standard: `180`). |
| `isDefault` | `Bool` | `public` | Gibt an, ob auf die Standard-Fallback-Dimensionen (`400x180`) zurückgegriffen wurde, falls das Seitenverhältnis außerhalb des tolerierten Bereichs liegt. |
| `screenRatio` | `Float` | `private` | Das tatsächliche Seitenverhältnis des Bildschirms (`screenWidth / screenHeight`). |

### Methoden (Methods)

| Methode | Signatur | Rückgabewert | Beschreibung |
| :--- | :--- | :--- | :--- |
| `new` | `(?screenWidth:Float = 0, ?screenHeight:Float = 0)` | `Void` | Erstellt eine neue `AspectRatio`-Instanz. Werden keine Dimensionen übergeben, wird die Bildschirmauflösung automatisch via `Capabilities.screenResolutionX / screenResolutionY` ermittelt (Fallback `1280x720`). Führt sofort `calc()` aus. |
| `calc` | `()` | `Void` | *(Privat)* Führt die Berechnung von `width` und `height` auf Basis von `screenRatio` durch. |
| `isInRange` | `()` | `Bool` | Prüft, ob das Seitenverhältnis im unterstützten Breitbildbereich liegt (zwischen `1.77` und `2.22`, gerundet mit `MathTool.floatFix`). Liefert `true` oder `false`. |

### Verwendung im Spiel-Einstiegspunkt (`Main.hx`)

```haxe
package;

import flixel.FlxGame;
import openfl.display.Sprite;
import mklib.tools.AspectRatio;

class Main extends Sprite {
    public function new() {
        super();

        // Auflösung dynamisch berechnen
        var ar = new AspectRatio();
        trace('Spielauflösung: ${ar.width} x ${ar.height} (Standard: ${ar.isDefault})');

        addChild(new FlxGame(ar.width, ar.height, PlayState, 60, 60, true, false));
    }
}
```

---

## 🔢 `MathTool` (`mklib.math.MathTool`)

Stellt statische Hilfsfunktionen für mathematische Berechnungen bereit.

### Methoden (Methods)

| Methode | Signatur | Rückgabewert | Beschreibung |
| :--- | :--- | :--- | :--- |
| `floatFix` | `(v:Float, length:Int)` | `Float` | *(Inline, Statisch)* Rundet eine Gleitkommazahl `v` auf eine feste Anzahl von `length` Nachkommastellen. Ungültige Werte (`NaN`, unendlich) werden unverändert zurückgegeben. |

### Code-Beispiel

```haxe
import mklib.math.MathTool;

var value = 3.14159265;
var rounded = MathTool.floatFix(value, 2); // Ergibt 3.14

var ratio = 1920 / 1080; // 1.7777777777777777
var fixedRatio = MathTool.floatFix(ratio, 2); // Ergibt 1.78
```
