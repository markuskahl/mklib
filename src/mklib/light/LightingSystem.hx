package mklib.light;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import mklib.layer.EntityLayer.EntityLayerSource;
import mklib.light.shader.LightingShader;
import openfl.display.BlendMode;

/**
 * Zentraler Manager und GPU-Shader-Renderer für dynamisches 2D-Licht in `mklib`.
 *
 * Verwaltet Lichtquellen (`PointLight`, `SpotLight`, `TorchLight`, `GlowLight`, `DirectionalLight`),
 * führt Viewport-/Frustum-Culling durch und rendert das finale Licht hardwarebeschleunigt
 * über den `LightingShader` als Multi-Light-Overlay (Standardmäßig mit `BlendMode.MULTIPLY`).
 *
 * Das Beleuchtungssystem wird üblicherweise wie ein `FlxSprite` zur Szene hinzugefügt:
 * ```haxe
 * var lighting = new LightingSystem(0xFF141424, 0.2);
 * add(lighting);
 * ```
 *
 * Bietet zudem bequeme Factory-Methoden zur programmatischen Lichterstellung sowie
 * automatische Erkennung und Instanziierung aus LDtk-Leveldaten anhand von Custom Properties.
 */
class LightingSystem extends FlxSprite {
	/**
	 * Maximale Anzahl an gleichzeitig an die GPU übergebenen Lichtern pro Viewport/Kamera (Standard: 32).
	 */
	public static inline var MAX_LIGHTS:Int = 32;

	/**
	 * Liste aller aktuell registrierten Lichtquellen in der Spielwelt.
	 */
	public var lights:Array<Light> = [];

	/**
	 * Die Umgebungs-Grundfarbe (Ambient Color), die überall dort sichtbar ist,
	 * wo keine Lichtquellen hinleuchten (Standard: Dunkles Nachtblau `0xFF141424`).
	 */
	public var ambientColor:FlxColor = 0xFF141424;

	/**
	 * Die Grundhelligkeit des Umgebungslichts (0.0 = absolute Dunkelheit, 1.0 = volle Ausleuchtung, Standard: 0.2).
	 */
	public var ambientIntensity:Float = 0.2;

	/**
	 * Aktiviert automatisches Frustum-Culling. Wenn `true`, werden nur diejenigen Lichter
	 * an den GPU-Shader übermittelt, die sich tatsächlich im sichtbaren Bereich der Kamera befinden.
	 */
	public var autoCull:Bool = true;

	/**
	 * Die Instanz des GPU-Multi-Light-Shaders (`LightingShader`), der das Lichtbild berechnet.
	 */
	public var shaderInstance(default, null):LightingShader;

	// Wiederverwendbare Puffer-Arrays zur Vermeidung von Garbage-Collector-Allokationen während der Render-Schleife
	private var _posBuffer:Array<Float> = [];
	private var _colorBuffer:Array<Float> = [];
	private var _paramsBuffer:Array<Float> = [];
	private var _spotBuffer:Array<Float> = [];

	/**
	 * Erstellt ein neues Beleuchtungssystem.
	 *
	 * @param ambientColor Die Grundfarbe der Dunkelheit / Umgebung (Standard: `0xFF141424`).
	 * @param ambientIntensity Die Helligkeit des Umgebungslichts von `0.0` (stockdunkel) bis `1.0` (taghell, Standard: `0.2`).
	 */
	public function new(ambientColor:FlxColor = 0xFF141424, ambientIntensity:Float = 0.2) {
		super(0, 0);
		this.ambientColor = ambientColor;
		this.ambientIntensity = ambientIntensity;

		scrollFactor.set(0, 0);
		blend = BlendMode.MULTIPLY;

		shaderInstance = new LightingShader();
		this.shader = shaderInstance;

		makeGraphic(FlxG.width > 0 ? FlxG.width : 320, FlxG.height > 0 ? FlxG.height : 180, FlxColor.WHITE);

		initBuffers();
	}

	/**
	 * Initialisiert die internen Puffer-Arrays auf die durch `MAX_LIGHTS` festgelegte Größe.
	 * Dadurch werden wiederholte Array-Allokationen in jedem Frame vermieden.
	 */
	private function initBuffers():Void {
		_posBuffer = [for (i in 0...(MAX_LIGHTS * 2)) 0.0];
		_colorBuffer = [for (i in 0...(MAX_LIGHTS * 4)) 0.0];
		_paramsBuffer = [for (i in 0...(MAX_LIGHTS * 4)) 0.0];
		_spotBuffer = [for (i in 0...(MAX_LIGHTS * 4)) 0.0];
	}

	/**
	 * Registriert eine existierende Lichtquelle im System.
	 *
	 * @param light Die hinzuzufügende Lichtquelle (z. B. `PointLight`, `SpotLight`, `TorchLight` etc.).
	 * @return Die übergebene Lichtquelle zur bequemen Verkettung (Fluent Interface).
	 */
	public function addLight<T:Light>(light:T):T {
		if (light != null && lights.indexOf(light) == -1) {
			lights.push(light);
		}
		return light;
	}

	/**
	 * Entfernt eine Lichtquelle aus dem System.
	 *
	 * @param light Die zu entfernende Lichtquelle.
	 * @param destroy Wenn `true`, wird zusätzlich `light.destroy()` aufgerufen (Standard: `false`).
	 * @return Die entfernte Lichtquelle.
	 */
	public function removeLight<T:Light>(light:T, destroy:Bool = false):T {
		if (light != null) {
			lights.remove(light);
			if (destroy) {
				light.destroy();
			}
		}
		return light;
	}

	/**
	 * Entfernt alle registrierten Lichtquellen aus dem System.
	 *
	 * @param destroy Wenn `true`, werden alle Lichter zusätzlich zerstört (Standard: `true`).
	 */
	public function clearLights(destroy:Bool = true):Void {
		if (destroy) {
			for (l in lights) {
				if (l != null) {
					l.destroy();
				}
			}
		}
		lights = [];
	}

	/**
	 * Gibt die Gesamtzahl aller aktuell registrierten Lichtquellen zurück.
	 *
	 * @return Anzahl der Lichter im Array `lights`.
	 */
	public inline function getLightCount():Int {
		return lights.length;
	}

	// =========================================================================
	// Programmatische Factory-Hilfsmethoden
	// =========================================================================

	/**
	 * Erstellt und registriert ein neues omnidirektionales Punktlicht (`PointLight`),
	 * das gleichmäßig in alle Richtungen (360°) strahlt.
	 *
	 * @param x X-Koordinate der Lichtquelle in Weltpixeln.
	 * @param y Y-Koordinate der Lichtquelle in Weltpixeln.
	 * @param radius Gesamtradius des Lichtkreises in Pixeln (Standard: 100).
	 * @param color Farbe des Lichts als `FlxColor` (Standard: Weiß `0xFFFFFFFF`).
	 * @param intensity Helligkeitsmultiplikator des Lichts (Standard: 1.0).
	 * @param innerRadius Radius des inneren Kernbereichs in Pixeln mit 100% voller Helligkeit (Standard: 0.0).
	 * @param falloff Dämpfungsexponent des Helligkeitsabfalls zum Rand hin (1.0 = linear, > 1.0 = steilerer Abfall, Standard: 1.0).
	 * @return Die erstellte und registrierte `PointLight`-Instanz.
	 */
	public function createPointLight(x:Float, y:Float, radius:Float = 100, color:FlxColor = FlxColor.WHITE, intensity:Float = 1.0, innerRadius:Float = 0.0, falloff:Float = 1.0):PointLight {
		var light = new PointLight(x, y, radius, color, intensity, innerRadius, falloff);
		return addLight(light);
	}

	/**
	 * Erstellt und registriert einen neuen gerichteten Scheinwerfer (`SpotLight`),
	 * der einen Lichtkegel in eine bestimmte Richtung wirft (z. B. Taschenlampe oder Suchscheinwerfer).
	 *
	 * @param x X-Koordinate des Scheinwerfers in Weltpixeln.
	 * @param y Y-Koordinate des Scheinwerfers in Weltpixeln.
	 * @param radius Reichweite des Lichtstrahls in Pixeln (Standard: 150).
	 * @param angle Abstrahlrichtung in **Grad** (0° = nach rechts, 90° = nach unten, 180° = nach links, 270° = nach oben, Standard: 0°).
	 * @param spotAngle Gesamt-Öffnungswinkel des Lichtkegels in **Grad** (z. B. 45° für schmalen Kegel, 360° für Vollkreis, Standard: 45°).
	 * @param color Farbe des Lichts als `FlxColor` (Standard: Weiß `0xFFFFFFFF`).
	 * @param intensity Helligkeitsmultiplikator (Standard: 1.0).
	 * @param innerAngle Innerer Fokuswinkel in **Grad**, innerhalb dessen maximale Helligkeit herrscht, bevor der weiche Randverlauf einsetzt (Standard: 15°).
	 * @param falloff Dämpfungsexponent des Lichtabfalls (Standard: 1.0).
	 * @return Die erstellte und registrierte `SpotLight`-Instanz.
	 */
	public function createSpotLight(x:Float, y:Float, radius:Float = 150, angle:Float = 0, spotAngle:Float = 45, color:FlxColor = FlxColor.WHITE, intensity:Float = 1.0, innerAngle:Float = 15, falloff:Float = 1.0):SpotLight {
		var light = new SpotLight(x, y, radius, angle, spotAngle, color, intensity, innerAngle, falloff);
		return addLight(light);
	}

	/**
	 * Erstellt und registriert eine dynamisch flackernde Fackellichtquelle (`TorchLight`),
	 * die Radius, Helligkeit und Position organisch oszillieren lässt.
	 *
	 * @param x X-Koordinate in Weltpixeln.
	 * @param y Y-Koordinate in Weltpixeln.
	 * @param radius Basisradius des Fackelscheins in Pixeln (Standard: 120).
	 * @param color Farbe des Feuerscheins (Standard: Warmes Fackelorange `0xFFFFAA44`).
	 * @param intensity Basis-Helligkeitsmultiplikator (Standard: 1.0).
	 * @param flickerSpeed Geschwindigkeit des Flackerns und der Oszillation (Standard: 8.0).
	 * @param flickerIntensity Maximale Helligkeitsschwankung beim Flackern (Standard: 0.15).
	 * @param flickerRadius Maximale Radiusschwankung in Pixeln nach oben/unten (Standard: 10.0).
	 * @param flameJitter Maximaler zufälliger Positions-Versatz (Jitter) der Flamme in Pixeln (Standard: 2.0).
	 * @return Die erstellte und registrierte `TorchLight`-Instanz.
	 */
	public function createTorchLight(x:Float, y:Float, radius:Float = 120, color:FlxColor = 0xFFFFAA44, intensity:Float = 1.0, flickerSpeed:Float = 8.0, flickerIntensity:Float = 0.15, flickerRadius:Float = 10.0, flameJitter:Float = 2.0):TorchLight {
		var light = new TorchLight(x, y, radius, color, intensity, flickerSpeed, flickerIntensity, flickerRadius, flameJitter);
		return addLight(light);
	}

	/**
	 * Erstellt und registriert eine harmonisch pulsierende Aura-Lichtquelle (`GlowLight`),
	 * die ihren Radius und ihre Helligkeit sinusförmig verändert (z. B. für magische Kristalle oder Portale).
	 *
	 * @param x X-Koordinate in Weltpixeln.
	 * @param y Y-Koordinate in Weltpixeln.
	 * @param minRadius Minimaler Radius der Pulsation in Pixeln (Standard: 40).
	 * @param maxRadius Maximaler Radius der Pulsation in Pixeln (Standard: 80).
	 * @param color Farbe des Leuchtens (Standard: Sanftes Magie-Blau `0xFF55AAFF`).
	 * @param minIntensity Minimale Helligkeit am Tiefpunkt der Pulsation (Standard: 0.4).
	 * @param maxIntensity Maximale Helligkeit am Hochpunkt der Pulsation (Standard: 1.0).
	 * @param pulseSpeed Geschwindigkeit der Pulsation in Radiant pro Sekunde (Standard: 2.0).
	 * @param pulsePhase Startphase der Sinuswelle in Radiant (Standard: 0.0).
	 * @return Die erstellte und registrierte `GlowLight`-Instanz.
	 */
	public function createGlowLight(x:Float, y:Float, minRadius:Float = 40, maxRadius:Float = 80, color:FlxColor = 0xFF55AAFF, minIntensity:Float = 0.4, maxIntensity:Float = 1.0, pulseSpeed:Float = 2.0, pulsePhase:Float = 0.0):GlowLight {
		var light = new GlowLight(x, y, minRadius, maxRadius, color, minIntensity, maxIntensity, pulseSpeed, pulsePhase);
		return addLight(light);
	}

	/**
	 * Erstellt und registriert ein globales, positionsunabhängiges Richtungslicht (`DirectionalLight`),
	 * das die gesamte Szene gleichmäßig aus einem bestimmten Einstrahlwinkel erhellt (z. B. Sonnen- oder Mondlicht).
	 *
	 * @param directionAngle Einstrahlwinkel des Lichts in **Grad** (Standard: 45.0°).
	 * @param color Farbe des Lichts (Standard: Warmes Sonnenlicht `0xFFFFF8EE`).
	 * @param intensity Helligkeitsfaktor des Richtungslichts (Standard: 0.5).
	 * @return Die erstellte und registrierte `DirectionalLight`-Instanz.
	 */
	public function createDirectionalLight(directionAngle:Float = 45.0, color:FlxColor = 0xFFFFF8EE, intensity:Float = 0.5):DirectionalLight {
		var light = new DirectionalLight(directionAngle, color, intensity);
		return addLight(light);
	}

	// =========================================================================
	// LDtk Custom-Properties Parser & Level-Integration
	// =========================================================================

	/**
	 * Parst eine LDtk-Entity und erzeugt anhand ihrer benutzerdefinierten Felder (`fieldInstances`)
	 * die passende `Light`-Instanz (`PointLight`, `SpotLight`, `TorchLight`, `GlowLight` oder `DirectionalLight`).
	 *
	 * Unterstützt flexible Feldnamen (z. B. `radius`, `light_radius`, `color`, `intensity`, `spotAngle` etc.)
	 * und konvertiert LDtk-Farbwerte und Offsets automatisch.
	 *
	 * @param entity Die aus LDtk geladene Entity-Definition (`ldtk.Entity`).
	 * @return Die erzeugte `Light`-Instanz oder `null`, falls die Entity keine Lichtdefinition darstellt.
	 */
	public static function fromEntity(entity:ldtk.Entity):Null<Light> {
		if (entity == null) {
			return null;
		}

		// Prüfen, ob Entity als Licht markiert ist
		var identifier = entity.identifier;
		var rawType:Null<String> = getEntityField(entity, "type");
		if (rawType == null) {
			rawType = getEntityField(entity, "light_type");
		}
		if (rawType == null) {
			rawType = getEntityField(entity, "lightType");
		}

		var isLightEntity = rawType != null || StringTools.contains(identifier.toLowerCase(), "light") || StringTools.contains(identifier.toLowerCase(), "torch") || StringTools.contains(identifier.toLowerCase(), "lamp") || StringTools.contains(identifier.toLowerCase(), "candle") || StringTools.contains(identifier.toLowerCase(), "glow") || StringTools.contains(identifier.toLowerCase(), "spot");

		if (!isLightEntity && !hasEntityField(entity, "radius") && !hasEntityField(entity, "light_radius")) {
			return null;
		}

		var lightType:LightType = LightType.fromString(rawType != null ? rawType : identifier, POINT);

		// Basis-Felder extrahieren
		var radius:Float = getFloatParam(entity, ["radius", "light_radius", "Radius"], 100.0);
		var intensity:Float = getFloatParam(entity, ["intensity", "light_intensity", "Intensity"], 1.0);
		var falloff:Float = getFloatParam(entity, ["falloff", "light_falloff", "Falloff"], 1.0);
		var color:FlxColor = getColorParam(entity, ["color", "light_color", "Color"], lightType == TORCH ? 0xFFFFAA44 : (lightType == GLOW ? 0xFF55AAFF : FlxColor.WHITE));
		var active:Bool = getBoolParam(entity, ["active", "enabled", "light_active"], true);

		var offsetX:Float = getFloatParam(entity, ["offsetX", "offset_x", "pivotX"], entity.width * 0.5);
		var offsetY:Float = getFloatParam(entity, ["offsetY", "offset_y", "pivotY"], entity.height * 0.5);
		var posX:Float = entity.pixelX + offsetX;
		var posY:Float = entity.pixelY + offsetY;

		var light:Light;

		switch (lightType) {
			case SPOT:
				var angle:Float = getFloatParam(entity, ["angle", "direction", "light_angle", "Angle"], 0.0);
				var spotAngle:Float = getFloatParam(entity, ["spotAngle", "cone", "coneAngle", "light_spotAngle"], 45.0);
				var innerAngle:Float = getFloatParam(entity, ["innerAngle", "focusAngle", "light_innerAngle"], 15.0);
				light = new SpotLight(posX, posY, radius, angle, spotAngle, color, intensity, innerAngle, falloff);

			case TORCH:
				var flickerSpeed:Float = getFloatParam(entity, ["flickerSpeed", "speed", "light_flickerSpeed"], 8.0);
				var flickerIntensity:Float = getFloatParam(entity, ["flickerIntensity", "flickerAmount", "light_flickerIntensity"], 0.15);
				var flickerRadius:Float = getFloatParam(entity, ["flickerRadius", "light_flickerRadius"], 10.0);
				var flameJitter:Float = getFloatParam(entity, ["flameJitter", "jitter", "light_flameJitter"], 2.0);
				light = new TorchLight(posX, posY, radius, color, intensity, flickerSpeed, flickerIntensity, flickerRadius, flameJitter);

			case GLOW:
				var minRadius:Float = getFloatParam(entity, ["minRadius", "light_minRadius"], radius * 0.5);
				var maxRadius:Float = getFloatParam(entity, ["maxRadius", "light_maxRadius"], radius);
				var minIntensity:Float = getFloatParam(entity, ["minIntensity", "light_minIntensity"], intensity * 0.4);
				var maxIntensity:Float = getFloatParam(entity, ["maxIntensity", "light_maxIntensity"], intensity);
				var pulseSpeed:Float = getFloatParam(entity, ["pulseSpeed", "speed", "light_pulseSpeed"], 2.0);
				var pulsePhase:Float = getFloatParam(entity, ["pulsePhase", "phase", "light_pulsePhase"], 0.0);
				light = new GlowLight(posX, posY, minRadius, maxRadius, color, minIntensity, maxIntensity, pulseSpeed, pulsePhase);

			case DIRECTIONAL:
				var dirAngle:Float = getFloatParam(entity, ["directionAngle", "angle", "direction"], 45.0);
				light = new DirectionalLight(dirAngle, color, intensity);

			case POINT:
				var innerRadius:Float = getFloatParam(entity, ["innerRadius", "coreRadius", "light_innerRadius"], 0.0);
				light = new PointLight(posX, posY, radius, color, intensity, innerRadius, falloff);
		}

		light.active = active;
		light.visible = active;
		return light;
	}

	/**
	 * Liest alle Licht-Entities aus einer LDtk-Entity-Layer-Quelle (z. B. `data.l_Lights` oder `data.l_Entities`)
	 * aus, konvertiert sie automatisch in Lichtquellen und fügt sie diesem System hinzu.
	 *
	 * @param layer Die LDtk-Layer-Quelle (`EntityLayerSource`).
	 * @return Anzahl der erfolgreich geladenen und hinzugefügten Lichter.
	 */
	public function loadFromEntityLayer(layer:EntityLayerSource<Dynamic>):Int {
		if (layer == null) {
			return 0;
		}

		var count = 0;
		var untypedList = layer.getAllUntyped();
		if (untypedList != null) {
			for (e in untypedList) {
				var entity:ldtk.Entity = cast e;
				var light = fromEntity(entity);
				if (light != null) {
					addLight(light);
					count++;
				}
			}
		}
		return count;
	}

	/**
	 * Durchsucht alle Layer eines LDtk-Level-Objekts (alle Felder mit dem Präfix `l_`)
	 * nach Licht-Entities und lädt diese automatisch in das Beleuchtungssystem.
	 *
	 * @param levelData Das LDtk-Level-Objekt (z. B. `state.data` bzw. `project.all_worlds...`).
	 * @return Gesamtzahl der erfolgreich geladenen und registrierten Lichter.
	 */
	public function loadFromLevel(levelData:Dynamic):Int {
		if (levelData == null) {
			return 0;
		}

		var total = 0;
		var fields = Reflect.fields(levelData);
		for (f in fields) {
			if (StringTools.startsWith(f, "l_")) {
				var layerObj = Reflect.field(levelData, f);
				if (layerObj != null && Reflect.hasField(layerObj, "getAllUntyped")) {
					total += loadFromEntityLayer(cast layerObj);
				}
			}
		}
		return total;
	}

	// =========================================================================
	// LDtk Hilfsfunktionen für Feld-Auslesung
	// =========================================================================

	/**
	 * Liest den Rohwert eines benutzerdefinierten Feldes (Custom Property) aus den LDtk-JSON-Daten einer Entity aus.
	 *
	 * @param entity Die zu prüfende LDtk-Entity.
	 * @param identifier Der Bezeichner des Felds (z. B. `"radius"`, `"color"`).
	 * @return Der Wert des Feldes oder `null`, falls nicht vorhanden.
	 */
	private static function getEntityField(entity:ldtk.Entity, identifier:String):Dynamic {
		if (entity != null && entity.json != null && entity.json.fieldInstances != null) {
			for (inst in entity.json.fieldInstances) {
				if (inst.__identifier == identifier) {
					return inst.__value;
				}
			}
		}
		return null;
	}

	/**
	 * Prüft, ob eine LDtk-Entity ein bestimmtes Feld besitzt und dieses nicht `null` ist.
	 *
	 * @param entity Die zu prüfende LDtk-Entity.
	 * @param identifier Der Bezeichner des Felds.
	 * @return `true`, wenn das Feld mit einem gültigen Wert existiert, sonst `false`.
	 */
	private static function hasEntityField(entity:ldtk.Entity, identifier:String):Bool {
		if (entity != null && entity.json != null && entity.json.fieldInstances != null) {
			for (inst in entity.json.fieldInstances) {
				if (inst.__identifier == identifier && inst.__value != null) {
					return true;
				}
			}
		}
		return false;
	}

	/**
	 * Sucht eine Liste möglicher Feldnamen in einer LDtk-Entity nach einer Zahl (Float/Int) ab
	 * und gibt den ersten gefundenen Wert zurück.
	 *
	 * @param entity Die LDtk-Entity.
	 * @param keys Liste alternativer Feldnamen (z. B. `["radius", "light_radius"]`).
	 * @param defaultValue Der Fallback-Standardwert, falls kein passendes Feld gefunden wird.
	 * @return Der gefundene Float-Wert oder `defaultValue`.
	 */
	private static function getFloatParam(entity:ldtk.Entity, keys:Array<String>, defaultValue:Float):Float {
		for (k in keys) {
			var val = getEntityField(entity, k);
			if (val != null) {
				if (Std.isOfType(val, Float) || Std.isOfType(val, Int)) {
					return cast val;
				}
				var parsed = Std.parseFloat(Std.string(val));
				if (!Math.isNaN(parsed)) {
					return parsed;
				}
			}
		}
		return defaultValue;
	}

	/**
	 * Sucht eine Liste möglicher Feldnamen in einer LDtk-Entity nach einem booleschen Wert ab.
	 *
	 * @param entity Die LDtk-Entity.
	 * @param keys Liste alternativer Feldnamen (z. B. `["active", "enabled"]`).
	 * @param defaultValue Der Fallback-Standardwert.
	 * @return Der boolesche Wert oder `defaultValue`.
	 */
	private static function getBoolParam(entity:ldtk.Entity, keys:Array<String>, defaultValue:Bool):Bool {
		for (k in keys) {
			var val = getEntityField(entity, k);
			if (val != null) {
				if (Std.isOfType(val, Bool)) {
					return cast val;
				}
				return Std.string(val).toLowerCase() == "true";
			}
		}
		return defaultValue;
	}

	/**
	 * Sucht eine Liste möglicher Feldnamen in einer LDtk-Entity nach einem Farbwert ab
	 * und konvertiert Int-Farbwerte (0xRRGGBB bzw. 0xAARRGGBB) oder Hex-Strings (z. B. `"#FF9900"`).
	 *
	 * @param entity Die LDtk-Entity.
	 * @param keys Liste alternativer Feldnamen (z. B. `["color", "light_color"]`).
	 * @param defaultColor Die Fallback-Farbe als `FlxColor`.
	 * @return Die ermittelte `FlxColor` oder `defaultColor`.
	 */
	private static function getColorParam(entity:ldtk.Entity, keys:Array<String>, defaultColor:FlxColor):FlxColor {
		for (k in keys) {
			var val = getEntityField(entity, k);
			if (val != null) {
				if (Std.isOfType(val, Int)) {
					var intVal:Int = cast val;
					// LDtk liefert Farben meist als 0xRRGGBB ohne Alpha-Kanal
					if ((intVal & 0xFF000000) == 0) {
						intVal |= 0xFF000000;
					}
					return FlxColor.fromInt(intVal);
				}
				if (Std.isOfType(val, String)) {
					var strVal:String = cast val;
					if (StringTools.startsWith(strVal, "#")) {
						return FlxColor.fromString(strVal);
					}
				}
			}
		}
		return defaultColor;
	}

	// =========================================================================
	// Update- & Render-Schleife
	// =========================================================================

	/**
	 * Aktualisiert das Beleuchtungssystem und ruft `update(elapsed)` für alle aktiven Lichter auf
	 * (wichtig für Oszillationen bei `TorchLight` und `GlowLight` sowie Follow-Ziele).
	 *
	 * @param elapsed Vergangene Zeit seit dem letzten Frame in Sekunden.
	 */
	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		// Alle aktiven Lichter aktualisieren
		for (light in lights) {
			if (light != null && light.active) {
				light.update(elapsed);
			}
		}
	}

	/**
	 * Rendert das Beleuchtungs-Overlay:
	 * 1. Passt die Grafikgröße dynamisch an die Kameraauflösung an.
	 * 2. Ermittelt sichtbare Lichter via Frustum-Culling (`autoCull`).
	 * 3. Befüllt die Shader-Uniform-Puffer (Positionen, Farben, Radien, Spot-Parameter).
	 * 4. Führt den GPU-Draw-Call mit Multi-Light-Shader aus.
	 */
	override public function draw():Void {
		var cam:FlxCamera = (camera != null) ? camera : FlxG.camera;
		if (cam == null || !visible) {
			return;
		}

		// Grafikgröße an Kamera anpassen falls nötig
		var camW = (cam.width > 0) ? cam.width : FlxG.width;
		var camH = (cam.height > 0) ? cam.height : FlxG.height;
		if (width != camW || height != camH) {
			makeGraphic(camW, camH, FlxColor.WHITE);
		}

		// Sichtbare Lichter ermitteln (Frustum Culling)
		var camLeft = cam.scroll.x;
		var camTop = cam.scroll.y;
		var camRight = camLeft + (camW / cam.zoom);
		var camBottom = camTop + (camH / cam.zoom);

		var visibleLights:Array<Light> = [];

		for (light in lights) {
			if (light == null || !light.visible) {
				continue;
			}

			if (light.lightType == DIRECTIONAL) {
				visibleLights.push(light);
			} else if (autoCull) {
				var lx = light.getRenderX();
				var ly = light.getRenderY();
				var lr = light.getRenderRadius();

				if (lx + lr >= camLeft && lx - lr <= camRight && ly + lr >= camTop && ly - lr <= camBottom) {
					visibleLights.push(light);
				}
			} else {
				visibleLights.push(light);
			}

			if (visibleLights.length >= MAX_LIGHTS) {
				break;
			}
		}

		// GPU-Uniforms befüllen
		var count = visibleLights.length;

		for (i in 0...count) {
			var l = visibleLights[i];
			var posIdx = i * 2;
			var vec4Idx = i * 4;

			_posBuffer[posIdx] = l.getRenderX();
			_posBuffer[posIdx + 1] = l.getRenderY();

			_colorBuffer[vec4Idx] = l.color.redFloat;
			_colorBuffer[vec4Idx + 1] = l.color.greenFloat;
			_colorBuffer[vec4Idx + 2] = l.color.blueFloat;
			_colorBuffer[vec4Idx + 3] = l.getRenderIntensity();

			_paramsBuffer[vec4Idx] = l.getRenderRadius();
			_paramsBuffer[vec4Idx + 1] = l.falloff;
			_paramsBuffer[vec4Idx + 2] = cast(l.lightType, Int);
			_paramsBuffer[vec4Idx + 3] = l.getShaderExtraParam();

			var spot = l.getShaderSpotData();
			_spotBuffer[vec4Idx] = spot[0];
			_spotBuffer[vec4Idx + 1] = spot[1];
			_spotBuffer[vec4Idx + 2] = spot[2];
			_spotBuffer[vec4Idx + 3] = spot[3];
		}

		// Shader-Uniforms setzen
		shaderInstance.data.u_ambient.value = [ambientColor.redFloat, ambientColor.greenFloat, ambientColor.blueFloat, ambientIntensity];
		shaderInstance.data.u_resolution.value = [camW, camH];
		shaderInstance.data.u_camScroll.value = [cam.scroll.x, cam.scroll.y];
		shaderInstance.data.u_camZoom.value = [cam.zoom];
		shaderInstance.data.u_lightCount.value = [count];

		shaderInstance.data.u_lightPos.value = _posBuffer;
		shaderInstance.data.u_lightColor.value = _colorBuffer;
		shaderInstance.data.u_lightParams.value = _paramsBuffer;
		shaderInstance.data.u_lightSpot.value = _spotBuffer;

		super.draw();
	}

	/**
	 * Gibt alle Ressourcen frei, zerstört alle registrierten Lichter und setzt Puffer zurück.
	 */
	override public function destroy():Void {
		clearLights(true);
		_posBuffer = null;
		_colorBuffer = null;
		_paramsBuffer = null;
		_spotBuffer = null;
		shaderInstance = null;
		super.destroy();
	}
}

