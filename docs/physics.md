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

---

## 💡 Code-Beispiel: Münzen einsammeln & Schaden nehmen

```haxe
package;

import mklib.state.State;
import mklib.physic.Listener;
import nape.callbacks.InteractionCallback;
import entities.Hero;
import entities.Coin;

class PlayState extends State<Data.Data_Level> {
    override public function create():Void {
        super.create();
        napeInit(0, 300);

        // 1. Münzen einsammeln (Sensor-Event zwischen "Player" und "Coin")
        Listener.addSensorBeginListener("Player", "Coin", onCollectCoin);

        // 2. Stacheln berühren (Kollisions-Event zwischen "Player" und "Spikes")
        Listener.addCollisionBeginListener("Player", "Spikes", onHitSpikes);

        // 3. Sensor-Event mit beliebigem Körper
        Listener.addSensorBeginListenerANY("Checkpoint", onTriggerCheckpoint);
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
