package mklib.light;

import flixel.util.FlxColor;

/**
 * Dynamische Fackel- und Feuerlichtquelle (Torch / Campfire / Candle).
 *
 * Erzeugt ein naturgetreues, organisches Flackern durch überlagerte
 * harmonische Oszillationen und Docht-Verschiebungen (Flame-Wobble).
 * Jede Instanz erhält einen zufälligen Phasen-Seed, sodass mehrere Fackeln
 * in der Spielwelt asynchron und lebendig wirken.
 */
class TorchLight extends Light {
	/**
	 * Die Geschwindigkeit / Grundfrequenz des Flackerns (Standard: 8.0).
	 */
	public var flickerSpeed:Float = 8.0;

	/**
	 * Die maximale Amplitude der Helligkeitsschwankung (Standard: 0.15).
	 */
	public var flickerIntensity:Float = 0.15;

	/**
	 * Die maximale Amplitude der Radiusschwankung in Pixeln (Standard: 10.0).
	 */
	public var flickerRadius:Float = 10.0;

	/**
	 * Die maximale Verschiebung des Flammendochts in Pixeln für tanzendes Licht (Standard: 2.0).
	 */
	public var flameJitter:Float = 2.0;

	/**
	 * Der innere Radius für volle Leuchtkraft.
	 */
	public var innerRadius:Float = 10.0;

	/**
	 * Interner Zeitakkumulator.
	 */
	private var _time:Float = 0.0;

	/**
	 * Zufälliger Phasen-Offset zur asynchronen Animation.
	 */
	private var _seed:Float = 0.0;

	/**
	 * Aktuell berechneter Render-Radius.
	 */
	private var _currentRadius:Float = 100.0;

	/**
	 * Aktuell berechnete Render-Intensität.
	 */
	private var _currentIntensity:Float = 1.0;

	/**
	 * Aktuelle Docht-Verschiebung auf der X-Achse.
	 */
	private var _wobbleX:Float = 0.0;

	/**
	 * Aktuelle Docht-Verschiebung auf der Y-Achse.
	 */
	private var _wobbleY:Float = 0.0;

	/**
	 * Erstellt eine neue Fackellichtquelle.
	 *
	 * @param x X-Koordinate in Weltpixeln.
	 * @param y Y-Koordinate in Weltpixeln.
	 * @param radius Grundradius des Lichts in Pixeln (Standard: 120).
	 * @param color Farbe des Lichts (Standard: Warmes Fackelorange `0xFFFFAA44`).
	 * @param intensity Grundintensität (Standard: 1.0).
	 * @param flickerSpeed Flacker-Frequenz (Standard: 8.0).
	 * @param flickerIntensity Helligkeits-Schwankung (Standard: 0.15).
	 * @param flickerRadius Radius-Schwankung in Pixeln (Standard: 10.0).
	 * @param flameJitter Flammendocht-Wobble in Pixeln (Standard: 2.0).
	 */
	public function new(x:Float = 0, y:Float = 0, radius:Float = 120, color:FlxColor = 0xFFFFAA44, intensity:Float = 1.0, flickerSpeed:Float = 8.0, flickerIntensity:Float = 0.15, flickerRadius:Float = 10.0, flameJitter:Float = 2.0) {
		super(x, y, radius, color, intensity, 1.0);
		this.flickerSpeed = flickerSpeed;
		this.flickerIntensity = flickerIntensity;
		this.flickerRadius = flickerRadius;
		this.flameJitter = flameJitter;
		this.lightType = TORCH;
		this._seed = Math.random() * 1000.0;
		this._currentRadius = radius;
		this._currentIntensity = intensity;
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (!active) {
			return;
		}

		_time += elapsed * flickerSpeed;
		var t = _time + _seed;

		// Überlagerte multi-frequente Oszillation für organische Flammenbewegung
		var noise = (Math.sin(t) * 0.45) + (Math.sin(t * 2.37 + 1.2) * 0.35) + (Math.sin(t * 5.13 + 2.8) * 0.20);

		_currentIntensity = Math.max(0.0, intensity + (noise * flickerIntensity));
		_currentRadius = Math.max(1.0, radius + (noise * flickerRadius));

		if (flameJitter > 0) {
			_wobbleX = Math.sin(t * 1.73) * flameJitter;
			_wobbleY = Math.cos(t * 2.19) * (flameJitter * 0.75);
		} else {
			_wobbleX = 0;
			_wobbleY = 0;
		}
	}

	override public function getRenderX():Float {
		return x + _wobbleX;
	}

	override public function getRenderY():Float {
		return y + _wobbleY;
	}

	override public function getRenderRadius():Float {
		return _currentRadius;
	}

	override public function getRenderIntensity():Float {
		return _currentIntensity;
	}

	override public function getShaderExtraParam():Float {
		return innerRadius;
	}
}
