package mklib.effect;

/**
 * Aufzählung der unterstützten Flüssigkeitstypen für `HazardLiquidShader` und `HazardLiquidPlane`.
 */
enum abstract HazardLiquidType(String) from String to String {
	/**
	 * Glühende Lava / flüssiges Magma (Dunkelrot, Orange, Gelb, mit schwarzer Kruste).
	 */
	var LAVA = "lava";

	/**
	 * Ätzende Säure / toxischer Schleim (Dunkelgrün, Neon-Hellgrün, Gelb-Glühen).
	 */
	var ACID_SLIME = "acid_slime";

	/**
	 * Verseuchtes Giftwasser / Lila Morast (Dunkelviolett, Magenta, Glühkante).
	 */
	var TOXIC_WATER = "toxic_water";

	/**
	 * Benutzerdefinierte Flüssigkeit mit frei konfigurierbaren Farbverläufen und Parametern.
	 */
	var CUSTOM = "custom";
}
