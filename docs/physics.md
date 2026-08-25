# Physik & Sensoren (`mklib.physic.*` & `mklib.tools.Tags`)

Das Physikmodul von `mklib` vereinfacht die Arbeit mit der **Nape-Physik-Engine** drastisch. Es ermöglicht die Registrierung von Kollisions- und Sensor-Handlern anhand von lesbaren Tag-Namen anstelle manuell verwalteter `CbType`-Instanzen.

---

## 🏷️ Tag-Verwaltung (`mklib.tools.Tags`)

Die Klasse `Tags` bietet statische Hilfsfunktionen, um `CbType`-Objekte aus dem aktuellen `State` abzufragen:

```haxe
// CbType für den Tag "Player" abrufen
var playerCb:nape.callbacks.CbType = Tags.get("Player");

// Prüfen, ob ein Tag existiert
if (Tags.exist("Hazard")) {
    trace("Hazard Tag ist registriert!");
}
```

---

## ⚡ Ereignis-Listener (`mklib.physic.Listener`)

Die Klasse `mklib.physic.Listener` stellt statische Methoden bereit, um auf Kollisionen und Sensorüberlappungen zu reagieren.

### 1. Kollisionen (`InteractionType.COLLISION`)
Physische Kontakte, bei denen Körper aneinander abprallen oder aufliegen.

| Methode | Beschreibung |
| :--- | :--- |
| `addCollisionBeginListener(tag1, tag2, handler)` | Wird aufgerufen, sobald sich zwei Körper mit `tag1` und `tag2` berühren. |
| `addCollisionEndListener(tag1, tag2, handler)` | Wird aufgerufen, sobald der physische Kontakt endet. |
| `addCollisionOngoingListener(tag1, tag2, handler)` | Wird in jedem Physik-Schritt aufgerufen, solange die Körper in Kontakt sind. |

### 2. Sensoren (`InteractionType.SENSOR`)
Überlappungen ohne physischen Widerstand (z. B. Trigger-Zonen, Münzen, Schadensflächen).

| Methode | Beschreibung |
| :--- | :--- |
| `addSensorBeginListener(tag1, tag2, handler)` | Überlappung zwischen `tag1` und `tag2` beginnt. |
| `addSensorEndListener(tag1, tag2, handler)` | Überlappung zwischen `tag1` und `tag2` endet. |
| `addSensorOngoingListener(tag1, tag2, handler)` | Überlappung zwischen `tag1` und `tag2` dauert an. |
| `addSensorBeginListenerANY(tag1, handler)` | `tag1` überlappt mit **irgendeinem** anderen Nape-Körper. |
| `addSensorEndListenerANY(tag1, handler)` | `tag1` beendet Überlappung mit **irgendeinem** anderen Nape-Körper. |
| `addSensorOngoingListenerANY(tag1, handler)` | `tag1` überlappt andauernd mit **irgendeinem** anderen Nape-Körper. |

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

        // Münzen einsammeln (Sensor-Event zwischen "Player" und "Coin")
        Listener.addSensorBeginListener("Player", "Coin", onCollectCoin);

        // Stacheln berühren (Kollisions-Event zwischen "Player" und "Spikes")
        Listener.addCollisionBeginListener("Player", "Spikes", onHitSpikes);
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
}
```
