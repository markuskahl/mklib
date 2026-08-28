package mklib.save;

/**
 * Metadaten eines gespeicherten Checkpoints.
 */
typedef CheckpointMeta = {
	/**
	 * Zeitstempel der Speicherung in Millisekunden seit Epoch (UTC).
	 */
	var timestamp:Float;

	/**
	 * Menschenlesbares Datum und Uhrzeit der Speicherung (z. B. "2026-08-29 00:35:00").
	 */
	var dateFormatted:String;

	/**
	 * Akkumulierte Spielzeit in Sekunden bis zu diesem Checkpoint.
	 */
	var playTimeSeconds:Float;

	/**
	 * Name des LDtk-Levels, in dem der Checkpoint erstellt wurde (z. B. "Level_0").
	 */
	var levelName:String;

	/**
	 * Optionale benutzerdefinierte Metadaten (z. B. Schwierigkeitsgrad, Kapitelname).
	 */
	var ?customMeta:Dynamic;
}

/**
 * Persistenter Zustand eines einzelnen Levels.
 */
typedef LevelSaveState = {
	/**
	 * Name des Levels.
	 */
	var levelName:String;

	/**
	 * Liste aller LDtk-Instanz-IDs (`iid`), die in diesem Level als zerstört markiert wurden.
	 */
	var destroyedIids:Array<String>;

	/**
	 * Serialisierte Zustandsdaten einzelner Entities (Schlüssel: `iid`).
	 */
	var entityStates:Map<String, Dynamic>;

	/**
	 * Level-spezifische benutzerdefinierte Key-Value-Daten.
	 */
	var customData:Map<String, Dynamic>;
}

/**
 * Gesamtstruktur des serialisierten Save-Profiles.
 */
typedef SaveProfile = {
	/**
	 * Versionsnummer des Save-Formats (für Migrationen).
	 */
	var version:Int;

	/**
	 * Metadaten des Checkpoints.
	 */
	var meta:CheckpointMeta;

	/**
	 * Globale spielübergreifende Key-Value-Daten.
	 */
	var globals:Dynamic;

	/**
	 * Alle Level-Zustände (Schlüssel: Level-Name).
	 */
	var levelStates:Dynamic;
}

/**
 * Konfigurationseinstellungen für den `SaveManager`.
 */
typedef SaveConfig = {
	/**
	 * Name des FlxSave-Profils (Standard: "mklib_save").
	 */
	var saveName:String;

	/**
	 * Gibt an, ob die gespeicherten JSON-Daten im Speicher verschleiert werden sollen.
	 */
	var obfuscate:Bool;

	/**
	 * Optionaler Sicherheitsschlüssel für die XOR/Base64-Verschleierung.
	 */
	var ?salt:String;
}
