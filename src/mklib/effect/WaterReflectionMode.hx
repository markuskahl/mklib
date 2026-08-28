package mklib.effect;

/**
 * Aufzählung der unterstützten Betriebsmodi für den `WaterReflectionShader`.
 */
enum abstract WaterReflectionMode(Int) from Int to Int {
	/**
	 * Klassische 2D-Wasseroberfläche: Spiegelt die Szene oberhalb der horizontalen Wasserlinie
	 * vertikal nach unten und wendet Wellenverzerrung, Färbung und Tiefenfading an.
	 */
	var VERTICAL_WATER_PLANE = 0;

	/**
	 * Horizontaler Spiegel: Spiegelt die Szene links oder rechts an einer vertikalen Spiegelachse
	 * mit horizontalem Wellenversatz (z. B. für magische Spiegel, Portale oder seitliche Wasserwände).
	 */
	var HORIZONTAL_MIRROR = 1;

	/**
	 * Reine Wellenverzerrung: Verändert die Texturkoordinaten organisch mit Sinus-Wellen,
	 * ohne die Achsen zu spiegeln (ideal für animierte Wasser-Texturen oder bereits geflippte Sprites).
	 */
	var WAVE_DISTORTION_ONLY = 2;
}
