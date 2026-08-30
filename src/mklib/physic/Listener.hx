package mklib.physic;

import flixel.addons.nape.FlxNapeSpace;
import mklib.tools.Tags;
import mklib.entity.EntityNapeSprite;
import nape.callbacks.CbEvent;
import nape.callbacks.CbType;
import nape.callbacks.InteractionCallback;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionType;

/**
 * Komfortklasse zur einfachen Registrierung von Nape-Kollisions- und Sensor-Listenern
 * über String-basierte Tag-Namen (`CbType`).
 *
 * Unterstützt physische Kollisionen (`COLLISION`) und sensorische Überlappungen (`SENSOR`)
 * für die Ereignisse `BEGIN` (Start), `END` (Ende) und `ONGOING` (dauerhaft).
 */
class Listener
{
	/**
	 * Registriert einen Listener für den Beginn einer physischen Kollision (`CbEvent.BEGIN`, `InteractionType.COLLISION`)
	 * zwischen zwei Tag-Typen.
	 *
	 * @param tag1 Name des ersten Tags (z. B. "Player").
	 * @param tag2 Name des zweiten Tags (z. B. "Solid").
	 * @param handler Callback-Funktion, die bei Kollisionsbeginn aufgerufen wird.
	 */
	public static function addCollisionBeginListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		var cb2 = Tags.get(tag2);
		if (cb1 == null || cb2 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register CollisionBeginListener for "$tag1" and "$tag2" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, cb1, cb2, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	/**
	 * Registriert einen Listener für das Ende einer physischen Kollision (`CbEvent.END`, `InteractionType.COLLISION`)
	 * zwischen zwei Tag-Typen.
	 *
	 * @param tag1 Name des ersten Tags.
	 * @param tag2 Name des zweiten Tags.
	 * @param handler Callback-Funktion, die beim Verlassen der Kollision aufgerufen wird.
	 */
	public static function addCollisionEndListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		var cb2 = Tags.get(tag2);
		if (cb1 == null || cb2 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register CollisionEndListener for "$tag1" and "$tag2" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.END, InteractionType.COLLISION, cb1, cb2, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	/**
	 * Registriert einen Listener für andauernden physischen Kollisionskontakt (`CbEvent.ONGOING`, `InteractionType.COLLISION`)
	 * zwischen zwei Tag-Typen.
	 *
	 * @param tag1 Name des ersten Tags.
	 * @param tag2 Name des zweiten Tags.
	 * @param handler Callback-Funktion, die in jedem Physik-Tick des Kontakts aufgerufen wird.
	 */
	public static function addCollisionOngoingListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		var cb2 = Tags.get(tag2);
		if (cb1 == null || cb2 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register CollisionOngoingListener for "$tag1" and "$tag2" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.ONGOING, InteractionType.COLLISION, cb1, cb2, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	/**
	 * Registriert einen Listener für den Beginn einer Sensor-Überlappung (`CbEvent.BEGIN`, `InteractionType.SENSOR`)
	 * zwischen zwei Tag-Typen (ohne physische Abstoßung / Durchdringung erlaubt).
	 *
	 * @param tag1 Name des ersten Tags (z. B. "Player").
	 * @param tag2 Name des zweiten Tags (z. B. "Coin", "Checkpoint").
	 * @param handler Callback-Funktion beim Eintritt in den Sensor.
	 */
	public static function addSensorBeginListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		var cb2 = Tags.get(tag2);
		if (cb1 == null || cb2 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register SensorBeginListener for "$tag1" and "$tag2" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, cb1, cb2, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	/**
	 * Registriert einen Listener für das Ende einer Sensor-Überlappung (`CbEvent.END`, `InteractionType.SENSOR`)
	 * zwischen zwei Tag-Typen.
	 *
	 * @param tag1 Name des ersten Tags.
	 * @param tag2 Name des zweiten Tags.
	 * @param handler Callback-Funktion beim Verlassen des Sensors.
	 */
	public static function addSensorEndListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		var cb2 = Tags.get(tag2);
		if (cb1 == null || cb2 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register SensorEndListener for "$tag1" and "$tag2" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.END, InteractionType.SENSOR, cb1, cb2, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	/**
	 * Registriert einen Listener für andauernde Sensor-Überlappung (`CbEvent.ONGOING`, `InteractionType.SENSOR`)
	 * zwischen zwei Tag-Typen.
	 *
	 * @param tag1 Name des ersten Tags.
	 * @param tag2 Name des zweiten Tags.
	 * @param handler Callback-Funktion während des Verweilens im Sensor.
	 */
	public static function addSensorOngoingListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		var cb2 = Tags.get(tag2);
		if (cb1 == null || cb2 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register SensorOngoingListener for "$tag1" and "$tag2" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.ONGOING, InteractionType.SENSOR, cb1, cb2, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	/**
	 * Registriert einen Sensor-Begin-Listener für einen bestimmten Tag mit JEDEM beliebigen anderen Körper (`CbType.ANY_BODY`).
	 *
	 * @param tag1 Name des Tags.
	 * @param handler Callback-Funktion beim Beginn der Überlappung.
	 */
	public static function addSensorBeginListenerANY(tag1:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		if (cb1 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register SensorBeginListenerANY for "$tag1" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, cb1, CbType.ANY_BODY, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	/**
	 * Registriert einen Sensor-End-Listener für einen bestimmten Tag mit JEDEM beliebigen anderen Körper (`CbType.ANY_BODY`).
	 *
	 * @param tag1 Name des Tags.
	 * @param handler Callback-Funktion beim Verlassen der Überlappung.
	 */
	public static function addSensorEndListenerANY(tag1:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		if (cb1 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register SensorEndListenerANY for "$tag1" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.END, InteractionType.SENSOR, cb1, CbType.ANY_BODY, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	/**
	 * Registriert einen andauernden Sensor-Listener (`ONGOING`) für einen bestimmten Tag mit JEDEM beliebigen anderen Körper (`CbType.ANY_BODY`).
	 *
	 * @param tag1 Name des Tags.
	 * @param handler Callback-Funktion während der Überlappung.
	 */
	public static function addSensorOngoingListenerANY(tag1:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		if (cb1 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register SensorOngoingListenerANY for "$tag1" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.ONGOING, InteractionType.SENSOR, cb1, CbType.ANY_BODY, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	/**
	 * Registriert eine pixelgenaue Kollisionsüberwachung zwischen zwei Tag-Typen (`tag1` und `tag2`).
	 * Löst bei Pixel-Überlappung (`FlxG.pixelPerfectOverlap`) automatisch das Zurücksetzen und Stoppen
	 * von `tag1` gegenüber `tag2` (inkl. Wall-Sliding) über `EntityNapeSprite.resolvePixelCollision` aus.
	 *
	 * @param tag1 Name des sich bewegenden Akteurs (z. B. "Hero", "Player").
	 * @param tag2 Name des Hindernisses (z. B. "Obstacle", "Solid").
	 * @param onCollision Optionaler Callback, der bei Pixel-Kollision aufgerufen wird: `(actor, obstacle) -> Void`.
	 */
	public static function addPixelCollisionListener(tag1:String, tag2:String, ?onCollision:EntityNapeSprite->EntityNapeSprite->Void):Void
	{
		var cb1 = Tags.get(tag1);
		var cb2 = Tags.get(tag2);
		if (cb1 == null || cb2 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register PixelCollisionListener for "$tag1" and "$tag2" (CbType or space is null)');
			return;
		}

		addSensorOngoingListener(tag1, tag2, function(cb:InteractionCallback) {
			var entA = EntityNapeSprite.getFromInteractor(cb.int1);
			var entB = EntityNapeSprite.getFromInteractor(cb.int2);
			if (entA == null || entB == null)
			{
				return;
			}

			var actor:EntityNapeSprite = null;
			var obstacle:EntityNapeSprite = null;

			var int1HasTag1 = cb.int1.cbTypes.has(cb1) || (cb.int1.isShape() && cb.int1.castShape.body != null && cb.int1.castShape.body.cbTypes.has(cb1));
			if (int1HasTag1)
			{
				actor = entA;
				obstacle = entB;
			}
			else
			{
				actor = entB;
				obstacle = entA;
			}

			if (actor.resolvePixelCollision(obstacle))
			{
				if (onCollision != null)
				{
					onCollision(actor, obstacle);
				}
			}
		});
	}
}
