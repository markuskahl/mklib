package mklib.effect.shader;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import mklib.effect.WaterReflectionMode;

/**
 * Hardware-beschleunigter 2D Wasser-Reflexions- und Wellen-GPU-Fragment-Shader für `mklib`.
 *
 * Unterstützt vertikale Wasserspiegelungen, horizontale Spiegelungen sowie reine Wellenverzerrungen.
 * Bietet konfigurierbare Mehrfach-Sinuswellen, Wassertönung (Tint), Tiefenausblendung (Fade),
 * Oberflächen-Schaumkanten (Foam) und automatische Weltsynchronisation mit Kamera-Scroll und -Zoom.
 */
class WaterReflectionShader extends FlxShader {
	@:glFragmentSource('
		#pragma header

		uniform float u_time;             // Fortlaufende Zeit in Sekunden
		uniform int u_mode;               // 0: Vertikal, 1: Horizontal, 2: Nur Verzerrung
		uniform float u_waterLevel;       // Relative Wasserlinie / Spiegelachse (0.0 bis 1.0)
		uniform float u_waveSpeed;        // Ausbreitungsgeschwindigkeit der Wellen
		uniform float u_waveFrequency;    // Dichte / Frequenz der Wellen
		uniform float u_waveAmplitude;    // Amplitude / Stärke der Verzerrung
		uniform float u_secondaryWave;    // Wichtungsfaktor für überlagerte Sekundärwellen
		uniform vec4 u_waterColor;        // RGB: Tönung, A: Mischstärke
		uniform float u_fadeDepth;        // Intensität des Tiefenausblendens
		uniform float u_minAlpha;         // Minimale Resttransparenz der Reflexion
		uniform vec4 u_foamColor;         // RGB: Schaumfarbe, A: Schaumdeckkraft
		uniform float u_foamThickness;    // Dicke der Schaumkante in UV-Einheiten

		// Welt- und Kamera-Transformation
		uniform vec2 u_resolution;        // Viewport-Auflösung
		uniform vec2 u_camScroll;         // Kamera-Scroll X, Y
		uniform float u_camZoom;          // Kamera-Zoomfaktor
		uniform int u_useWorldCoords;     // 1 = Weltkoordinaten aktiv, 0 = Relative UV-Werte
		uniform float u_worldWaterLevel;  // Absolute Y-Koordinate der Wasserlinie im Level

		void main() {
			vec2 uv = openfl_TextureCoordv;

			// Effektive Spiegelungsachse berechnen
			float splitAxis = u_waterLevel;
			if (u_useWorldCoords == 1 && u_resolution.y > 0.0 && u_camZoom > 0.0) {
				float screenPixelY = (u_worldWaterLevel - u_camScroll.y) * u_camZoom;
				splitAxis = screenPixelY / u_resolution.y;
			}

			// Modus 2: Reine Wellenverzerrung (für Wasser-Texturen oder geflippte Sprites)
			if (u_mode == 2) {
				float wave = sin(uv.y * u_waveFrequency + u_time * u_waveSpeed) * u_waveAmplitude;
				if (u_secondaryWave > 0.0) {
					wave += cos(uv.x * (u_waveFrequency * 0.7) - u_time * (u_waveSpeed * 1.3)) * (u_waveAmplitude * u_secondaryWave);
				}

				vec2 sampleUV = clamp(vec2(uv.x + wave, uv.y), 0.0, 1.0);
				vec4 texColor = flixel_texture2D(bitmap, sampleUV);
				vec3 tinted = mix(texColor.rgb, u_waterColor.rgb, u_waterColor.a);
				gl_FragColor = vec4(tinted * texColor.a, texColor.a);
				return;
			}

			// Modus 1: Horizontale Spiegelung (links/rechts an vertikaler Achse)
			if (u_mode == 1) {
				if (uv.x < splitAxis) {
					gl_FragColor = flixel_texture2D(bitmap, uv);
					return;
				}

				float distFromMirror = uv.x - splitAxis;
				float wave = sin(uv.y * u_waveFrequency + u_time * u_waveSpeed) * u_waveAmplitude;
				if (u_secondaryWave > 0.0) {
					wave += cos(uv.x * (u_waveFrequency * 0.7) - u_time * (u_waveSpeed * 1.3)) * (u_waveAmplitude * u_secondaryWave);
				}

				vec2 reflectedUV = vec2(clamp(splitAxis - distFromMirror + wave, 0.0, 1.0), uv.y);
				vec4 reflColor = flixel_texture2D(bitmap, reflectedUV);

				vec3 tinted = mix(reflColor.rgb, u_waterColor.rgb, u_waterColor.a);
				float alphaFade = clamp(1.0 - (distFromMirror * u_fadeDepth), u_minAlpha, 1.0);
				float finalAlpha = reflColor.a * alphaFade;

				if (u_foamThickness > 0.0 && distFromMirror < u_foamThickness) {
					float foamBlend = (1.0 - (distFromMirror / u_foamThickness)) * u_foamColor.a;
					tinted = mix(tinted, u_foamColor.rgb, foamBlend);
				}

				gl_FragColor = vec4(tinted * finalAlpha, finalAlpha);
				return;
			}

			// Modus 0: Standard Vertikale Wasseroberfläche
			if (uv.y < splitAxis) {
				gl_FragColor = flixel_texture2D(bitmap, uv);
				return;
			}

			float distFromSurface = uv.y - splitAxis;

			// Horizontale und vertikale Sinus- und Kosinus-Wellenverzerrung
			float waveX = sin(uv.y * u_waveFrequency + u_time * u_waveSpeed) * u_waveAmplitude;
			if (u_secondaryWave > 0.0) {
				waveX += cos(uv.x * (u_waveFrequency * 0.7) - u_time * (u_waveSpeed * 1.3)) * (u_waveAmplitude * u_secondaryWave);
			}
			float waveY = cos(uv.x * (u_waveFrequency * 0.8) + u_time * (u_waveSpeed * 0.9)) * (u_waveAmplitude * 0.35);

			// Gespiegelte Abtastkoordinate oberhalb der Wasserlinie
			vec2 reflectedUV = vec2(clamp(uv.x + waveX, 0.0, 1.0), clamp(splitAxis - distFromSurface + waveY, 0.0, 1.0));
			vec4 reflColor = flixel_texture2D(bitmap, reflectedUV);

			// Wassertönung beimischen
			vec3 tinted = mix(reflColor.rgb, u_waterColor.rgb, u_waterColor.a);

			// Tiefenausblendung berechnen
			float alphaFade = clamp(1.0 - (distFromSurface * u_fadeDepth), u_minAlpha, 1.0);
			float finalAlpha = reflColor.a * alphaFade;

			// Schaum- / Glanzlinie an der Wasseroberfläche
			if (u_foamThickness > 0.0 && distFromSurface < u_foamThickness) {
				float foamBlend = (1.0 - (distFromSurface / u_foamThickness)) * u_foamColor.a;
				tinted = mix(tinted, u_foamColor.rgb, foamBlend);
			}

			gl_FragColor = vec4(tinted * finalAlpha, finalAlpha);
		}
	')

	/**
	 * Akkumulierte Gesamtzeit für die kontinuierliche Wellenbewegung.
	 */
	public var totalTime:Float = 0.0;

	/**
	 * Erstellt eine neue Instanz des `WaterReflectionShader` mit ausgewogenen Standardwerten.
	 */
	public function new() {
		super();

		data.u_time.value = [0.0];
		data.u_mode.value = [0];
		data.u_waterLevel.value = [0.65];
		data.u_waveSpeed.value = [2.8];
		data.u_waveFrequency.value = [35.0];
		data.u_waveAmplitude.value = [0.012];
		data.u_secondaryWave.value = [0.5];
		data.u_waterColor.value = [0.08, 0.35, 0.65, 0.4];
		data.u_fadeDepth.value = [2.0];
		data.u_minAlpha.value = [0.15];
		data.u_foamColor.value = [0.95, 0.98, 1.0, 0.75];
		data.u_foamThickness.value = [0.006];

		data.u_resolution.value = [FlxG.width, FlxG.height];
		data.u_camScroll.value = [0.0, 0.0];
		data.u_camZoom.value = [1.0];
		data.u_useWorldCoords.value = [0];
		data.u_worldWaterLevel.value = [0.0];
	}

	/**
	 * Aktualisiert den Zeit-Uniform für kontinuierliche Wellenbewegung.
	 *
	 * @param elapsed Vergangene Frame-Zeit in Sekunden.
	 */
	public function update(elapsed:Float):Void {
		totalTime += elapsed;
		data.u_time.value = [totalTime];
	}

	/**
	 * Setzt die relative Position der Wasserlinie / Spiegelachse im UV-Raum (0.0 bis 1.0).
	 *
	 * @param level Y-Koordinate (bei vertikal) bzw. X-Koordinate (bei horizontal).
	 */
	public function setWaterLevel(level:Float):Void {
		data.u_waterLevel.value = [level];
		data.u_useWorldCoords.value = [0];
	}

	/**
	 * Bindet die Wasserlinie an eine absolute Welt-Koordinate und synchronisiert Kamera-Scroll/Zoom.
	 *
	 * @param worldY Y-Koordinate der Wasseroberfläche in Weltpixeln.
	 * @param camera Die zu überwachende Kamera (Standard: `FlxG.camera`).
	 */
	public function syncWithCamera(worldY:Float, ?camera:FlxCamera):Void {
		var cam = (camera != null) ? camera : FlxG.camera;
		if (cam == null)
			return;

		data.u_useWorldCoords.value = [1];
		data.u_worldWaterLevel.value = [worldY];
		data.u_resolution.value = [cam.width, cam.height];
		data.u_camScroll.value = [cam.scroll.x, cam.scroll.y];
		data.u_camZoom.value = [cam.zoom];
	}

	/**
	 * Konfiguriert die dynamischen Wellenparameter.
	 *
	 * @param speed Ausbreitungsgeschwindigkeit der Wellen.
	 * @param frequency Frequenz / Dichte der Wellenkuppen.
	 * @param amplitude Maximale Wellenauslenkung (Verzerrungsstärke).
	 * @param secondaryWave Überlagerungsfaktor für Kreuzwellen (Standard: 0.5).
	 */
	public function setWaveParams(speed:Float, frequency:Float, amplitude:Float, secondaryWave:Float = 0.5):Void {
		data.u_waveSpeed.value = [speed];
		data.u_waveFrequency.value = [frequency];
		data.u_waveAmplitude.value = [amplitude];
		data.u_secondaryWave.value = [secondaryWave];
	}

	/**
	 * Konfiguriert die Wassertönung (Farbe und Deckkraft).
	 *
	 * @param color Die Tönungsfarbe des Wassers.
	 * @param tintIntensity Mischfaktor von 0.0 (keine Tönung) bis 1.0 (volle Farbe).
	 */
	public function setWaterColor(color:FlxColor, tintIntensity:Float = 0.4):Void {
		data.u_waterColor.value = [color.redFloat, color.greenFloat, color.blueFloat, tintIntensity];
	}

	/**
	 * Konfiguriert die Schaum- / Glanzkante an der Wasseroberfläche.
	 *
	 * @param thickness Dicke der Schaumlinie in UV-Einheiten (z. B. 0.005, 0 = deaktiviert).
	 * @param color Farbe und Deckkraft des Schaums (Standard: Weiß 0.75).
	 */
	public function setFoam(thickness:Float, ?color:FlxColor):Void {
		data.u_foamThickness.value = [thickness];
		if (color != null) {
			data.u_foamColor.value = [color.redFloat, color.greenFloat, color.blueFloat, color.alphaFloat];
		}
	}

	/**
	 * Konfiguriert das Tiefenausblenden (Fade).
	 *
	 * @param depthFactor Wie schnell die Reflexion nach unten hin transparenter wird.
	 * @param minAlpha Die minimale Resttransparenz der Reflexion am Grund (0.0 bis 1.0).
	 */
	public function setFade(depthFactor:Float, minAlpha:Float = 0.15):Void {
		data.u_fadeDepth.value = [depthFactor];
		data.u_minAlpha.value = [minAlpha];
	}

	/**
	 * Setzt den Betriebsmodus der Spiegelung.
	 *
	 * @param mode Der gewünschte `WaterReflectionMode`.
	 */
	public function setMode(mode:WaterReflectionMode):Void {
		data.u_mode.value = [mode];
	}
}
