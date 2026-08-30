package mklib.light.shader;

import flixel.system.FlxAssets.FlxShader;

/**
 * Hardware-beschleunigter 2D-Multi-Light GPU Fragment-Shader für `mklib`.
 *
 * Berechnet bis zu 32 dynamische Lichter gleichzeitig auf der GPU pro Render-Durchlauf.
 * Transformiert Fragment-Pixel automatisch anhand von Kamera-Scroll und Zoom in Weltkoordinaten
 * und unterstützt Dämpfungskurven, innere Helligkeitsradien, Scheinwerferkegel sowie
 * hardwarebeschleunigtes 2D-GPU-Raymarching für dynamische Schattenwürfe (Occlusion Shadows).
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

		// 2D Raycast / Shadow Casting Uniforms
		uniform sampler2D u_occlusionTexture;      // Maskentextur der Hindernisse/Wände (Alpha > 0 = Hindernis)
		uniform int u_shadowsEnabled;              // 1 = Schatten aktiv, 0 = Schatten deaktiviert
		uniform int u_shadowSteps;                 // Anzahl der Raymarching-Abtastschritte (z. B. 24, 32)
		uniform float u_shadowSoftness;            // Weichzeichnungsfaktor für Halbschatten (0.0 = harte Schatten)

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

					// 2D Raymarching Schatten-Berechnung
					if (u_shadowsEnabled == 1 && att > 0.001 && dist > 1.0) {
						vec2 lightScreen = (lPos - u_camScroll) * u_camZoom;
						vec2 lightUV = lightScreen / u_resolution;

						float shadow = 1.0;
						float steps = clamp(float(u_shadowSteps), 4.0, 64.0);
						float stepSize = 1.0 / steps;

						// Startpunkt mit kleinem Versatz zur Vermeidung von Selbstverschattung an der Lichtquelle
						float startT = clamp(2.0 / max(dist * u_camZoom, 2.0), 0.01, 0.15);

						for (int s = 1; s <= 64; s++) {
							if (float(s) >= steps) {
								break;
							}
							float t = startT + float(s) * stepSize * (1.0 - startT);
							if (t >= 0.98) {
								break;
							}
							vec2 sampleUV = mix(lightUV, uv, t);
							if (sampleUV.x >= 0.0 && sampleUV.x <= 1.0 && sampleUV.y >= 0.0 && sampleUV.y <= 1.0) {
								float occ = flixel_texture2D(u_occlusionTexture, sampleUV).a;
								if (occ > 0.25) {
									if (u_shadowSoftness > 0.01) {
										float penumbra = clamp((1.0 - t) * (1.0 / u_shadowSoftness), 0.0, 1.0);
										shadow = min(shadow, 1.0 - penumbra);
										if (shadow <= 0.0) {
											break;
										}
									} else {
										shadow = 0.0;
										break;
									}
								}
							}
						}
						att *= shadow;
					}

					// Farb- und Intensitätsakkumulation
					lightAcc += lCol.rgb * (lCol.a * att);
				}
			}

			// Ergebnis: Lichtakkumulation multipliziert mit Textur-/Szene-Farbe
			gl_FragColor = vec4(clamp(lightAcc, vec3(0.0), vec3(1.0)), 1.0) * sceneColor;
		}
	')
	public function new() {
		super();
	}
}
