package mklib.state;

import ldtk.Project;
import nape.geom.Vec2;
import flixel.addons.nape.FlxNapeSpace;
import nape.callbacks.CbType;
import flixel.FlxG;
import flixel.FlxState;

class State<TLevel = Dynamic> extends FlxState {
	public var project:ldtk.Project;
	public var tags:Map<String, CbType> = new Map();
	public var levelName:String;
	public var data:TLevel;

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

	override function create():Void {
		super.create();
	}

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

	public function napeInit(gx:Int, gy:Int):Void {
		FlxNapeSpace.init();
		FlxNapeSpace.space.gravity.set(Vec2.weak(gx, gy));
		addCbTypes();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		#if windows
		FlxG.mouse.visible = true;
		#end

		#if html5
		FlxG.mouse.visible = false;
		#end
	}
}
