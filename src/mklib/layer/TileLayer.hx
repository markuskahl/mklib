package mklib.layer;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import ldtk.Layer_Tiles;
import mklib.state.State;

/**
 * Verwaltet und rendert Kachelebenen (Tilemaps / AutoLayers) aus einem LDtk-Level.
 *
 * Erbt von `FlxSpriteGroup` und nutzt die native LDtk-Render-Methode, um alle Kacheln
 * des Layers direkt in diese SpriteGroup einzufügen.
 */
class TileLayer extends FlxSpriteGroup
{
	/**
	 * Der Name des aktiven Levels.
	 */
	public var levelName:String;

	/**
	 * Der Bezeichner des LDtk-Tile-Layers (z. B. "Tiles", "Background").
	 */
	public var layerName:String;

	/**
	 * Referenz auf den aktuellen `mklib.state.State`.
	 */
	public var state:State;

	/**
	 * Erstellt einen neuen `TileLayer` und rendert die Kacheln sofort.
	 *
	 * @param LayerName Der Bezeichner des Layers im LDtk-Projekt.
	 */
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

	/**
	 * Leert die SpriteGroup und rendert den LDtk-Tile-Layer neu.
	 *
	 * @return Diese Instanz von `FlxSpriteGroup` (Fluent Interface).
	 */
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
