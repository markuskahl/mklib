package mklib.state;

import ldtk.Json.LevelJson;
import ldtk.Layer;
import ldtk.Layer_Entities;
import ldtk.Project;
import ldtk.Json.LayerType;
import nape.geom.Vec2;
import flixel.addons.nape.FlxNapeSpace;
import nape.callbacks.CbType;
import flixel.FlxG;
import flixel.FlxState;
import ldtk.Layer_Tiles;
import flixel.group.FlxSpriteGroup;

class State extends FlxState {
	public var project:Data;
	public var tags:Map<String, CbType> = new Map();
	public var levelName:String;
	public var data:Data.Data_Level;

	public function new(LevelName:String = "Level_0") {
		super();
		this.levelName = LevelName;
		project = new Data();
		data = project.all_worlds.Default.getLevel(LevelName);
	}

	override function create():Void {
		super.create();
	}

	public function addCbTypes():Void {
		var jsonTags:ldtk.Json.EnumDefJson = project.getEnumDefJson("Tags");
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
