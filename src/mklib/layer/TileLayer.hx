package mklib.layer;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import ldtk.Layer_Tiles;
import mklib.state.State;



class TileLayer extends FlxSpriteGroup
{
	public var levelName:String;
	public var layerName:String;
	public var state:State;

	public function new(LayerName:String)
	{
		super();
		if (FlxG.state != null && Std.isOfType(FlxG.state, State))
		{
			state = cast(FlxG.state, State);
			this.levelName = state.levelName;
		}
		this.layerName = LayerName;
		render();
	}

	public function render():FlxSpriteGroup
	{
		if (state == null || state.data == null)
		{
			return this;
		}

		clear();

		var layer:ldtk.Layer = state.data.resolveLayer(layerName);
		if (layer != null && Std.isOfType(layer, Layer_Tiles))
		{
			var tileLayer:ldtk.Layer_Tiles = cast(layer, Layer_Tiles);
			tileLayer.render(this);
		}

		return this;
	}
}
