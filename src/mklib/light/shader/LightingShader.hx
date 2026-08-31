package mklib.light.shader;

import flixel.system.FlxAssets.FlxShader;
import lime.utils.Float32Array;

/**
 * Hardware-beschleunigter 2D-Multi-Light GPU Fragment-Shader für `mklib`.
 *
 * Berechnet bis zu 32 dynamische Lichter gleichzeitig auf der GPU pro Render-Durchlauf.
 * Transformiert Fragment-Pixel automatisch anhand von Kamera-Scroll und Zoom in Weltkoordinaten
 * und unterstützt Dämpfungskurven, innere Helligkeitsradien, Scheinwerferkegel sowie
 * hardwarebeschleunigtes 2D-GPU-Raymarching für dynamische Schattenwürfe (Occlusion Shadows).
 */
@:access(openfl.display.Shader)
@:access(openfl.display3D.Context3D)
class LightingShader extends FlxShader {
	public static inline var MAX_LIGHTS:Int = 32;

	@:glFragmentSource('
		#pragma header

		#define MAX_LIGHTS 32

		uniform vec4 u_ambient;
		uniform vec2 u_resolution;
		uniform vec2 u_camScroll;
		uniform float u_camZoom;
		uniform int u_lightCount;

		uniform vec2 u_lightPos[32];
		uniform vec4 u_lightColor[32];
		uniform vec4 u_lightParams[32];
		uniform vec4 u_lightSpot[32];

		uniform sampler2D u_occlusionTexture;
		uniform int u_shadowsEnabled;
		uniform int u_shadowSteps;
		uniform float u_shadowSoftness;

		void main() {
			vec2 uv = openfl_TextureCoordv;
			vec4 sceneColor = flixel_texture2D(bitmap, uv);

			vec2 screenPixel = uv * u_resolution;
			vec2 worldPos = u_camScroll + (screenPixel / u_camZoom);

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

				if (type == 4) {
					lightAcc += lCol.rgb * lCol.a;
					continue;
				}

				vec2 toPixel = worldPos - lPos;
				float dist = length(toPixel);

				if (dist < radius) {
					float normDist = clamp(dist / max(0.001, radius), 0.0, 1.0);

					if (innerParam > 0.0) {
						float innerNorm = clamp(innerParam / radius, 0.0, 0.999);
						if (normDist < innerNorm) {
							normDist = 0.0;
						} else {
							normDist = (normDist - innerNorm) / (1.0 - innerNorm);
						}
					}

					float att = 1.0 - normDist;
					att = pow(clamp(att, 0.0, 1.0), falloffExp);
					att = smoothstep(0.0, 1.0, att);

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

					if (u_shadowsEnabled == 1 && att > 0.001 && dist > 1.0) {
						vec2 lightScreen = (lPos - u_camScroll) * u_camZoom;
						vec2 lightUV = lightScreen / u_resolution;

						float shadow = 1.0;
						float steps = clamp(float(u_shadowSteps), 4.0, 64.0);
						float stepSize = 1.0 / steps;

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

					lightAcc += lCol.rgb * (lCol.a * att);
				}
			}

			gl_FragColor = vec4(clamp(lightAcc, vec3(0.0), vec3(1.0)), 1.0) * sceneColor;
		}
	')

	public var posArray(default, null):Float32Array;
	public var colorArray(default, null):Float32Array;
	public var paramsArray(default, null):Float32Array;
	public var spotArray(default, null):Float32Array;

	public var ambientR:Float = 0.078;
	public var ambientG:Float = 0.078;
	public var ambientB:Float = 0.141;
	public var ambientIntensity:Float = 0.2;

	public var resolutionX:Float = 320.0;
	public var resolutionY:Float = 180.0;

	public var camScrollX:Float = 0.0;
	public var camScrollY:Float = 0.0;
	public var camZoom:Float = 1.0;
	public var lightCount:Int = 0;

	public var shadowsEnabled:Int = 0;
	public var shadowSteps:Int = 32;
	public var shadowSoftness:Float = 0.0;

	private var _locAmbient:Int = -1;
	private var _locResolution:Int = -1;
	private var _locCamScroll:Int = -1;
	private var _locCamZoom:Int = -1;
	private var _locLightCount:Int = -1;
	private var _locShadowsEnabled:Int = -1;
	private var _locShadowSteps:Int = -1;
	private var _locShadowSoftness:Int = -1;
	private var _locLightPos:Int = -1;
	private var _locLightColor:Int = -1;
	private var _locLightParams:Int = -1;
	private var _locLightSpot:Int = -1;
	private var _locOcclusion:Int = -1;

	public function new() {
		super();

		posArray = new Float32Array(MAX_LIGHTS * 2);
		colorArray = new Float32Array(MAX_LIGHTS * 4);
		paramsArray = new Float32Array(MAX_LIGHTS * 4);
		spotArray = new Float32Array(MAX_LIGHTS * 4);
	}

	@:noCompletion override private function __initGL():Void {
		super.__initGL();

		#if lime
		if (__context != null && glProgram != null) {
			var gl = __context.gl;

			_locAmbient = gl.getUniformLocation(glProgram, "u_ambient");
			_locResolution = gl.getUniformLocation(glProgram, "u_resolution");
			_locCamScroll = gl.getUniformLocation(glProgram, "u_camScroll");
			_locCamZoom = gl.getUniformLocation(glProgram, "u_camZoom");
			_locLightCount = gl.getUniformLocation(glProgram, "u_lightCount");

			_locLightPos = gl.getUniformLocation(glProgram, "u_lightPos[0]");
			if (_locLightPos < 0) _locLightPos = gl.getUniformLocation(glProgram, "u_lightPos");

			_locLightColor = gl.getUniformLocation(glProgram, "u_lightColor[0]");
			if (_locLightColor < 0) _locLightColor = gl.getUniformLocation(glProgram, "u_lightColor");

			_locLightParams = gl.getUniformLocation(glProgram, "u_lightParams[0]");
			if (_locLightParams < 0) _locLightParams = gl.getUniformLocation(glProgram, "u_lightParams");

			_locLightSpot = gl.getUniformLocation(glProgram, "u_lightSpot[0]");
			if (_locLightSpot < 0) _locLightSpot = gl.getUniformLocation(glProgram, "u_lightSpot");

			_locShadowsEnabled = gl.getUniformLocation(glProgram, "u_shadowsEnabled");
			_locShadowSteps = gl.getUniformLocation(glProgram, "u_shadowSteps");
			_locShadowSoftness = gl.getUniformLocation(glProgram, "u_shadowSoftness");
			_locOcclusion = gl.getUniformLocation(glProgram, "u_occlusionTexture");
		}
		#end
	}

	@:noCompletion override private function __updateGL():Void {
		super.__updateGL();
		uploadLightArrays();
	}

	@:noCompletion override private function __updateGLFromBuffer(shaderBuffer:openfl.display._internal.ShaderBuffer, bufferOffset:Int):Void {
		super.__updateGLFromBuffer(shaderBuffer, bufferOffset);
		uploadLightArrays();
	}

	public function uploadLightArrays():Void {
		#if lime
		if (__context == null || glProgram == null) return;
		var gl = __context.gl;

		if (_locLightCount < 0) {
			_locAmbient = gl.getUniformLocation(glProgram, "u_ambient");
			_locResolution = gl.getUniformLocation(glProgram, "u_resolution");
			_locCamScroll = gl.getUniformLocation(glProgram, "u_camScroll");
			_locCamZoom = gl.getUniformLocation(glProgram, "u_camZoom");
			_locLightCount = gl.getUniformLocation(glProgram, "u_lightCount");

			_locLightPos = gl.getUniformLocation(glProgram, "u_lightPos[0]");
			if (_locLightPos < 0) _locLightPos = gl.getUniformLocation(glProgram, "u_lightPos");

			_locLightColor = gl.getUniformLocation(glProgram, "u_lightColor[0]");
			if (_locLightColor < 0) _locLightColor = gl.getUniformLocation(glProgram, "u_lightColor");

			_locLightParams = gl.getUniformLocation(glProgram, "u_lightParams[0]");
			if (_locLightParams < 0) _locLightParams = gl.getUniformLocation(glProgram, "u_lightParams");

			_locLightSpot = gl.getUniformLocation(glProgram, "u_lightSpot[0]");
			if (_locLightSpot < 0) _locLightSpot = gl.getUniformLocation(glProgram, "u_lightSpot");

			_locShadowsEnabled = gl.getUniformLocation(glProgram, "u_shadowsEnabled");
			_locShadowSteps = gl.getUniformLocation(glProgram, "u_shadowSteps");
			_locShadowSoftness = gl.getUniformLocation(glProgram, "u_shadowSoftness");
			_locOcclusion = gl.getUniformLocation(glProgram, "u_occlusionTexture");
		}

		if (_locAmbient >= 0) gl.uniform4f(_locAmbient, ambientR, ambientG, ambientB, ambientIntensity);
		if (_locResolution >= 0) gl.uniform2f(_locResolution, resolutionX, resolutionY);
		if (_locCamScroll >= 0) gl.uniform2f(_locCamScroll, camScrollX, camScrollY);
		if (_locCamZoom >= 0) gl.uniform1f(_locCamZoom, camZoom);
		if (_locLightCount >= 0) gl.uniform1i(_locLightCount, lightCount);

		if (_locShadowsEnabled >= 0) gl.uniform1i(_locShadowsEnabled, shadowsEnabled);
		if (_locShadowSteps >= 0) gl.uniform1i(_locShadowSteps, shadowSteps);
		if (_locShadowSoftness >= 0) gl.uniform1f(_locShadowSoftness, shadowSoftness);

		// Bind occlusion sampler explicitly to texture unit 1
		if (_locOcclusion >= 0) {
			gl.uniform1i(_locOcclusion, 1);
		}

		if (_locLightPos >= 0 && posArray != null) {
			#if (js && html5)
			gl.uniform2fv(_locLightPos, posArray);
			#else
			lime.graphics.opengl.GL.uniform2fv(_locLightPos, MAX_LIGHTS, posArray);
			#end
		}

		if (_locLightColor >= 0 && colorArray != null) {
			#if (js && html5)
			gl.uniform4fv(_locLightColor, colorArray);
			#else
			lime.graphics.opengl.GL.uniform4fv(_locLightColor, MAX_LIGHTS, colorArray);
			#end
		}

		if (_locLightParams >= 0 && paramsArray != null) {
			#if (js && html5)
			gl.uniform4fv(_locLightParams, paramsArray);
			#else
			lime.graphics.opengl.GL.uniform4fv(_locLightParams, MAX_LIGHTS, paramsArray);
			#end
		}

		if (_locLightSpot >= 0 && spotArray != null) {
			#if (js && html5)
			gl.uniform4fv(_locLightSpot, spotArray);
			#else
			lime.graphics.opengl.GL.uniform4fv(_locLightSpot, MAX_LIGHTS, spotArray);
			#end
		}
		#end
	}
}

