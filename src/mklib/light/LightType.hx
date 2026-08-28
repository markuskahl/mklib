package mklib.light;

/**
 * Aufzählung der unterstützten Licht-Typen für das GPU-Shader-Lighting-System.
 */
enum abstract LightType(Int) from Int to Int {
	/**
	 * Omnidirektionales Punktlicht (360° Abstrahlung).
	 */
	var POINT = 0;

	/**
	 * Gerichteter Scheinwerfer mit Kegel- und Fokuswinkel.
	 */
	var SPOT = 1;

	/**
	 * Dynamisch und organisch flackerndes Fackelfeuer / Kerzenlicht.
	 */
	var TORCH = 2;

	/**
	 * Pulsierendes Aura- / Magie- / Breathing-Licht.
	 */
	var GLOW = 3;

	/**
	 * Globales Umgebungs- / Richtungslicht (z. B. Sonne oder Mond).
	 */
	var DIRECTIONAL = 4;

	/**
	 * Wandelt einen Text-Identifier (z. B. aus LDtk) in einen `LightType` um.
	 *
	 * @param str Der Name des Lichttyps (z. B. "point", "spot", "torch", "glow", "directional").
	 * @param defaultType Fallback, falls der String nicht zugeordnet werden kann (Standard: `POINT`).
	 * @return Der passende `LightType`.
	 */
	public static function fromString(str:Null<String>, defaultType:LightType = POINT):LightType {
		if (str == null) {
			return defaultType;
		}

		var lower = StringTools.trim(str.toLowerCase());
		return switch (lower) {
			case "point", "pointlight", "lamp", "bulb", "circle": POINT;
			case "spot", "spotlight", "cone", "flashlight", "headlight": SPOT;
			case "torch", "torchlight", "fire", "flame", "candle", "campfire", "flicker": TORCH;
			case "glow", "glowlight", "pulse", "pulselight", "aura", "crystal", "magic": GLOW;
			case "directional", "sun", "sunlight", "moon", "moonlight", "ambient": DIRECTIONAL;
			default: defaultType;
		}
	}

	/**
	 * Gibt den lesbaren Namen des Lichttyps zurück.
	 */
	public function toString():String {
		return switch (this) {
			case POINT: "PointLight";
			case SPOT: "SpotLight";
			case TORCH: "TorchLight";
			case GLOW: "GlowLight";
			case DIRECTIONAL: "DirectionalLight";
			default: "UnknownLight";
		}
	}
}
