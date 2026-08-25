package mklib.math;

/**
 * Mathematische Hilfsfunktionen und Berechnungen.
 */
class MathTool
{
	/**
	 * Rundet eine Gleitkommazahl (`Float`) auf eine feste Anzahl von Nachkommastellen.
	 *
	 * Ungültige oder unendliche Werte (`NaN`, `Infinity`) werden unverändert zurückgegeben.
	 *
	 * @param v Die zu rundende Gleitkommazahl.
	 * @param length Die Anzahl der gewünschten Nachkommastellen (z. B. 2).
	 * @return Die gerundete Gleitkommazahl.
	 */
	public inline static function floatFix(v:Float, length:Int):Float
	{
		if (Math.isNaN(v) || !Math.isFinite(v))
		{
			return v;
		}
		var factor:Float = Math.pow(10, length);
		return Math.round(v * factor) / factor;
	}
}
