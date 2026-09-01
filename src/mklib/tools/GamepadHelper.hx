package mklib.tools;

#if (!FLX_NO_GAMEPAD && lime)
import flixel.FlxG;
import lime.ui.Gamepad as LimeGamepad;
#end

/**
 * Hilfsklasse für Gamepad-spezifische Hardware-Funktionen wie Controller-Vibration (Rumble).
 *
 * Verbindet das Gamepad-System von HaxeFlixel (`FlxGamepad`) mit der nativen Hardware-Schnittstelle
 * von Lime (`lime.ui.Gamepad.rumble`), um präzise Vibrations-Effekte (z. B. bei Treffern, Explosionen
 * oder Interaktionen) auszulösen.
 */
class GamepadHelper
{
	/**
	 * Löst eine Controller-Vibration auf dem angegebenen Gamepad aus.
	 *
	 * @param gamepadID  ID des FlxGamepad (Standard: `0` für Spieler 1 / erstes Gamepad).
	 * @param lowFreq    Intensität des starken/tiefen Motors (Bereich `0.0` bis `1.0`, Standard: `0.5`).
	 * @param highFreq   Intensität des feinen/hohen Motors (Bereich `0.0` bis `1.0`, Standard: `0.5`).
	 * @param durationMs Dauer der Vibration in Millisekunden (Standard: `200` ms).
	 */
	public static function vibrate(gamepadID:Int = 0, lowFreq:Float = 0.5, highFreq:Float = 0.5, durationMs:Int = 200):Void
	{
		#if (!FLX_NO_GAMEPAD && lime)
		if (FlxG.gamepads == null)
			return;

		var flxGamepad = FlxG.gamepads.getByID(gamepadID);
		if (flxGamepad == null)
			return;

		// Entsprechendes Lime-Gamepad über die Hardware-ID abrufen
		var limeGamepad:LimeGamepad = LimeGamepad.devices.get(flxGamepad.id);
		if (limeGamepad != null)
		{
			limeGamepad.rumble(lowFreq, highFreq, durationMs);
		}
		#end
	}

	/**
	 * Alias für `vibrate`. Löst ein Rumble-Feedback auf dem angegebenen Gamepad aus.
	 *
	 * @param gamepadID  ID des FlxGamepad (Standard: `0`).
	 * @param lowFreq    Starker Motor (`0.0` bis `1.0`).
	 * @param highFreq   Hoher Motor (`0.0` bis `1.0`).
	 * @param durationMs Dauer in Millisekunden.
	 */
	public static inline function rumble(gamepadID:Int = 0, lowFreq:Float = 0.5, highFreq:Float = 0.5, durationMs:Int = 200):Void
	{
		vibrate(gamepadID, lowFreq, highFreq, durationMs);
	}

	/**
	 * Stoppt die Vibration auf dem angegebenen Gamepad sofort.
	 *
	 * @param gamepadID ID des FlxGamepad (Standard: `0`).
	 */
	public static function stopVibration(gamepadID:Int = 0):Void
	{
		vibrate(gamepadID, 0.0, 0.0, 0);
	}

	/**
	 * Löst eine Controller-Vibration auf allen aktuell verbundenen Gamepads aus.
	 *
	 * @param lowFreq    Intensität des starken Motors (`0.0` bis `1.0`, Standard: `0.5`).
	 * @param highFreq   Intensität des feinen Motors (`0.0` bis `1.0`, Standard: `0.5`).
	 * @param durationMs Dauer in Millisekunden (Standard: `200` ms).
	 */
	public static function vibrateAll(lowFreq:Float = 0.5, highFreq:Float = 0.5, durationMs:Int = 200):Void
	{
		#if (!FLX_NO_GAMEPAD && lime)
		if (FlxG.gamepads == null)
			return;

		var activeGamepads = FlxG.gamepads.getActiveGamepads();
		if (activeGamepads != null)
		{
			for (pad in activeGamepads)
			{
				if (pad != null)
				{
					var limeGamepad:LimeGamepad = LimeGamepad.devices.get(pad.id);
					if (limeGamepad != null)
					{
						limeGamepad.rumble(lowFreq, highFreq, durationMs);
					}
				}
			}
		}
		#end
	}

	/**
	 * Stoppt die Vibration auf allen verbundenen Gamepads.
	 */
	public static function stopAllVibrations():Void
	{
		vibrateAll(0.0, 0.0, 0);
	}

	/**
	 * Gibt die native `lime.ui.Gamepad`-Instanz für ein gegebenes `FlxGamepad` zurück.
	 *
	 * @param gamepadID ID des FlxGamepad (Standard: `0`).
	 * @return Die zugehörige `lime.ui.Gamepad`-Instanz oder `null`, falls nicht vorhanden.
	 */
	#if (!FLX_NO_GAMEPAD && lime)
	public static function getLimeGamepad(gamepadID:Int = 0):LimeGamepad
	{
		if (FlxG.gamepads == null)
			return null;

		var flxGamepad = FlxG.gamepads.getByID(gamepadID);
		if (flxGamepad == null)
			return null;

		return LimeGamepad.devices.get(flxGamepad.id);
	}
	#end
}
