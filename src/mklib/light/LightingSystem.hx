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
 * Verwaltet Lichter (`PointLight`, `SpotLight`, `TorchLight`, `GlowLight`, `DirectionalLight`),
 * führt intelligentes Viewport-/Frustum-Culling durch und rendert das Lichtbild hardwarebeschleunigt
 * über den `LightingShader`.
 *
 * Bietet zudem automatische Erkennung und Instanziierung von Lichtquellen aus LDtk-Leveldaten
 * anhand benutzerdefinierter Felder (Custom Properties).
 */
class LightingSystem extends FlxSprite {
	/**
	 * Maximale Anzahl an gleichzeitig an die GPU übergebenen Lichtern pro Viewport.
	 */
	public static inline var MAX_LIGHTS:Int = 32;

	/**
	 * Liste aller registrierten Lichtquellen in der Spielwelt.
	 */
	public var lights:Array<Light> = [];

	/**
	 * Die Umgebungs-Grundfarbe (Standard: Dunkles Nachtblau/Violett `0xFF141424`).
	 */
	public var ambientColor:FlxColor = 0xFF141424;

	/**
	 * Die Grundhelligkeit des Umgebungslichts (0.0 = stockdunkel, 1.0 = voll ausgeleuchtet, Standard: 0.2).
	 */
	public var ambientIntensity:Float = 0.2;

	/**
	 * Aktiviert automatisches Frustum-Culling (nur Lichter im Kamerabereich werden an den Shader gesendet).
	 */
	public var autoCull:Bool = true;

	/**
	 * Die Instanz des GPU-Multi-Light-Shaders.
	 */
	public var shaderInstance(default, null):LightingShader;

	// Wiederverwendbare Puffer-Arrays zur Vermeidung von GC-Allokationen während der Render-Schleife
	private var _posBuffer:Array<Float> = [];
	private var _colorBuffer:Array<Float> = [];
	private var _paramsBuffer:Array<Float> = [];
	private var _spotBuffer:Array<Float> = [];

	/**
	 * Erstellt ein neues Beleuchtungssystem.
	 *
	 * @param ambientColor Umgebungslicht-Farbe (Standard: `0xFF141424`).
	 * @param ambientIntensity Umgebungslicht-Intensität (Standard: `0.2`).
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
	 * Initialisiert die internen Uniform-Puffer für die maximale Shader-Kapazität.
	 */
	private function initBuffers():Void {
		_posBuffer = [for (i in 0...(MAX_LIGHTS * 2)) 0.0];
		_colorBuffer = [for (i in 0...(MAX_LIGHTS * 4)) 0.0];
		_paramsBuffer = [for (i in 0...(MAX_LIGHTS * 4)) 0.0];
		_spotBuffer = [for (i in 0...(MAX_LIGHTS * 4)) 0.0];
	}

	/**
	 * Registriert eine neue Lichtquelle im System.
	 *
	 * @param light Die hinzuzufügende Lichtquelle.
	 * @return Die hinzugefügte Lichtquelle (Fluent Interface).
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
	 * @param destroy Ob die Lichtquelle zerstört werden soll (`destroy()`).
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
	 * Entfernt alle Lichtquellen aus dem System.
	 *
	 * @param destroy Ob alle Lichter zerstört werden sollen.
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
	 * Gibt die Gesamtzahl der registrierten Lichter zurück.
	 */
	public inline function getLightCount():Int {
		return lights.length;
	}

	// =========================================================================
	// Programmatische Factory-Hilfsmethoden
	// =========================================================================

	/**
	 * Erstellt und registriert ein neues omnidirektionales Punktlicht (`PointLight`).
	 */
	public function createPointLight(x:Float, y:Float, radius:Float = 100, color:FlxColor = FlxColor.WHITE, intensity:Float = 1.0, innerRadius:Float = 0.0, falloff:Float = 1.0):PointLight {
		var light = new PointLight(x, y, radius, color, intensity, innerRadius, falloff);
		return addLight(light);
	}

	/**
	 * Erstellt und registriert einen neuen gerichteten Scheinwerfer (`SpotLight`).
	 */
	public function createSpotLight(x:Float, y:Float, radius:Float = 150, angle:Float = 0, spotAngle:Float = 45, color:FlxColor = FlxColor.WHITE, intensity:Float = 1.0, innerAngle:Float = 15, falloff:Float = 1.0):SpotLight {
		var light = new SpotLight(x, y, radius, angle, spotAngle, color, intensity, innerAngle, falloff);
		return addLight(light);
	}

	/**
	 * Erstellt und registriert eine neue Fackellichtquelle (`TorchLight`).
	 */
	public function createTorchLight(x:Float, y:Float, radius:Float = 120, color:FlxColor = 0xFFFFAA44, intensity:Float = 1.0, flickerSpeed:Float = 8.0, flickerIntensity:Float = 0.15, flickerRadius:Float = 10.0, flameJitter:Float = 2.0):TorchLight {
		var light = new TorchLight(x, y, radius, color, intensity, flickerSpeed, flickerIntensity, flickerRadius, flameJitter);
		return addLight(light);
	}

	/**
	 * Erstellt und registriert eine neue pulsierende Aura-Lichtquelle (`GlowLight`).
	 */
	public function createGlowLight(x:Float, y:Float, minRadius:Float = 40, maxRadius:Float = 80, color:FlxColor = 0xFF55AAFF, minIntensity:Float = 0.4, maxIntensity:Float = 1.0, pulseSpeed:Float = 2.0, pulsePhase:Float = 0.0):GlowLight {
		var light = new GlowLight(x, y, minRadius, maxRadius, color, minIntensity, maxIntensity, pulseSpeed, pulsePhase);
		return addLight(light);
	}

	/**
	 * Erstellt und registriert ein neues globales Richtungslicht (`DirectionalLight`).
	 */
	public function createDirectionalLight(directionAngle:Float = 45.0, color:FlxColor = 0xFFFFF8EE, intensity:Float = 0.5):DirectionalLight {
		var light = new DirectionalLight(directionAngle, color, intensity);
		return addLight(light);
	}

	// =========================================================================
	// LDtk Custom-Properties Parser & Level-Integration
	// =========================================================================

	/**
	 * Parst eine LDtk-Entity und erzeugt anhand ihrer benutzerdefinierten Felder
	 * (`fieldInstances`) die passende `Light`-Instanz.
	 *
	 * Unterstützt flexible Feldnamen (z. B. `radius`, `light_radius`, `color`, `intensity`, `spotAngle` etc.)
	 * und konvertiert LDtk-Farbwerte automatisch.
	 *
	 * @param entity Die aus LDtk geladene Entity-Definition.
	 * @return Die erzeugte Lichtquelle oder `null`, falls die Entity kein Licht definiert.
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
	 * Liest alle Lichter aus einer LDtk-Entity-Layer-Quelle (z. B. `data.l_Lights` oder `data.l_Entities`)
	 * aus und fügt sie diesem System hinzu.
	 *
	 * @param layer Die LDtk-Layer-Quelle.
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
	 * Durchsucht alle Layer eines LDtk-Level-Objekts nach Licht-Entities und lädt diese automatisch.
	 *
	 * @param levelData Das typisierte LDtk-Level-Objekt (z. B. `state.data`).
	 * @return Gesamtzahl der geladenen Lichter.
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

	private static function getColorParam(entity:ldtk.Entity, keys:Array<String>, defaultColor:FlxColor):FlxColor {
		for (k in keys) {
			var val = getEntityField(entity, k);
			if (val != null) {
				if (Std.isOfType(val, Int)) {
					var intVal:Int = cast val;
					// LDtk liefert Farben meist als 0xRRGGBB ohne Alpha
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

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		// Alle aktiven Lichter aktualisieren
		for (light in lights) {
			if (light != null && light.active) {
				light.update(elapsed);
			}
		}
	}

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
