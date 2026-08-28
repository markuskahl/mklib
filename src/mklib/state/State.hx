package mklib.state;

import ldtk.Project;
import nape.geom.Vec2;
import flixel.addons.nape.FlxNapeSpace;
import nape.callbacks.CbType;
import flixel.FlxG;
import flixel.FlxState;

/**
 * Generischer Basis-Game-State für HaxeFlixel-Projekte mit LDtk- und Nape-Integration.
 *
 * Verwaltet:
 * - Das LDtk-Projekt und das typisierte Level-Datenobjekt (`data`).
 * - Die automatische Initialisierung des Nape-Physikraums (`napeInit`).
 * - Die Konvertierung von LDtk-Tags (Enum "Tags") in Nape-`CbType`-Objekte.
 * - Das automatische, saubere Aufräumen von Nape-Space, CbTypes und LDtk-Referenzen beim State-Wechsel.
 *
 * @param TLevel Der Typ des LDtk-Levels (z. B. `Data.Data_Level`).
 */
class State<TLevel = Dynamic> extends FlxState {
	/**
	 * Die geladene LDtk-Projektinstanz.
	 */
	public var project:ldtk.Project;

	/**
	 * Eine Map von Tag-Namen (aus dem LDtk-Enum "Tags") auf die entsprechenden Nape-`CbType`-Instanzen.
	 */
	public var tags:Map<String, CbType> = new Map();

	/**
	 * Der Name des aktuell aktiven Levels (z. B. "Level_0").
	 */
	public var levelName:String;

	/**
	 * Die typisierten Leveldaten aus dem LDtk-Projekt.
	 */
	public var data:TLevel;

	/**
	 * Erstellt einen neuen State und lädt das angegebene Level aus dem LDtk-Projekt.
	 *
	 * @param LevelName Der Name des zu ladenden LDtk-Levels (Standard: "Level_0").
	 * @param projectInstance Optionale LDtk-Projektinstanz (falls null, wird versucht, die globale Klasse "Data" zu instanziieren).
	 */
	public function new(LevelName:String = "Level_0", ?projectInstance:ldtk.Project) {
		super();
		this.levelName = LevelName;
		if (projectInstance != null) {
			project = projectInstance;
		} else {
			var dataCls = Type.resolveClass("Data");
			if (dataCls != null) {
				project = Type.createInstance(dataCls, []);
			}
		}

		if (project != null) {
			var dynProject:Dynamic = project;
			if (dynProject.all_worlds != null && dynProject.all_worlds.Default != null) {
				data = cast dynProject.all_worlds.Default.getLevel(null, LevelName);
			} else if (Reflect.isFunction(dynProject.getLevel)) {
				data = cast dynProject.getLevel(null, LevelName);
			}
		}
	}

	/**
	 * Initialisiert den Spielzustand (`FlxState.create()`).
	 */
	override function create():Void {
		super.create();
	}

	/**
	 * Liest das Enum "Tags" aus der LDtk-Projektdefinition aus und erzeugt
	 * für jeden Wert einen entsprechenden Nape-`CbType` in der `tags`-Map.
	 */
	public function addCbTypes():Void {
		if (project == null) {
			return;
		}
		var jsonTags:ldtk.Json.EnumDefJson = project.getEnumDefJson(null, "Tags");
		if (jsonTags != null && jsonTags.values != null) {
			for (value in jsonTags.values) {
				var cbtype:CbType = new CbType();
				tags.set(value.id, cbtype);
			}
		}
	}

	/**
	 * Initialisiert den Nape-Physikraum (`FlxNapeSpace`) mit einer Gravitation
	 * und registriert automatisch alle LDtk-Tags als CbTypes.
	 *
	 * @param gx Gravitation in X-Richtung (Standard meist 0).
	 * @param gy Gravitation in Y-Richtung (z. B. 300 für Platformer-Schwerkraft nach unten).
	 */
	public function napeInit(gx:Int, gy:Int):Void {
		FlxNapeSpace.init();
		FlxNapeSpace.space.gravity.set(Vec2.weak(gx, gy));
		addCbTypes();
	}

	/**
	 * Haupt-Update-Schleife des States. Steuert u. a. die Maussichtbarkeit je nach Zielplattform.
	 *
	 * @param elapsed Die vergangene Zeit seit dem letzten Frame in Sekunden.
	 */
	override function update(elapsed:Float) {
		super.update(elapsed);
		#if windows
		FlxG.mouse.visible = true;
		#end

		#if html5
		FlxG.mouse.visible = false;
		#end
	}

	/**
	 * Räumt den State beim Wechsel sauber auf, um Speicherlecks zu verhindern.
	 * Leert den Nape-Physikraum, Nape-Listener, CbTypes sowie LDtk-Referenzen.
	 */
	override function destroy():Void {
		if (FlxNapeSpace.space != null) {
			FlxNapeSpace.space.listeners.clear();
			FlxNapeSpace.space.clear();
		}

		if (tags != null) {
			tags.clear();
			tags = null;
		}

		project = null;
		data = null;

		super.destroy();
	}
}
