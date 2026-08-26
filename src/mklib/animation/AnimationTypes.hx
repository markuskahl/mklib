package mklib.animation;

/**
 * Konfigurationsparameter für ein Kachel-Spritesheet (Frame-Dimensionen, Spacing, Margin).
 */
typedef FrameConfig = {
	/** Breite eines einzelnen Animationsframes in Pixeln. */
	var width:Int;

	/** Höhe eines einzelnen Animationsframes in Pixeln. */
	var height:Int;

	/** Optionaler Abstand zwischen Frames in Pixeln. */
	var ?spacing:Int;

	/** Optionaler Außenabstand des Spritesheets in Pixeln. */
	var ?margin:Int;
}

/**
 * Definition eines einzelnen Animationsclips (Name, Framerate, Frame-Indizes, Looping, Flipping).
 */
typedef AnimationClip = {
	/** Eindeutiger Name der Animation (z. B. "idle", "burn", "walk"). */
	var name:String;

	/** Abspielgeschwindigkeit in Bildern pro Sekunde (Frames per Second). */
	var fps:Int;

	/** Gibt an, ob die Animation in einer Endlosschleife wiederholt werden soll. */
	var loop:Bool;

	/** Horizontale Spiegelung der Frames. */
	var flipX:Bool;

	/** Vertikale Spiegelung der Frames. */
	var flipY:Bool;

	/** Liste der Frame-Indizes auf dem Spritesheet. */
	var frames:Array<Int>;
}

/**
 * Vollständige Datendefinition eines Spritesheets inklusive Bildpfad, Frame-Setup und Clips.
 */
typedef SpriteSheetData = {
	/** Relativer Pfad zur Bilddatei (z. B. "assets/tilesets/Fire.png"). */
	var imagePath:String;

	/** Kachel- und Rasterkonfiguration des Spritesheets. */
	var config:FrameConfig;

	/** Liste aller in diesem Spritesheet definierten Animationsclips. */
	var animations:Array<AnimationClip>;

	/** Name der standardmäßig abzuspielenden Animation. */
	var defaultAnimation:String;
}

