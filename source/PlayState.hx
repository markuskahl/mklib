package;

import flixel.util.FlxColor;
import flixel.FlxG;
import mklib.state.State;


class PlayState extends State
{
	override public function create()
	{
		super.create();


		//FlxG.camera.bgColor=FlxColor.WHITE;
		napeInit(0,300);		
		addCbTypes();
		
		
		renderTileLayer("Tiles");
		
        renderEntityLayer(levelData.l_Entities.getAllUntyped());
        
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if(FlxG.keys.justPressed.F){
			FlxG.fullscreen=!FlxG.fullscreen;
		}
	}
}