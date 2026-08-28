package mklib.light.shader;

import flixel.system.FlxAssets.FlxShader;

/**
 * Hardware-beschleunigter 2D-Multi-Light GPU Fragment-Shader für `mklib`.
 *
 * Berechnet bis zu 32 dynamische Lichter gleichzeitig auf der GPU pro Render-Durchlauf.
 * Transformiert Fragment-Pixel automatisch anhand von Kamera-Scroll und Zoom in Weltkoordinaten
 * und unterstützt Dämpfungskurven, innere Helligkeitsradien sowie Scheinwerferkegel.
 */
class LightingShader extends FlxShader {
	@:glFragmentSource('
		#pragma header

		const int MAX_LIGHTS = 32;

		uniform vec4 u_ambient;       // rgb: Umgebungsfarbe, a: Umgebungshelligkeit
		uniform vec2 u_resolution;    // Viewport-Auflösung (Breite, Höhe)
		uniform vec2 u_camScroll;     // Kamera-Scroll (Welt-Offset X, Y)
		uniform float u_camZoom;      // Kamera-Zoomfaktor
		uniform int u_lightCount;     // Anzahl aktiver Lichter im aktuellen Batch

		// Array-Uniforms für Lichterdaten
		uniform vec2 u_lightPos[MAX_LIGHTS];       // Weltkoordinaten (X, Y)
		uniform vec4 u_lightColor[MAX_LIGHTS];     // R, G, B, Intensität
		uniform vec4 u_lightParams[MAX_LIGHTS];    // X: Radius, Y: Falloff-Exponent, Z: LightType, W: InnerParam
		uniform vec4 u_lightSpot[MAX_LIGHTS];      // X: DirX, Y: DirY, Z: CosOuter, W: CosInner

		void main() {
			vec2 uv = openfl_TextureCoordv;
			vec4 sceneColor = flixel_texture2D(bitmap, uv);

			// Fragment-Position in Weltkoordinaten berechnen
			vec2 screenPixel = uv * u_resolution;
			vec2 worldPos = u_camScroll + (screenPixel / u_camZoom);

			// Basis-Umgebungslicht (Ambient)
			vec3 lightAcc = u_ambient.rgb * u_ambient.a;

			for (int i = 0; i < MAX_LIGHTS; i++) {
				if (i >= u_lightCount) {
					break;
				}

				vec2 lPos = u_lightPos[i];
				vec4 lCol = u_lightColor[i];
				vec4 lPar = u_lightParams[i];
				vec4 lSpt = u_lightSpot[i];

				float radius = lPar.x;
				float falloffExp = max(0.1, lPar.y);
				int type = int(lPar.z + 0.5);
				float innerParam = lPar.w;

				// Globales Directional Light
				if (type == 4) {
					lightAcc += lCol.rgb * lCol.a;
					continue;
				}

				vec2 toPixel = worldPos - lPos;
				float dist = length(toPixel);

				if (dist < radius) {
					// Distanz normalisieren
					float normDist = clamp(dist / max(0.001, radius), 0.0, 1.0);

					// Innerer Radius für 100% Leuchtkraft
					if (innerParam > 0.0) {
						float innerNorm = clamp(innerParam / radius, 0.0, 0.999);
						if (normDist < innerNorm) {
							normDist = 0.0;
						} else {
							normDist = (normDist - innerNorm) / (1.0 - innerNorm);
						}
					}

					// Sanfte Dämpfungskurve (Smoothstep & Exponential)
					float att = 1.0 - normDist;
					att = pow(clamp(att, 0.0, 1.0), falloffExp);
					att = smoothstep(0.0, 1.0, att);

					// Gerichteter Scheinwerfer (SpotLight)
					if (type == 1) {
						vec2 dir = normalize(toPixel);
						vec2 spotDir = lSpt.xy;
						float cosOuter = lSpt.z;
						float cosInner = lSpt.w;

						float currentCos = dot(dir, spotDir);
						if (currentCos < cosOuter) {
							att = 0.0;
						} else {
							float spotSpan = max(0.0001, cosInner - cosOuter);
							float spotAtt = clamp((currentCos - cosOuter) / spotSpan, 0.0, 1.0);
							spotAtt = smoothstep(0.0, 1.0, spotAtt);
							att *= spotAtt;
						}
					}

					// Farb- und Intensitätsakkumulation
					lightAcc += lCol.rgb * (lCol.a * att);
				}
			}

			// Ergebnis: Lichtakkumulation multipliziert mit Textur-/Szene-Farbe
			gl_FragColor = vec4(clamp(lightAcc, 0.0, 1.0), 1.0) * sceneColor;
		}
	')
	public function new() {
		super();
	}
}
