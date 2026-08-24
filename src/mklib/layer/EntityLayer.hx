package mklib.layer;

import mklib.state.State;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.FlxG;

class EntityLayer extends FlxSpriteGroup
{
	public var layerName:String;
	public var state:State;

	public function new(LayerName:String, ?Entities:Array<Data.Data_Entity>)
	{
		super();
		if (FlxG.state != null && Std.isOfType(FlxG.state, State))
		{
			state = cast(FlxG.state, State);
		}
		this.layerName = LayerName;
		if (Entities != null)
		{
			addEntities(Entities);
		}
	}

	public function addEntities(entities:Array<Data.Data_Entity>):Void
	{
		if (entities == null)
		{
			return;
		}

		for (i in 0...entities.length)
		{
			var entityName = entities[i].entityType.getName();

			var cls = Type.resolveClass("entities." + entityName);
			if (cls != null)
			{
				var o:Dynamic = Type.createInstance(cls, [entities[i]]);
				if (Std.isOfType(o, FlxSprite))
				{
					add(cast o);
				}
			}
			else
			{
				trace('Error: Class "entities.' + entityName + '" does not exist!');
			}
		}
	}

	public inline function addEntites(entities:Array<Data.Data_Entity>):Void
	{
		addEntities(entities);
	}
}
