# Tools & Hilfsfunktionen (`mklib.tools.*` & `mklib.math.*`)

Dieses Modul beinhaltet nützliche Helfer für Auflösungs- und Seitenverhältnisberechnungen sowie mathematische Rundungen.

---

## 📱 `AspectRatio` (`mklib.tools.AspectRatio`)

Berechnet dynamisch die optimale interne Spielauflösung anhand des Bildschirms-Seitenverhältnisses. Dies ist besonders wertvoll für mobile Endgeräte und unterschiedliche Breitbild-Monitore (z. B. 16:9, 18:9, 19.5:9, 21:9), um schwarze Balken ("Letterboxing") zu vermeiden.

### Funktionsweise

- Hält eine feste vertikale Design-Höhe (Standard: `180` Pixel).
- Passt die Design-Breite proportional an (`height * screenRatio`), sofern das Seitenverhältnis im Bereich von **1.77 bis 2.22** (16:9 bis ca. 20:9) liegt.
- Fällt bei abweichenden Verhältnissen auf Standardmaße (`400x180`) zurück.

### API-Definition

```haxe
package mklib.tools;

class AspectRatio {
    public var width:Int;
    public var height:Int;
    public var isDefault:Bool;

    public function new(?screenWidth:Float = 0, ?screenHeight:Float = 0);
    public function isInRange():Bool;
}
```

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

Stellt statische Hilfsfunktionen für mathematische Berechnungen und Formatierungen bereit.

### `floatFix(v:Float, length:Int):Float`

Rundet eine Gleitkommazahl auf eine feste Anzahl von Nachkommastellen (z. B. zur Vermeidung von Rundungsfehlern bei Vergleichen oder Logging).

```haxe
import mklib.math.MathTool;

var value = 3.14159265;
var rounded = MathTool.floatFix(value, 2); // Ergibt 3.14

var ratio = 1920 / 1080; // 1.7777777777777777
var fixedRatio = MathTool.floatFix(ratio, 2); // Ergibt 1.78
```
