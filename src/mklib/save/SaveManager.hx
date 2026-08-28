package mklib.save;

import flixel.FlxG;
import flixel.util.FlxSave;
import haxe.Json;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import mklib.state.State;
import mklib.save.SaveData;

/**
 * Statische Fassade zur Verwaltung von Spielständen, Checkpoints, globalen Variablen
 * und Multi-Level-Zuständen in HaxeFlixel / LDtk-Projekten.
 */
class SaveManager {
	/**
	 * Aktuelle Versionsnummer des Speicherformats.
	 */
	public static inline var FORMAT_VERSION:Int = 1;

	/**
	 * Standard-Konfiguration des Save-Managers.
	 */
	public static var config:SaveConfig = {
		saveName: "mklib_save",
		obfuscate: false,
		salt: "mklib_persistence_salt"
	};

	/**
	 * Akkumulierte Gesamtspielzeit in Sekunden.
	 */
	public static var playTime:Float = 0.0;

	/**
	 * Globale spielübergreifende Variablen (z. B. Inventar, Story-Flags, Einstellungen).
	 */
	public static var globals:Map<String, Dynamic> = new Map();

	/**
	 * Im Speicher gecachte Zustände aller besuchten Level (Schlüssel: Level-Name).
	 */
	public static var levelStates:Map<String, LevelSaveState> = new Map();

	/**
	 * Metadaten des aktuell geladenen oder zuletzt erstellten Checkpoints.
	 */
	public static var lastCheckpointMeta:Null<CheckpointMeta> = null;

	/**
	 * Optionaler Callback, der nach einem erfolgreichen Speichervorgang ausgelöst wird.
	 */
	public static var onSave:Null<CheckpointMeta->Void> = null;

	/**
	 * Optionaler Callback, der nach einem erfolgreichen Ladevorgang ausgelöst wird.
	 */
	public static var onLoad:Null<CheckpointMeta->Void> = null;

	/**
	 * Aktualisiert die Spielzeit. Kann im Haupt-State-Update aufgerufen werden.
	 *
	 * @param elapsed Verstrichene Zeit seit dem letzten Frame in Sekunden.
	 */
	public static function update(elapsed:Float):Void {
		playTime += elapsed;
	}

	// =========================================================================
	// Checkpoint-Verwaltung (Speichern & Laden)
	// =========================================================================

	/**
	 * Speichert den aktuellen Spielzustand (inkl. aktuellem Level, Session-Cache und globalen Variablen)
	 * als persistenten Checkpoint via `FlxSave`.
	 *
	 * @param customMeta Optionale benutzerdefinierte Metadaten.
	 * @param targetState Optionaler State, der vor dem Speichern erfasst werden soll. Falls null, wird `FlxG.state` verwendet.
	 * @return `true`, wenn die Speicherung erfolgreich war, andernfalls `false`.
	 */
	public static function saveCheckpoint(?customMeta:Dynamic, ?targetState:State<Dynamic>):Bool {
		var stateToCapture:State<Dynamic> = targetState;
		if (stateToCapture == null && FlxG.state != null && Std.isOfType(FlxG.state, State)) {
			stateToCapture = cast FlxG.state;
		}

		var activeLevelName:String = (stateToCapture != null && stateToCapture.levelName != null) ? stateToCapture.levelName : "Unknown";

		if (stateToCapture != null) {
			captureLevel(stateToCapture);
		}

		var dateStr = Date.now().toString();
		var meta:CheckpointMeta = {
			timestamp: Date.now().getTime(),
			dateFormatted: dateStr,
			playTimeSeconds: playTime,
			levelName: activeLevelName,
			customMeta: customMeta
		};

		// Serialisiere LevelStates Map
		var serializedLevels:Dynamic = {};
		for (lvlName => lvlState in levelStates) {
			var serializedEntities:Dynamic = {};
			if (lvlState.entityStates != null) {
				for (iid => eData in lvlState.entityStates) {
					Reflect.setField(serializedEntities, iid, eData);
				}
			}

			var serializedCustom:Dynamic = {};
			if (lvlState.customData != null) {
				for (k => v in lvlState.customData) {
					Reflect.setField(serializedCustom, k, v);
				}
			}

			Reflect.setField(serializedLevels, lvlName, {
				levelName: lvlState.levelName,
				destroyedIids: lvlState.destroyedIids != null ? lvlState.destroyedIids.copy() : [],
				entityStates: serializedEntities,
				customData: serializedCustom
			});
		}

		// Serialisiere Globals Map
		var serializedGlobals:Dynamic = {};
		for (k => v in globals) {
			Reflect.setField(serializedGlobals, k, v);
		}

		var profile:SaveProfile = {
			version: FORMAT_VERSION,
			meta: meta,
			globals: serializedGlobals,
			levelStates: serializedLevels
		};

		var rawJson:String = Json.stringify(profile);
		var payload:String = config.obfuscate ? obfuscateString(rawJson, config.salt) : rawJson;

		var save:FlxSave = new FlxSave();
		var success:Bool = false;
		if (save.bind(config.saveName)) {
			save.data.payload = payload;
			save.data.isObfuscated = config.obfuscate;
			save.data.meta = meta;
			success = save.flush();
			save.close();
		}

		if (success) {
			lastCheckpointMeta = meta;
			if (onSave != null) {
				onSave(meta);
			}
		}

		return success;
	}

	/**
	 * Lädt den gespeicherten Checkpoint und stellt alle Level-Zustände und globalen Variablen wieder her.
	 *
	 * @return `true`, wenn ein gültiger Checkpoint geladen werden konnte, andernfalls `false`.
	 */
	public static function loadCheckpoint():Bool {
		var save:FlxSave = new FlxSave();
		if (!save.bind(config.saveName)) {
			return false;
		}

		if (save.data.payload == null) {
			save.close();
			return false;
		}

		var rawJson:String = "";
		var isObf:Bool = save.data.isObfuscated == true;
		var rawPayload:String = cast save.data.payload;

		if (isObf) {
			rawJson = deobfuscateString(rawPayload, config.salt);
		} else {
			rawJson = rawPayload;
		}

		save.close();

		var profile:SaveProfile = null;
		try {
			profile = Json.parse(rawJson);
		} catch (e:Dynamic) {
			trace("[SaveManager] Fehler beim Parsen des Speicherstands: " + Std.string(e));
			return false;
		}

		if (profile == null) {
			return false;
		}

		// Spielzeit & Metadaten wiederherstellen
		lastCheckpointMeta = profile.meta;
		if (profile.meta != null) {
			playTime = profile.meta.playTimeSeconds;
		}

		// Globale Variablen wiederherstellen
		globals.clear();
		if (profile.globals != null) {
			for (field in Reflect.fields(profile.globals)) {
				globals.set(field, Reflect.field(profile.globals, field));
			}
		}

		// Level-Zustände wiederherstellen
		levelStates.clear();
		if (profile.levelStates != null) {
			for (lvlField in Reflect.fields(profile.levelStates)) {
				var rawLvl:Dynamic = Reflect.field(profile.levelStates, lvlField);
				if (rawLvl != null) {
					var destroyedList:Array<String> = [];
					if (rawLvl.destroyedIids != null) {
						var arr:Array<Dynamic> = rawLvl.destroyedIids;
						for (item in arr) {
							destroyedList.push(Std.string(item));
						}
					}

					var eMap:Map<String, Dynamic> = new Map();
					if (rawLvl.entityStates != null) {
						for (eKey in Reflect.fields(rawLvl.entityStates)) {
							eMap.set(eKey, Reflect.field(rawLvl.entityStates, eKey));
						}
					}

					var cMap:Map<String, Dynamic> = new Map();
					if (rawLvl.customData != null) {
						for (cKey in Reflect.fields(rawLvl.customData)) {
							cMap.set(cKey, Reflect.field(rawLvl.customData, cKey));
						}
					}

					levelStates.set(lvlField, {
						levelName: rawLvl.levelName != null ? rawLvl.levelName : lvlField,
						destroyedIids: destroyedList,
						entityStates: eMap,
						customData: cMap
					});
				}
			}
		}

		// Falls der aktuelle State aktiv ist, wende geladene Daten direkt an
		if (FlxG.state != null && Std.isOfType(FlxG.state, State)) {
			restoreLevel(cast FlxG.state);
		}

		if (onLoad != null && lastCheckpointMeta != null) {
			onLoad(lastCheckpointMeta);
		}

		return true;
	}

	/**
	 * Prüft, ob ein gespeicherter Checkpoint existiert.
	 */
	public static function hasCheckpoint():Bool {
		var save:FlxSave = new FlxSave();
		if (!save.bind(config.saveName)) {
			return false;
		}
		var exists:Bool = (save.data.payload != null);
		save.close();
		return exists;
	}

	/**
	 * Löscht den persistent gespeicherten Checkpoint.
	 */
	public static function clearCheckpoint():Void {
		var save:FlxSave = new FlxSave();
		if (save.bind(config.saveName)) {
			save.erase();
			save.close();
		}
		lastCheckpointMeta = null;
	}

	/**
	 * Gibt die Metadaten des gespeicherten Checkpoints zurück, ohne das gesamte Savegame in den RAM zu laden.
	 */
	public static function getCheckpointMeta():Null<CheckpointMeta> {
		if (lastCheckpointMeta != null) {
			return lastCheckpointMeta;
		}

		var save:FlxSave = new FlxSave();
		if (!save.bind(config.saveName)) {
			return null;
		}

		var meta:Null<CheckpointMeta> = null;
		if (save.data.meta != null) {
			meta = cast save.data.meta;
		}
		save.close();
		return meta;
	}

	// =========================================================================
	// Session-Cache & Level-Zustände (Multi-Level Unterstützung)
	// =========================================================================

	/**
	 * Ruft das `LevelSaveState`-Objekt für das angegebene Level ab oder erstellt ein neues.
	 *
	 * @param levelName Der Name des Levels (z. B. "Level_0").
	 * @param createIfMissing Erstellt bei `true` einen leeren State, falls noch keiner existiert.
	 */
	public static function getLevelState(levelName:String, createIfMissing:Bool = true):Null<LevelSaveState> {
		if (levelStates.exists(levelName)) {
			return levelStates.get(levelName);
		}
		if (createIfMissing) {
			var newState:LevelSaveState = {
				levelName: levelName,
				destroyedIids: [],
				entityStates: new Map(),
				customData: new Map()
			};
			levelStates.set(levelName, newState);
			return newState;
		}
		return null;
	}

	/**
	 * Erfasst alle serialisierbaren Zustände des übergebenen States im Session-Cache.
	 *
	 * @param state Der zu erfassende `mklib.state.State`.
	 */
	public static function captureLevel(state:State<Dynamic>):Void {
		if (state == null || state.levelName == null) {
			return;
		}

		var lvlState = getLevelState(state.levelName, true);

		// Iteriere über alle Sprites im State und erfasse ISaveable-Objekte
		state.forEachOfType(ISaveable, function(saveable:ISaveable) {
			captureEntity(saveable, state.levelName);
		}, true);
	}

	/**
	 * Stellt gespeicherte Daten für alle im übergebenen State vorhandenen Entities wieder her.
	 *
	 * @param state Der zu aktualisierende `mklib.state.State`.
	 */
	public static function restoreLevel(state:State<Dynamic>):Void {
		if (state == null || state.levelName == null) {
			return;
		}

		var lvlState = getLevelState(state.levelName, false);
		if (lvlState == null) {
			return;
		}

		state.forEachOfType(ISaveable, function(saveable:ISaveable) {
			restoreEntity(saveable, state.levelName);
		}, true);
	}

	/**
	 * Löscht den gesamten Session-Cache (Level-Zustände, Globals und Spielzeit) aus dem Arbeitsspeicher.
	 */
	public static function clearSession():Void {
		levelStates.clear();
		globals.clear();
		playTime = 0.0;
		lastCheckpointMeta = null;
	}

	// =========================================================================
	// Entity-Zustände & Zerstörungs-Tracking (IID)
	// =========================================================================

	/**
	 * Markiert eine Entity anhand ihrer LDtk-Instanz-ID (`iid`) als zerstört/aufgesammelt.
	 *
	 * @param iid Die weltweit eindeutige Instanz-ID der Entity aus LDtk.
	 * @param levelName Der Name des Levels (Standard: aktuelles Level aus `FlxG.state`).
	 */
	public static function markEntityDestroyed(iid:String, ?levelName:String):Void {
		var lvl = resolveLevelName(levelName);
		if (lvl == null || iid == null) {
			return;
		}

		var lvlState = getLevelState(lvl, true);
		if (lvlState.destroyedIids.indexOf(iid) == -1) {
			lvlState.destroyedIids.push(iid);
		}
	}

	/**
	 * Prüft, ob eine Entity anhand ihrer LDtk-Instanz-ID (`iid`) als zerstört markiert ist.
	 *
	 * @param iid Die Instanz-ID der Entity.
	 * @param levelName Der Name des Levels (Standard: aktuelles Level aus `FlxG.state`).
	 */
	public static function isEntityDestroyed(iid:String, ?levelName:String):Bool {
		var lvl = resolveLevelName(levelName);
		if (lvl == null || iid == null) {
			return false;
		}

		var lvlState = getLevelState(lvl, false);
		if (lvlState == null) {
			return false;
		}

		return lvlState.destroyedIids.indexOf(iid) != -1;
	}

	/**
	 * Speichert die Zustandsdaten einer Entity anhand ihrer `iid`.
	 */
	public static function setEntityData(iid:String, data:Dynamic, ?levelName:String):Void {
		var lvl = resolveLevelName(levelName);
		if (lvl == null || iid == null) {
			return;
		}

		var lvlState = getLevelState(lvl, true);
		lvlState.entityStates.set(iid, data);
	}

	/**
	 * Ruft die gespeicherten Zustandsdaten einer Entity anhand ihrer `iid` ab.
	 */
	public static function getEntityData(iid:String, ?levelName:String):Dynamic {
		var lvl = resolveLevelName(levelName);
		if (lvl == null || iid == null) {
			return null;
		}

		var lvlState = getLevelState(lvl, false);
		if (lvlState == null) {
			return null;
		}

		return lvlState.entityStates.get(iid);
	}

	/**
	 * Erfasst den Zustand eines `ISaveable`-Objekts und speichert ihn unter seiner `iid`.
	 */
	public static function captureEntity(saveable:Dynamic, ?levelName:String):Void {
		if (saveable == null) {
			return;
		}

		var iid:Null<String> = Reflect.field(saveable, "iid");
		if (iid != null && Std.isOfType(saveable, ISaveable)) {
			var isav:ISaveable = cast saveable;
			var data = isav.saveState();
			if (data != null) {
				setEntityData(iid, data, levelName);
			}
		}
	}

	/**
	 * Stellt den Zustand eines `ISaveable`-Objekts anhand seiner `iid` wieder her, sofern Daten existieren.
	 */
	public static function restoreEntity(saveable:Dynamic, ?levelName:String):Void {
		if (saveable == null) {
			return;
		}

		var iid:Null<String> = Reflect.field(saveable, "iid");
		if (iid != null && Std.isOfType(saveable, ISaveable)) {
			var data = getEntityData(iid, levelName);
			if (data != null) {
				var isav:ISaveable = cast saveable;
				isav.loadState(data);
			}
		}
	}

	// =========================================================================
	// Globale Variablen (Key-Value Datenbank)
	// =========================================================================

	/**
	 * Setzt eine globale Variable.
	 */
	public static function setGlobal(key:String, value:Dynamic):Void {
		globals.set(key, value);
	}

	/**
	 * Ruft eine globale Variable typisiert ab oder liefert den Standardwert zurück.
	 */
	public static function getGlobal<T>(key:String, ?defaultValue:T):T {
		if (globals.exists(key)) {
			return cast globals.get(key);
		}
		return defaultValue;
	}

	/**
	 * Prüft, ob eine globale Variable mit dem angegebenen Schlüssel existiert.
	 */
	public static function hasGlobal(key:String):Bool {
		return globals.exists(key);
	}

	/**
	 * Entfernt eine globale Variable.
	 */
	public static function removeGlobal(key:String):Void {
		globals.remove(key);
	}

	/**
	 * Löscht alle globalen Variablen.
	 */
	public static function clearGlobals():Void {
		globals.clear();
	}

	// =========================================================================
	// Interne Hilfsmethoden (Level-Name Auflösung & Obfuscation)
	// =========================================================================

	private static function resolveLevelName(?levelName:String):Null<String> {
		if (levelName != null) {
			return levelName;
		}
		if (FlxG.state != null && Std.isOfType(FlxG.state, State)) {
			var st:State<Dynamic> = cast FlxG.state;
			return st.levelName;
		}
		return null;
	}

	/**
	 * Einfache XOR-Verschleierung mit Base64-Kodierung.
	 */
	public static function obfuscateString(input:String, ?salt:String):String {
		if (input == null) {
			return "";
		}
		var keyStr = (salt != null && salt.length > 0) ? salt : "mklib_default_salt";
		var inputBytes = Bytes.ofString(input);
		var keyBytes = Bytes.ofString(keyStr);

		var resultBytes = Bytes.alloc(inputBytes.length);
		for (i in 0...inputBytes.length) {
			var b = inputBytes.get(i);
			var k = keyBytes.get(i % keyBytes.length);
			resultBytes.set(i, b ^ k);
		}

		return Base64.encode(resultBytes);
	}

	/**
	 * Dekodiert und entschlüsselt einen mit `obfuscateString` verschleierten String.
	 */
	public static function deobfuscateString(encoded:String, ?salt:String):String {
		if (encoded == null || encoded.length == 0) {
			return "";
		}
		var keyStr = (salt != null && salt.length > 0) ? salt : "mklib_default_salt";
		var encryptedBytes:Bytes = null;
		try {
			encryptedBytes = Base64.decode(encoded);
		} catch (e:Dynamic) {
			trace("[SaveManager] Base64 Dekodierungsfehler: " + Std.string(e));
			return "";
		}

		var keyBytes = Bytes.ofString(keyStr);
		var resultBytes = Bytes.alloc(encryptedBytes.length);
		for (i in 0...encryptedBytes.length) {
			var b = encryptedBytes.get(i);
			var k = keyBytes.get(i % keyBytes.length);
			resultBytes.set(i, b ^ k);
		}

		return resultBytes.toString();
	}
}
