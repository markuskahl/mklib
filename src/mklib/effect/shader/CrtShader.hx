package mklib.effect.shader;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.system.FlxAssets.FlxShader;
import openfl.filters.ShaderFilter;

/**
 * Hardware-beschleunigter CRT & Retro-Arcade GPU-Post-Processing-Shader für `mklib`.
 *
 * Simuliert authentische Röhrenmonitore (CRT) und Arcade-Bildschirme der 80er/90er Jahre mit:
 * - **Bildschirmwölbung (Screen Curvature / Barrel Distortion)**
 * - **Horizontale Scanlines** mit konfigurierbarer Frequenz, Stärke und Rollgeschwindigkeit
 * - **RGB Phosphor Shadow Mask (Triad Subpixel)**
 * - **Chromatische Aberration (RGB-Split / Farbkanalverschiebung)**
 * - **Vignette & Bezel-Randabschattung** mit abgerundeten Ecken
 * - **Phosphor-Bloom, Helligkeits- und Kontrast-Anpassung**
 * - **Analoges Röhrenflimmern (Flicker) & feines Rauschen (Noise)**
 */
class CrtShader extends FlxShader {
	@:glFragmentSource('
		#pragma header

		uniform float u_time;
		uniform vec2 u_resolution;
		uniform vec2 u_curvature;
		uniform float u_scanlineCount;
		uniform float u_scanlineIntensity;
		uniform float u_scanlineSpeed;
		uniform float u_rgbMaskIntensity;
		uniform float u_rgbMaskScale;
		uniform float u_chromaticAberration;
		uniform float u_vignetteIntensity;
		uniform float u_vignetteRoundness;
		uniform float u_brightness;
		uniform float u_contrast;
		uniform float u_flicker;
		uniform float u_noise;
		uniform float u_cornerSmoothness;

		// Pseudo-Zufallsfunktion für analoges Bildrauschen
		float rand(vec2 co) {
			return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
		}

		// Berechnet die gekrümmte Bildschirm-Koordinate (Barrel Distortion)
		vec2 curveUV(vec2 uv, vec2 curve) {
			if (curve.x <= 0.0 && curve.y <= 0.0) {
				return uv;
			}
			vec2 centered = uv - 0.5;
			float r2 = centered.x * centered.x + centered.y * centered.y;
			centered *= 1.0 + r2 * curve;
			return centered + 0.5;
		}

		void main() {
			vec2 uv = openfl_TextureCoordv;

			// 1. Bildschirmwölbung anwenden
			vec2 curvedUV = curveUV(uv, u_curvature);

			// Außerhalb des gewölbten CRT-Schirms Schwarz rendern (mit weicher Kante)
			if (curvedUV.x < 0.0 || curvedUV.x > 1.0 || curvedUV.y < 0.0 || curvedUV.y > 1.0) {
				gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
				return;
			}

			// Weicher Übergang an den Außenkanten (Bezel-Border)
			float smoothBorder = 1.0;
			if (u_cornerSmoothness > 0.0) {
				float bx = smoothstep(0.0, u_cornerSmoothness, curvedUV.x) * smoothstep(1.0, 1.0 - u_cornerSmoothness, curvedUV.x);
				float by = smoothstep(0.0, u_cornerSmoothness, curvedUV.y) * smoothstep(1.0, 1.0 - u_cornerSmoothness, curvedUV.y);
				smoothBorder = bx * by;
			}

			// 2. Chromatische Aberration (RGB-Split)
			vec3 color;
			if (u_chromaticAberration > 0.0) {
				vec2 dir = (curvedUV - 0.5) * u_chromaticAberration;
				float r = flixel_texture2D(bitmap, clamp(curvedUV + dir, 0.0, 1.0)).r;
				float g = flixel_texture2D(bitmap, curvedUV).g;
				float b = flixel_texture2D(bitmap, clamp(curvedUV - dir, 0.0, 1.0)).b;
				color = vec3(r, g, b);
			} else {
				color = flixel_texture2D(bitmap, curvedUV).rgb;
			}

			// 3. Scanlines (Horizontale Linien mit optionalem sanftem Scrollen)
			if (u_scanlineIntensity > 0.0) {
				float lines = u_scanlineCount > 0.0 ? u_scanlineCount : (u_resolution.y * 0.5);
				float scanline = sin((curvedUV.y * lines + u_time * u_scanlineSpeed) * 6.2831853);
				// Sinuswelle von [-1, 1] auf [0, 1] mappen
				scanline = (scanline * 0.5 + 0.5);
				// Weicher Scanline-Verlauf
				float scanFactor = mix(1.0, scanline, u_scanlineIntensity);
				color *= scanFactor;
			}

			// 4. RGB Phosphor Mask (Triad Subpixel Grille)
			if (u_rgbMaskIntensity > 0.0) {
				float maskCoord = mod(floor(openfl_TextureCoordv.x * u_resolution.x * u_rgbMaskScale), 3.0);
				vec3 mask = vec3(1.0);
				if (maskCoord < 1.0) {
					mask = vec3(1.0, 1.0 - u_rgbMaskIntensity, 1.0 - u_rgbMaskIntensity); // Rot-Dominanz
				} else if (maskCoord < 2.0) {
					mask = vec3(1.0 - u_rgbMaskIntensity, 1.0, 1.0 - u_rgbMaskIntensity); // Grün-Dominanz
				} else {
					mask = vec3(1.0 - u_rgbMaskIntensity, 1.0 - u_rgbMaskIntensity, 1.0); // Blau-Dominanz
				}
				color *= mask;
			}

			// 5. Vignette (Rand- und Eckenabschattung)
			if (u_vignetteIntensity > 0.0) {
				float vig = curvedUV.x * (1.0 - curvedUV.x) * curvedUV.y * (1.0 - curvedUV.y) * 16.0;
				vig = clamp(pow(vig, u_vignetteRoundness), 0.0, 1.0);
				color *= mix(1.0 - u_vignetteIntensity, 1.0, vig);
			}

			// 6. Röhrenflimmern (Flicker) & Rauschen (Noise)
			if (u_flicker > 0.0) {
				float f = 1.0 + (sin(u_time * 50.0) * 0.5 + 0.5) * u_flicker;
				color *= f;
			}
			if (u_noise > 0.0) {
				float n = (rand(curvedUV * u_time) - 0.5) * u_noise;
				color += vec3(n);
			}

			// 7. Helligkeit & Kontrast
			color = ((color - 0.5) * u_contrast) + 0.5;
			color *= u_brightness;

			// Randabdunkelung einrechnen
			color *= smoothBorder;

			gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
		}
	')

	/**
	 * Akkumulierte Gesamtzeit in Sekunden für Scanline-Scrolling und Rauschen.
	 */
	public var totalTime:Float = 0.0;

	/**
	 * Cached Filter-Instanz für einfache Zuweisung an Kameras (`camera.setFilters([crtShader.filter])`).
	 */
	public var filter(get, null):ShaderFilter;

	private var _filter:ShaderFilter;

	private function get_filter():ShaderFilter {
		if (_filter == null) {
			_filter = new ShaderFilter(this);
		}
		return _filter;
	}

	/**
	 * Erstellt eine neue Instanz des `CrtShader` mit ausgewogenen Standard-Retro-Werten.
	 */
	public function new() {
		super();

		data.u_time.value = [0.0];
		data.u_resolution.value = [FlxG.width, FlxG.height];
		data.u_curvature.value = [0.08, 0.08];
		data.u_scanlineCount.value = [240.0];
		data.u_scanlineIntensity.value = [0.22];
		data.u_scanlineSpeed.value = [0.0];
		data.u_rgbMaskIntensity.value = [0.12];
		data.u_rgbMaskScale.value = [1.0];
		data.u_chromaticAberration.value = [0.003];
		data.u_vignetteIntensity.value = [0.3];
		data.u_vignetteRoundness.value = [0.28];
		data.u_brightness.value = [1.05];
		data.u_contrast.value = [1.05];
		data.u_flicker.value = [0.015];
		data.u_noise.value = [0.012];
		data.u_cornerSmoothness.value = [0.01];
	}

	/**
	 * Aktualisiert Zeit und Viewport-Auflösung pro Frame.
	 *
	 * @param elapsed Vergangene Frame-Zeit in Sekunden (`FlxG.elapsed`).
	 * @param camera Optionale Kamera (Standard: `FlxG.camera`).
	 */
	public function update(elapsed:Float, ?camera:FlxCamera):Void {
		totalTime += elapsed;
		data.u_time.value = [totalTime];

		var cam = (camera != null) ? camera : FlxG.camera;
		if (cam != null) {
			data.u_resolution.value = [cam.width, cam.height];
		}
	}

	/**
	 * Konfiguriert die Bildschirmwölbung (CRT Tube Curvature).
	 *
	 * @param horizontal Wölbung in X-Richtung (Standard: 0.08, 0.0 = flach).
	 * @param vertical Wölbung in Y-Richtung (Standard: 0.08, 0.0 = flach).
	 * @param cornerSmoothness Weichheit des Übergangs an den Außenkanten (Standard: 0.01).
	 */
	public function setCurvature(horizontal:Float = 0.08, vertical:Float = 0.08, cornerSmoothness:Float = 0.01):Void {
		data.u_curvature.value = [horizontal, vertical];
		data.u_cornerSmoothness.value = [cornerSmoothness];
	}

	/**
	 * Konfiguriert die horizontalen Scanlines.
	 *
	 * @param intensity Dunkelheit der Scanlines (0.0 = aus, 1.0 = maximal, Standard: 0.22).
	 * @param lineCount Anzahl der Scanlines über die Bildschirmhöhe (Standard: 240.0, 0 = automatisch aus Auflösung).
	 * @param rollSpeed Vertikale Rollgeschwindigkeit für subtiles Scrollen (Standard: 0.0 = statisch).
	 */
	public function setScanlines(intensity:Float = 0.22, lineCount:Float = 240.0, rollSpeed:Float = 0.0):Void {
		data.u_scanlineIntensity.value = [intensity];
		data.u_scanlineCount.value = [lineCount];
		data.u_scanlineSpeed.value = [rollSpeed];
	}

	/**
	 * Konfiguriert das Phosphor-RGB-Gitter (Shadow Mask).
	 *
	 * @param intensity Stärke des RGB-Subpixel-Musters (0.0 = aus, Standard: 0.12).
	 * @param scale Skalierung des Rasters (Standard: 1.0).
	 */
	public function setRgbMask(intensity:Float = 0.12, scale:Float = 1.0):Void {
		data.u_rgbMaskIntensity.value = [intensity];
		data.u_rgbMaskScale.value = [scale];
	}

	/**
	 * Konfiguriert die chromatische Farbverschiebung (RGB-Split).
	 *
	 * @param amount Stärke des Farbversatzes (z. B. 0.003, 0.0 = aus).
	 */
	public function setChromaticAberration(amount:Float = 0.003):Void {
		data.u_chromaticAberration.value = [amount];
	}

	/**
	 * Konfiguriert die Randabschattung (Vignette) der Röhre.
	 *
	 * @param intensity Intensität der Randabdunkelung (0.0 bis 1.0, Standard: 0.3).
	 * @param roundness Krümmung / Formfaktor der Vignette (Standard: 0.28).
	 */
	public function setVignette(intensity:Float = 0.3, roundness:Float = 0.28):Void {
		data.u_vignetteIntensity.value = [intensity];
		data.u_vignetteRoundness.value = [roundness];
	}

	/**
	 * Konfiguriert Helligkeit, Kontrast und Phosphor-Bloom.
	 *
	 * @param brightness Helligkeitsmultiplikator (Standard: 1.05).
	 * @param contrast Kontrastmultiplikator (Standard: 1.05).
	 */
	public function setBloom(brightness:Float = 1.05, contrast:Float = 1.05):Void {
		data.u_brightness.value = [brightness];
		data.u_contrast.value = [contrast];
	}

	/**
	 * Konfiguriert Röhrenflimmern und analoges Rauschen.
	 *
	 * @param flicker Intensität des 50/60Hz Netzflimmerns (Standard: 0.015, 0.0 = aus).
	 * @param noise Intensität des körnigen Bildrauschens (Standard: 0.012, 0.0 = aus).
	 */
	public function setAnalogNoise(flicker:Float = 0.015, noise:Float = 0.012):Void {
		data.u_flicker.value = [flicker];
		data.u_noise.value = [noise];
	}

	/**
	 * Schaltet alle CRT-Effekte auf ein dezentes, für modernes Gameplay optimiertes Preset.
	 */
	public function presetSubtle():Void {
		setCurvature(0.03, 0.03, 0.005);
		setScanlines(0.12, 0.0, 0.0);
		setRgbMask(0.06, 1.0);
		setChromaticAberration(0.0015);
		setVignette(0.2, 0.3);
		setBloom(1.03, 1.02);
		setAnalogNoise(0.008, 0.006);
	}

	/**
	 * Schaltet alle CRT-Effekte auf ein starkes Arcade-Kabinett-Preset der 80er Jahre.
	 */
	public function presetArcade():Void {
		setCurvature(0.12, 0.12, 0.015);
		setScanlines(0.35, 240.0, 0.3);
		setRgbMask(0.2, 1.0);
		setChromaticAberration(0.005);
		setVignette(0.45, 0.25);
		setBloom(1.1, 1.1);
		setAnalogNoise(0.025, 0.02);
	}

	/**
	 * Schaltet alle CRT-Effekte auf einen monochromen / bernsteinfarbenen Retro-Terminal-Look.
	 */
	public function presetVhsGlitch():Void {
		setCurvature(0.06, 0.06, 0.01);
		setScanlines(0.28, 200.0, 1.2);
		setRgbMask(0.15, 1.0);
		setChromaticAberration(0.008);
		setVignette(0.35, 0.28);
		setBloom(1.15, 1.15);
		setAnalogNoise(0.04, 0.035);
	}
}
