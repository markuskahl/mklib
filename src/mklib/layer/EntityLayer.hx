package mklib.layer;

import ldtk.Entity;
import mklib.state.State;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.FlxG;

typedef EntityLayerSource<T = Dynamic> = {
	var identifier:String;
	function getAllUntyped():Array<T>;
}

class EntityLayer extends FlxSpriteGroup
{
	public var layerName:String;
	public var packageName:String;
	public var state:State<Dynamic>;

	public function new(layer:EntityLayerSource<Dynamic>, packageName:String = "entities")
	{
		super();
		this.packageName = packageName;
		if (FlxG.state != null && Std.isOfType(FlxG.state, State))
		{
			state = cast(FlxG.state, State);
		}

		if (layer != null)
		{
			this.layerName = layer.identifier;
			var untypedList:Array<Dynamic> = layer.getAllUntyped();
			if (untypedList != null)
			{
				var entityList:Array<ldtk.Entity> = [for (e in untypedList) cast e];
				addEntities(entityList);
			}
		}
	}

	public function addEntities(entities:Array<ldtk.Entity>):Void
	{
		if (entities == null)
		{
			return;
		}

		for (i in 0...entities.length)
		{
			var entity:ldtk.Entity = entities[i];
			var entityName:String = entity.identifier;

			var targetClass:String = (packageName != null && packageName.length > 0) ? (packageName + "." + entityName) : entityName;
			var cls = Type.resolveClass(targetClass);
			if (cls != null)
			{
				var o:Dynamic = Type.createInstance(cls, [entity]);
				if (Std.isOfType(o, FlxSprite))
				{
					add(cast o);
				}
			}
			else
			{
				trace('Error: Class "' + targetClass + '" does not exist!');
			}
		}
	}
}
