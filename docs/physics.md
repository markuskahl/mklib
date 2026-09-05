# Physik & Sensoren (`mklib.physic.*` & `mklib.tools.Tags`)

Das Physikmodul von `mklib` vereinfacht die Arbeit mit der **Nape 2D Physik-Engine** drastisch. Es ermöglicht die Registrierung von Kollisions- und Sensor-Handlern anhand von lesbaren Tag-Namen anstelle manuell verwalteter `CbType`-Instanzen.

---

## 🏷️ Tag-Verwaltung (`mklib.tools.Tags`)

Die Klasse `Tags` bietet statische Hilfsfunktionen, um `CbType`-Objekte aus dem aktuellen `State` abzufragen:

### Methoden (Methods)

| Methode | Signatur | Rückgabewert | Beschreibung |
| :--- | :--- | :--- | :--- |
| `get` | `(tag:String)` | `nape.callbacks.CbType` | Gibt das registrierte `CbType`-Objekt für einen gegebenen Tag-Namen aus `state.tags` zurück. Liefert `null`, wenn der Tag nicht existiert oder kein `State` aktiv ist. |
| `exist` | `(tag:String)` | `Bool` | Prüft, ob ein gegebener Tag-Name in der Tag-Map des aktuellen `State` registriert ist (`true` / `false`). |

### Verwendung

```haxe
import mklib.tools.Tags;

// CbType für den Tag "Player" abrufen
var playerCb:nape.callbacks.CbType = Tags.get("Player");

// Prüfen, ob ein Tag existiert
if (Tags.exist("Hazard")) {
    trace("Hazard Tag ist registriert!");
}
```

---

## ⚡ Ereignis-Listener (`mklib.physic.Listener`)

Die Klasse `mklib.physic.Listener` stellt statische Hilfsmethoden bereit, um Nape-Kollisionen und Sensorüberlappungen über lesbare Tag-Namen zu registrieren.

### Übersicht: Physische Kollisionen (`InteractionType.COLLISION`)

Physische Kontakte, bei denen Körper aneinander abprallen, stehen bleiben oder aufliegen.

| Methode | Signatur | Rückgabe | Beschreibung |
| :--- | :--- | :--- | :--- |
| `addCollisionBeginListener` | `(tag1:String, tag2:String, handler:InteractionCallback->Void)` | `Void` | Registriert ein `CbEvent.BEGIN`-Event für `COLLISION`. Wird aufgerufen, sobald sich zwei Körper mit `tag1` und `tag2` berühren. |
| `addCollisionEndListener` | `(tag1:String, tag2:String, handler:InteractionCallback->Void)` | `Void` | Registriert ein `CbEvent.END`-Event für `COLLISION`. Wird aufgerufen, sobald der physische Kontakt zwischen `tag1` und `tag2` abreißt. |
| `addCollisionOngoingListener` | `(tag1:String, tag2:String, handler:InteractionCallback->Void)` | `Void` | Registriert ein `CbEvent.ONGOING`-Event für `COLLISION`. Wird in jedem Physik-Tick aufgerufen, solange die Körper mit `tag1` und `tag2` in Kontakt stehen. |

### Übersicht: Sensoren (`InteractionType.SENSOR`)

Überlappungen ohne physischen Widerstand (z. B. Trigger-Zonen, Münzen, Schadensflächen, Kontrollpunkte).

| Methode | Signatur | Rückgabe | Beschreibung |
| :--- | :--- | :--- | :--- |
| `addSensorBeginListener` | `(tag1:String, tag2:String, handler:InteractionCallback->Void)` | `Void` | Registriert ein `CbEvent.BEGIN`-Event für `SENSOR`. Wird beim ersten Überlappen von `tag1` und `tag2` aufgerufen. |
| `addSensorEndListener` | `(tag1:String, tag2:String, handler:InteractionCallback->Void)` | `Void` | Registriert ein `CbEvent.END`-Event für `SENSOR`. Wird beim Verlassen der Überlappung von `tag1` und `tag2` aufgerufen. |
| `addSensorOngoingListener` | `(tag1:String, tag2:String, handler:InteractionCallback->Void)` | `Void` | Registriert ein `CbEvent.ONGOING`-Event für `SENSOR`. Wird in jedem Physik-Tick aufgerufen, solange sich `tag1` und `tag2` überlappen. |
| `addSensorBeginListenerANY` | `(tag1:String, handler:InteractionCallback->Void)` | `Void` | Registriert ein `CbEvent.BEGIN`-Sensor-Event zwischen `tag1` und `CbType.ANY_BODY` (jedem beliebigen Nape-Körper). |
| `addSensorEndListenerANY` | `(tag1:String, handler:InteractionCallback->Void)` | `Void` | Registriert ein `CbEvent.END`-Sensor-Event zwischen `tag1` und `CbType.ANY_BODY`. |
| `addSensorOngoingListenerANY` | `(tag1:String, handler:InteractionCallback->Void)` | `Void` | Registriert ein `CbEvent.ONGOING`-Sensor-Event zwischen `tag1` und `CbType.ANY_BODY`. |

### Übersicht: Pixelgenaue Kollisionen & Pixel-Sensoren (`Pixel-Perfect`)

Pixelgenaue Kollisions- und Sensorüberwachung via `FlxG.pixelPerfectOverlap`.

| Methode | Signatur | Rückgabe | Beschreibung |
| :--- | :--- | :--- | :--- |
| `addPixelCollisionListener` | `(tag1:String, tag2:String, ?onCollision:EntityNapeSprite->EntityNapeSprite->Void)` | `Void` | **Physische Pixel-Kollision:** Registriert eine pixelgenaue Kollisionsüberwachung zwischen `tag1` (Akteur) und `tag2` (Hindernis). Löst bei Pixel-Überlappung automatisches Zurücksetzen, Stoppen und Wall-Sliding via `resolvePixelCollision` aus. Optionaler Callback `(actor, obstacle) -> Void`. |
| `addPixelSensorBeginListener` | `(tag1:String, tag2:String, onBegin:EntityNapeSprite->EntityNapeSprite->Void)` | `Void` | **Pixel-Sensor (Start):** Feuert genau einmal im ersten Frame, in dem sich tatsächliche Pixel von `tag1` und `tag2` berühren (ohne die Bewegung physikalisch zu blockieren). Perfekt für Münzen, Schalter, Fallen. |
| `addPixelSensorOngoingListener` | `(tag1:String, tag2:String, onOngoing:EntityNapeSprite->EntityNapeSprite->Void)` | `Void` | **Pixel-Sensor (Dauerhaft):** Feuert in jedem Physik-Tick, solange sich tatsächliche Pixel überlappen (z. B. Schaden über Zeit in Giftwolken/Lava, Wasserströmungen). |
| `addPixelSensorEndListener` | `(tag1:String, tag2:String, onEnd:EntityNapeSprite->EntityNapeSprite->Void)` | `Void` | **Pixel-Sensor (Ende):** Feuert in dem Frame, in dem die Pixel-Überlappung abreißt, nachdem zuvor ein Kontakt bestand. |

---

## 📐 Shape-Generierung aus Grafiken (`mklib.physic.ShapeBuilder`)

Die Klasse `mklib.physic.ShapeBuilder` bietet statische Methoden zur vollautomatischen Generierung konvexer Nape-`Polygon`-Shapes direkt aus Pixelgrafiken (`BitmapData` und `FlxSprite`) mittels **Marching Squares** (`nape.geom.MarchingSquares`) und konvexer Zerlegung (`convexDecomposition`).

Darüber hinaus unterstützt `ShapeBuilder` das automatische Generieren und Zwischenspeichern von Shapes für alle Frames einer Sprite-Animation (sowohl in normaler Ausrichtung als auch horizontal gespiegelt für `flipX`).

### Methoden (Methods)

| Methode | Signatur | Rückgabewert | Beschreibung |
| :--- | :--- | :--- | :--- |
| `createShapesFromBitmap` | `(bmd:BitmapData, ?body:Body, alphaThreshold:Int = 128, simplify:Float = 1.0, ?offset:Vec2, sensor:Bool = false, ?cbType:CbType, cellSizeVal:Float = 1.0)` | `Array<Polygon>` | Erzeugt konvexe Nape-`Polygon`-Shapes direkt aus den sichtbaren Pixeln einer `BitmapData`. Die Shapes können optional direkt einem Nape-`Body` zugewiesen, mit einem `offset` verschoben oder als Sensoren deklariert werden. |
| `createShapesFromSprite` | `(sprite:FlxSprite, ?body:Body, alphaThreshold:Int = 128, simplify:Float = 1.0, sensor:Bool = false, ?cbType:CbType, cellSizeVal:Float = 1.0)` | `Array<Polygon>` | Erzeugt passgenaue Polygon-Shapes für ein `FlxSprite` und richtet sie automatisch am Ursprung (`origin.x`, `origin.y`) des Sprites aus. Falls kein `body` übergeben wird, wird `sprite.body` (falls vorhanden) genutzt. |
| `createBodyFromSprite` | `(sprite:FlxSprite, ?type:BodyType, alphaThreshold:Int = 128, simplify:Float = 1.0, sensor:Bool = false, ?cbType:CbType, cellSizeVal:Float = 1.0)` | `Body` | Erzeugt einen neuen Nape-`Body` (`STATIC`, `DYNAMIC` oder `KINEMATIC`) und bestückt ihn automatisch mit konvexen Polygon-Shapes aus der Sprite-Grafik. |
| `extractFrameBitmap` | `(sourceBmd:BitmapData, frameRect:Rectangle, flipX:Bool = false, flipY:Bool = false)` | `Null<BitmapData>` | Schneidet ein einzelnes Frame aus einer Spritesheet-`BitmapData` aus und spiegelt es optional horizontal (`flipX`) oder vertikal (`flipY`). |
| `createShapesForAnimation` | `(sprite:FlxSprite, animName:String, alphaThreshold:Int = 128, simplify:Float = 1.0, sensor:Bool = true, ?cbType:CbType, cellSizeVal:Float = 1.0)` | `Map<String, Array<Polygon>>` | Erzeugt vorberechnete Polygon-Shapes für alle Frames einer `FlxSprite`-Animation (für Normal- und `flipX`-Darstellung). Shapes erhalten in `userData` Metadaten (`animName`, `frameNumber`, `frameIndex`). |

### Verwendung

```haxe
import mklib.physic.ShapeBuilder;
import mklib.tools.Tags;
import nape.phys.BodyType;

// 1. Shapes direkt für ein FlxSprite erzeugen und dem Körper zuweisen
var shapes = ShapeBuilder.createShapesFromSprite(
    mySprite,
    myBody,
    128,                     // Alpha-Schwellenwert (0-255)
    1.0,                     // Vereinfachung/Glättung in Pixeln (simplify)
    false,                   // sensor = false (feste physische Kollision)
    Tags.get("Obstacle"),    // CbType für alle erzeugten Shapes
    1.0                      // Zellengröße (cellSize)
);

// 2. Kompletten neuen Nape-Body aus einem Sprite erzeugen
var enemyBody = ShapeBuilder.createBodyFromSprite(
    enemySprite,
    BodyType.DYNAMIC,
    128,
    1.5,
    false,
    Tags.get("Enemy")
);

// 3. Shapes für eine Angriffsanimation vorberechnen
var attackShapes = ShapeBuilder.createShapesForAnimation(
    heroSprite,
    "attack",
    128,
    1.0,
    true,                    // Als Hitbox-Sensoren
    Tags.get("HeroHitbox")
);
```

---

## 💡 Code-Beispiel: Münzen einsammeln, Schaden nehmen & Pixel-Kollision / Sensoren

```haxe
package;

import mklib.state.State;
import mklib.physic.Listener;
import mklib.physic.ShapeBuilder;
import mklib.entity.EntityNapeSprite;
import nape.callbacks.InteractionCallback;
import entities.Hero;
import entities.Coin;

class PlayState extends State<Data.Data_Level> {
    override public function create():Void {
        super.create();
        napeInit(0, 300);

        // 1. Münzen pixelgenau einsammeln (Pixel-Sensor BEGIN, ohne grobe Bounding-Box-Fehlauslösung)
        Listener.addPixelSensorBeginListener("Player", "Coin", onCollectCoinPixel);

        // 2. Schaden in Lava-Feldern (Pixel-Sensor ONGOING, Schaden pro Frame bei echtem Kontakt)
        Listener.addPixelSensorOngoingListener("Player", "Lava", onBurnInLava);

        // 3. Stacheln berühren (Standard Nape CbEvent.BEGIN Kollisions-Event)
        Listener.addCollisionBeginListener("Player", "Spikes", onHitSpikes);

        // 4. Pixelgenaue feste Kollision zwischen Spieler und Hindernissen (inkl. Wall-Sliding)
        Listener.addPixelCollisionListener("Player", "Obstacle", onPixelHit);
    }

    private function onCollectCoinPixel(player:EntityNapeSprite, coin:EntityNapeSprite):Void {
        coin.kill();
        trace("Münze bei exaktem Pixelkontakt eingesammelt!");
    }

    private function onBurnInLava(player:EntityNapeSprite, lava:EntityNapeSprite):Void {
        trace("Spieler berührt Lava-Pixel!");
    }

    private function onPixelHit(actor:EntityNapeSprite, obstacle:EntityNapeSprite):Void {
        trace('Pixel-Kollision zwischen ${actor.iid} und ${obstacle.iid}');
    }

    private function onCollectCoin(cb:InteractionCallback):Void {
        // Über body.userData.instance auf die Haxe-Entity-Instanzen zugreifen:
        var player:Hero = cast cb.int1.userData.instance;
        var coin:Coin = cast cb.int2.userData.instance;

        if (coin != null) {
            coin.kill(); // Münze aus dem Spiel entfernen
            trace("Münze eingesammelt!");
        }
    }

    private function onHitSpikes(cb:InteractionCallback):Void {
        var player:Hero = cast cb.int1.userData.instance;
        if (player != null) {
            trace("Spieler hat Stacheln berührt - Schaden zufügen!");
        }
    }

    private function onTriggerCheckpoint(cb:InteractionCallback):Void {
        trace("Ein Körper hat den Checkpoint betreten: " + cb.int2.castBody);
    }
}
```
