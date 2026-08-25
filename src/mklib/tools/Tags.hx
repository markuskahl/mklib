package mklib.tools;

import mklib.state.State;
import flixel.FlxG;
import nape.callbacks.CbType;

/**
 * Statische Hilfsklasse zum Abrufen von Nape-`CbType`-Objekten, die im aktuellen `State`
 * aus dem LDtk-Enum "Tags" registriert wurden.
 */
class Tags
{
	/**
	 * Gibt das `CbType`-Objekt für einen gegebenen Tag-Namen aus dem aktuellen `State` zurück.
	 *
	 * @param tag Der Name des Tags (z. B. "Player", "Solid", "Coin").
	 * @return Die zugehörige `CbType`-Instanz oder `null`, falls nicht gefunden oder kein `State` aktiv ist.
	 */
	public static function get(tag:String):CbType
	{
		if (tag == null || FlxG.state == null || !Std.isOfType(FlxG.state, State))
		{
			return null;
		}
		var state:State = cast FlxG.state;
		if (state.tags == null)
		{
			return null;
		}
		return state.tags.get(tag);
	}

	/**
	 * Prüft, ob ein gegebener Tag-Name in der Tag-Map des aktuellen `State` registriert ist.
	 *
	 * @param tag Der Name des zu prüfenden Tags.
	 * @return `true`, wenn der Tag existiert, sonst `false`.
	 */
	public static function exist(tag:String):Bool
	{
		if (tag == null || FlxG.state == null || !Std.isOfType(FlxG.state, State))
		{
			return false;
		}
		var state:State = cast FlxG.state;
		if (state.tags == null)
		{
			return false;
		}
		return state.tags.exists(tag);
	}
}