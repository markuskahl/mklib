package mklib.effect.shader;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import mklib.effect.HazardLiquidType;

/**
 * Hardware-beschleunigter 2D Lava-, Säure- und Schleim-GPU-Fragment-Shader für `mklib`.
 *
 * Berechnet prozedurale, flüssige Oberflächen mit:
 * - **GPU-berechneter organischer Turbulenz (fBm Noise & Strömung)**
 * - **Aufbrechender Magmakruste / Schaumschollen**
 * - **Glühenden Hitzerissen & aufsteigenden Blubberblasen**
 * - **Dynamischer Oberflächen-Wellenbewegung**
 * - **Emissivem Oberflächenglühen (Surface Edge Glow)**
 * - **Welt- und Kamerasynchronisation für nahtlose Level-Integration**
 */
class HazardLiquidShader extends FlxShader {
	@:glFragmentSource('
		#pragma header

		uniform float u_time;
		uniform vec2 u_resolution;
		uniform vec2 u_flowSpeed;
		uniform vec2 u_noiseScale;
		uniform float u_turbulence;

		// Farben für den mehrstufigen thermischen/chemischen Gradienten
		uniform vec4 u_colorDeep;         // Tiefenfarbe (z. B. dunkles Magma / Gift-Tiefgrün)
		uniform vec4 u_colorSurface;      // Mittlere Flüssigkeitsfarbe (Orange / Neongrün)
		uniform vec4 u_colorGlow;         // Heißeste Stellen / Glüh-Adern (Gelb / Weiß)
		uniform vec4 u_colorCrust;        // Feste Kruste / Schaumschollen (Dunkles Gestein / Schaum)

		// Schwellenwerte
		uniform float u_crustThreshold;   // Ab welchem Wert Kruste sichtbar wird (0.0 bis 1.0)
		uniform float u_glowThreshold;    // Schwellenwert für glühende Hitzeadern
		uniform float u_crustSoftness;    // Weichheit des Krustenübergangs

		// Oberflächenwelle & Glühkante
		uniform float u_waveSpeed;        // Geschwindigkeit der Oberflächenwellen
		uniform float u_waveFrequency;    // Frequenz / Wellendichte
		uniform float u_waveAmplitude;    // Amplitude der Wellen an der Oberfläche
		uniform vec4 u_surfaceGlowColor;  // Farbe der Glühkante an der Wasseroberfläche
		uniform float u_surfaceGlowHeight;// Höhe des Oberflächenglühens

		// Blubbern & Pulsieren
		uniform float u_bubbleSpeed;      // Aufstiegsgeschwindigkeit der Blasen
		uniform float u_bubbleIntensity;  // Stärke des Blubber-Effekts

		// Weltkoordinaten & Kamera
		uniform vec2 u_camScroll;
		uniform float u_camZoom;
		uniform int u_useWorldCoords;
		uniform vec2 u_worldPos;
		uniform vec2 u_planeSize;

		// 2D Hash
		vec2 hash2(vec2 p) {
			p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
			return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
		}

		// Gradient Noise
		float gnoise(vec2 p) {
			vec2 i = floor(p);
			vec2 f = fract(p);
			vec2 u = f * f * (3.0 - 2.0 * f);
			return mix(mix(dot(hash2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
			               dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
			           mix(dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
			               dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
		}

		// Fractional Brownian Motion (fBm) für organische Flüssigkeitsströmung
		float fbm(vec2 p) {
			float v = 0.0;
			float a = 0.5;
			vec2 shift = vec2(10.0);
			mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
			for (int i = 0; i < 4; ++i) {
				v += a * gnoise(p);
				p = rot * p * 2.0 + shift;
				a *= 0.5;
			}
			return v;
		}

		void main() {
			vec2 uv = openfl_TextureCoordv;

			// Weltposition oder lokale Position ermitteln
			vec2 pos = uv * u_planeSize;
			if (u_useWorldCoords == 1) {
				pos = u_worldPos + pos;
			}

			// 1. Oberflächen-Wellenverzerrung (Obere Kante der Flüssigkeit)
			float wave = sin(pos.x * u_waveFrequency + u_time * u_waveSpeed) * u_waveAmplitude;
			wave += cos(pos.x * (u_waveFrequency * 0.7) - u_time * (u_waveSpeed * 1.3)) * (u_waveAmplitude * 0.4);

			// Relative Höhe unterhalb der modulierten Oberfläche (0.0 = Oberfläche, 1.0 = Boden)
			float waveOffsetNorm = wave / max(1.0, u_planeSize.y);
			float surfaceDist = uv.y - waveOffsetNorm;

			// Oberhalb der Wasser-/Lavakante transparent zeichnen
			if (surfaceDist < 0.0) {
				gl_FragColor = vec4(0.0);
				return;
			}

			// Normalisierte Tiefe (0.0 an Oberfläche bis 1.0 am Beckengrund)
			float depthNorm = clamp(surfaceDist / (1.0 - waveOffsetNorm), 0.0, 1.0);

			// 2. Strömungsvektor & Noise-Berechnung
			vec2 flowUV = (pos * u_noiseScale) + (u_flowSpeed * u_time);
			
			// Verzerrung über sekundären Noise (Domain Warping)
			vec2 warp = vec2(
				fbm(flowUV + vec2(u_time * 0.2, 0.0)),
				fbm(flowUV + vec2(0.0, u_time * 0.25))
			) * u_turbulence;

			float n = fbm(flowUV + warp) * 0.5 + 0.5; // Auf [0, 1] bringen

			// 3. Aufsteigende Blasen / Hotspots
			if (u_bubbleIntensity > 0.0) {
				vec2 bubbleCoord = vec2(pos.x * 0.04, (pos.y - u_time * u_bubbleSpeed * 40.0) * 0.04);
				float bubbleNoise = gnoise(bubbleCoord);
				float bubble = smoothstep(0.65, 0.85, bubbleNoise) * u_bubbleIntensity;
				n = clamp(n + bubble, 0.0, 1.0);
			}

			// 4. Farbstufen mischen (Thermischer Gradient)
			// Basis: Mischung aus Tiefen- und Oberflächenfarbe anhand der Tiefe und des Noise
			vec3 fluidColor = mix(u_colorDeep.rgb, u_colorSurface.rgb, pow(1.0 - depthNorm, 0.7) * (0.5 + 0.5 * n));

			// Glühende Hitze-Adern / energiereiche Stellen
			if (n > u_glowThreshold) {
				float glowFactor = smoothstep(u_glowThreshold, 1.0, n);
				fluidColor = mix(fluidColor, u_colorGlow.rgb, glowFactor * u_colorGlow.a);
			}

			// Feste Krustenschollen / Schaum (nur an weniger heißen Stellen)
			if (u_colorCrust.a > 0.0 && n < u_crustThreshold) {
				float crustFactor = smoothstep(u_crustThreshold, u_crustThreshold - u_crustSoftness, n);
				// Kruste ist an der Oberfläche ausgeprägter als tief unten
				crustFactor *= mix(1.0, 0.4, depthNorm);
				fluidColor = mix(fluidColor, u_colorCrust.rgb, crustFactor * u_colorCrust.a);
			}

			// 5. Oberflächen-Glühkante (Emissive Surface Glow)
			if (u_surfaceGlowHeight > 0.0 && surfaceDist < u_surfaceGlowHeight) {
				float edgeGlow = (1.0 - (surfaceDist / u_surfaceGlowHeight));
				edgeGlow = pow(edgeGlow, 1.5) * u_surfaceGlowColor.a;
				fluidColor = mix(fluidColor, u_surfaceGlowColor.rgb, edgeGlow);
			}

			// Gesamte Deckkraft
			float finalAlpha = mix(u_colorSurface.a, u_colorDeep.a, depthNorm);

			// Auslaufende Ränder am Beckenboden (weicher Übergang)
			float bottomFade = smoothstep(1.0, 0.96, depthNorm);
			finalAlpha *= bottomFade;

			gl_FragColor = vec4(fluidColor * finalAlpha, finalAlpha);
		}
	')

	/**
	 * Akkumulierte Gesamtzeit in Sekunden für Strömung und Wellen.
	 */
	public var totalTime:Float = 0.0;

	/**
	 * Erstellt eine neue Instanz des `HazardLiquidShader` mit Standardwerten für Lava.
	 */
	public function new() {
		super();

		data.u_time.value = [0.0];
		data.u_resolution.value = [FlxG.width, FlxG.height];
		data.u_flowSpeed.value = [0.03, 0.01];
		data.u_noiseScale.value = [0.015, 0.02];
		data.u_turbulence.value = [0.8];

		data.u_crustThreshold.value = [0.42];
		data.u_glowThreshold.value = [0.65];
		data.u_crustSoftness.value = [0.12];

		data.u_waveSpeed.value = [2.5];
		data.u_waveFrequency.value = [0.04];
		data.u_waveAmplitude.value = [3.5];
		data.u_surfaceGlowHeight.value = [0.08];

		data.u_bubbleSpeed.value = [1.2];
		data.u_bubbleIntensity.value = [0.35];

		data.u_camScroll.value = [0.0, 0.0];
		data.u_camZoom.value = [1.0];
		data.u_useWorldCoords.value = [1];
		data.u_worldPos.value = [0.0, 0.0];
		data.u_planeSize.value = [100.0, 50.0];

		// Standard-Preset: Lava
		presetLava();
	}

	/**
	 * Aktualisiert Zeit und Kamera-Synchronisation pro Frame.
	 *
	 * @param elapsed Vergangene Frame-Zeit in Sekunden (`FlxG.elapsed`).
	 * @param worldX Absolute X-Position des Beckens in der Spielwelt.
	 * @param worldY Absolute Y-Position des Beckens in der Spielwelt.
	 * @param width Breite des Flüssigkeitsbeckens in Pixeln.
	 * @param height Höhe des Flüssigkeitsbeckens in Pixeln.
	 * @param camera Optionale Kamera (Standard: `FlxG.camera`).
	 */
	public function update(elapsed:Float, worldX:Float, worldY:Float, width:Float, height:Float, ?camera:FlxCamera):Void {
		totalTime += elapsed;
		data.u_time.value = [totalTime];
		data.u_worldPos.value = [worldX, worldY];
		data.u_planeSize.value = [width, height];

		var cam = (camera != null) ? camera : FlxG.camera;
		if (cam != null) {
			data.u_resolution.value = [cam.width, cam.height];
			data.u_camScroll.value = [cam.scroll.x, cam.scroll.y];
			data.u_camZoom.value = [cam.zoom];
		}
	}

	/**
	 * Konfiguriert die Farbverläufe der Flüssigkeit.
	 *
	 * @param deepColor Farbe in den tiefen Schichten.
	 * @param surfaceColor Hauptfarbe an der Oberfläche.
	 * @param glowColor Glutfarbe / Hotspot-Adern (hellste Stellen).
	 * @param crustColor Krusten- bzw. Schaumfarbe.
	 */
	public function setColors(deepColor:FlxColor, surfaceColor:FlxColor, glowColor:FlxColor, crustColor:FlxColor):Void {
		data.u_colorDeep.value = [deepColor.redFloat, deepColor.greenFloat, deepColor.blueFloat, deepColor.alphaFloat];
		data.u_colorSurface.value = [surfaceColor.redFloat, surfaceColor.greenFloat, surfaceColor.blueFloat, surfaceColor.alphaFloat];
		data.u_colorGlow.value = [glowColor.redFloat, glowColor.greenFloat, glowColor.blueFloat, glowColor.alphaFloat];
		data.u_colorCrust.value = [crustColor.redFloat, crustColor.greenFloat, crustColor.blueFloat, crustColor.alphaFloat];
	}

	/**
	 * Konfiguriert Strömung, Noise-Dichte und Turbulenz.
	 *
	 * @param flowX Horizontale Driftgeschwindigkeit der Kruste/Flüssigkeit.
	 * @param flowY Vertikale Driftgeschwindigkeit.
	 * @param scaleX Horizontale Noise-Skalierung.
	 * @param scaleY Vertikale Noise-Skalierung.
	 * @param turbulence Stärke der organischen Wirbelbildung.
	 */
	public function setFlowAndTurbulence(flowX:Float = 0.03, flowY:Float = 0.01, scaleX:Float = 0.015, scaleY:Float = 0.02, turbulence:Float = 0.8):Void {
		data.u_flowSpeed.value = [flowX, flowY];
		data.u_noiseScale.value = [scaleX, scaleY];
		data.u_turbulence.value = [turbulence];
	}

	/**
	 * Konfiguriert die Oberflächenwelle und das Emissive-Glühen an der oberen Kante.
	 *
	 * @param speed Wellengeschwindigkeit.
	 * @param frequency Wellenfrequenz / Kuppendichte.
	 * @param amplitude Maximale Wellenhöhe in Pixeln.
	 * @param glowColor Farbe des Oberflächenglühens.
	 * @param glowHeight Relative Höhe der Glühzone (z. B. 0.08).
	 */
	public function setSurfaceWave(speed:Float = 2.5, frequency:Float = 0.04, amplitude:Float = 3.5, ?glowColor:FlxColor, glowHeight:Float = 0.08):Void {
		data.u_waveSpeed.value = [speed];
		data.u_waveFrequency.value = [frequency];
		data.u_waveAmplitude.value = [amplitude];
		data.u_surfaceGlowHeight.value = [glowHeight];

		if (glowColor != null) {
			data.u_surfaceGlowColor.value = [glowColor.redFloat, glowColor.greenFloat, glowColor.blueFloat, glowColor.alphaFloat];
		}
	}

	/**
	 * Konfiguriert die aufsteigenden Blasen.
	 *
	 * @param speed Aufstiegsgeschwindigkeit der Blasen.
	 * @param intensity Intensität / Häufigkeit des Blubberns.
	 */
	public function setBubbles(speed:Float = 1.2, intensity:Float = 0.35):Void {
		data.u_bubbleSpeed.value = [speed];
		data.u_bubbleIntensity.value = [intensity];
	}

	/**
	 * Konfiguriert Schwellenwerte für Kruste und Glühadern.
	 *
	 * @param crustThreshold Schwellenwert für Krustenbildung (0.0 bis 1.0).
	 * @param glowThreshold Schwellenwert für Hitzeadern (0.0 bis 1.0).
	 * @param crustSoftness Weichheit der Krustenkanten.
	 */
	public function setCrustThresholds(crustThreshold:Float = 0.42, glowThreshold:Float = 0.65, crustSoftness:Float = 0.12):Void {
		data.u_crustThreshold.value = [crustThreshold];
		data.u_glowThreshold.value = [glowThreshold];
		data.u_crustSoftness.value = [crustSoftness];
	}

	/**
	 * Schaltet auf das vordefinierte Lava-Preset (Glühendes Magma mit Basaltkruste).
	 */
	public function presetLava():Void {
		setColors(
			FlxColor.fromRGB(160, 20, 0, 255),    // Tiefrot
			FlxColor.fromRGB(255, 90, 0, 255),    // Helles Magma-Orange
			FlxColor.fromRGB(255, 230, 80, 255),  // Weißgelbe Glut-Adern
			FlxColor.fromRGB(28, 18, 16, 255)     // Dunkle Basalt-Kruste
		);
		data.u_surfaceGlowColor.value = [1.0, 0.75, 0.2, 0.9];
		setFlowAndTurbulence(0.02, 0.008, 0.012, 0.016, 0.85);
		setCrustThresholds(0.42, 0.65, 0.12);
		setSurfaceWave(2.2, 0.035, 3.0, null, 0.07);
		setBubbles(1.0, 0.3);
	}

	/**
	 * Schaltet auf das vordefinierte Säure-/Slime-Preset (Toxische Neongrüne Brühe).
	 */
	public function presetAcid():Void {
		setColors(
			FlxColor.fromRGB(15, 60, 20, 255),    // Tiefes Dunkelgrün
			FlxColor.fromRGB(50, 210, 40, 240),   // Toxisches Neongrün
			FlxColor.fromRGB(190, 255, 80, 255),  // Hellgelbe Säurespritzer
			FlxColor.fromRGB(25, 90, 30, 220)     // Zäher Schaum
		);
		data.u_surfaceGlowColor.value = [0.6, 1.0, 0.3, 0.85];
		setFlowAndTurbulence(0.04, 0.015, 0.018, 0.022, 0.7);
		setCrustThresholds(0.35, 0.70, 0.15);
		setSurfaceWave(3.2, 0.05, 4.0, null, 0.09);
		setBubbles(2.2, 0.55);
	}

	/**
	 * Schaltet auf das vordefinierte Giftwasser-Preset (Violette Verseuchung / Morast).
	 */
	public function presetToxic():Void {
		setColors(
			FlxColor.fromRGB(40, 10, 60, 255),    // Dunkles Violett
			FlxColor.fromRGB(140, 30, 180, 240),  // Toxisches Magenta
			FlxColor.fromRGB(240, 120, 255, 255), // Helles Gift-Pink
			FlxColor.fromRGB(60, 20, 80, 200)     // Dunkler Giftrand
		);
		data.u_surfaceGlowColor.value = [0.9, 0.4, 1.0, 0.8];
		setFlowAndTurbulence(0.025, 0.01, 0.014, 0.018, 0.75);
		setCrustThresholds(0.38, 0.68, 0.14);
		setSurfaceWave(2.6, 0.04, 3.2, null, 0.08);
		setBubbles(1.5, 0.4);
	}

	/**
	 * Wendet einen `HazardLiquidType` an.
	 *
	 * @param type Der gewünschte Flüssigkeitstyp.
	 */
	public function applyType(type:HazardLiquidType):Void {
		switch (type) {
			case LAVA:
				presetLava();
			case ACID_SLIME:
				presetAcid();
			case TOXIC_WATER:
				presetToxic();
			case CUSTOM:
				// Bleibt bei aktuellen Einstellungen
		}
	}
}
