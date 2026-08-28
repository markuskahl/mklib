package mklib.light;

import flixel.util.FlxColor;

/**
 * Pulsierende Aura- und Magielichtquelle (Glow / Magic / Crystal / Beacon).
 *
 * Simuliert ein sanft atmendes Leuchten durch periodische Oszillation
 * zwischen definierten Minimal- und Maximalwerten für Radius und Intensität.
 */
class GlowLight extends Light {
	/**
	 * Der minimale Radius im Atmungszyklus.
	 */
	public var minRadius:Float = 40.0;

	/**
	 * Der maximale Radius im Atmungszyklus.
	 */
	public var maxRadius:Float = 80.0;

	/**
	 * Die minimale Helligkeit / Intensität im Atmungszyklus.
	 */
	public var minIntensity:Float = 0.4;

	/**
	 * Die maximale Helligkeit / Intensität im Atmungszyklus.
	 */
	public var maxIntensity:Float = 1.0;

	/**
	 * Die Geschwindigkeit des Pulsierens (Standard: 2.0).
	 */
	public var pulseSpeed:Float = 2.0;

	/**
	 * Phasenverschiebung in Radiant (z. B. zur Verschiebung mehrerer Kristalle).
	 */
	public var pulsePhase:Float = 0.0;

	/**
	 * Interner Zeitakkumulator.
	 */
	private var _time:Float = 0.0;

	/**
	 * Aktuell berechneter Render-Radius.
	 */
	private var _currentRadius:Float = 60.0;

	/**
	 * Aktuell berechnete Render-Intensität.
	 */
	private var _currentIntensity:Float = 0.7;

	/**
	 * Erstellt eine neue pulsierende Glow-Lichtquelle.
	 *
	 * @param x X-Koordinate in Weltpixeln.
	 * @param y Y-Koordinate in Weltpixeln.
	 * @param minRadius Minimaler Radius in Pixeln (Standard: 40).
	 * @param maxRadius Maximaler Radius in Pixeln (Standard: 80).
	 * @param color Farbe des Lichts (Standard: Magisches Cyan `0xFF55AAFF`).
	 * @param minIntensity Minimale Intensität (Standard: 0.4).
	 * @param maxIntensity Maximale Intensität (Standard: 1.0).
	 * @param pulseSpeed Pulsier-Geschwindigkeit (Standard: 2.0).
	 * @param pulsePhase Phasenverschiebung (Standard: 0.0).
	 */
	public function new(x:Float = 0, y:Float = 0, minRadius:Float = 40, maxRadius:Float = 80, color:FlxColor = 0xFF55AAFF, minIntensity:Float = 0.4, maxIntensity:Float = 1.0, pulseSpeed:Float = 2.0, pulsePhase:Float = 0.0) {
		super(x, y, maxRadius, color, maxIntensity, 1.0);
		this.minRadius = minRadius;
		this.maxRadius = maxRadius;
		this.minIntensity = minIntensity;
		this.maxIntensity = maxIntensity;
		this.pulseSpeed = pulseSpeed;
		this.pulsePhase = pulsePhase;
		this.lightType = GLOW;
		this._currentRadius = (minRadius + maxRadius) * 0.5;
		this._currentIntensity = (minIntensity + maxIntensity) * 0.5;
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (!active) {
			return;
		}

		_time += elapsed * pulseSpeed;
		var wave = (Math.sin(_time + pulsePhase) + 1.0) * 0.5; // [0.0 .. 1.0]

		_currentRadius = minRadius + (wave * (maxRadius - minRadius));
		_currentIntensity = minIntensity + (wave * (maxIntensity - minIntensity));
	}

	override public function getRenderRadius():Float {
		return _currentRadius;
	}

	override public function getRenderIntensity():Float {
		return _currentIntensity;
	}
}
