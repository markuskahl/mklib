package mklib.state;

import flixel.system.scaleModes.StageSizeScaleMode;
import nape.geom.Vec2;
import flixel.addons.nape.FlxNapeSpace;
import nape.callbacks.CbType;
import flixel.FlxG;
import flixel.FlxState;
import ldtk.Layer_Tiles;
import flixel.group.FlxSpriteGroup;
import mklib.assets.Data;

class State extends FlxState{

    public var project:Data;
    public var tags:Map<String,CbType>=new Map();
    

    public function new() {
        super();
        project=new Data();
    }
    
    override function create():Void {
        
        super.create();
        
        //FlxG.scaleMode = new flixel.system.scaleModes.RatioScaleMode(true);

        
    }


    public function renderTileLayer(layer:Layer_Tiles):FlxSpriteGroup
    {
        var container = new FlxSpriteGroup();
        add(container);
        layer.render(container);
        return container;
    }

    public function addCbTypes():Void {
        
            
            for (tag in Data.Enum_Tags.createAll()) {
                var cbtype:CbType=new CbType();
                tags.set(tag.getName(),cbtype);
                FlxNapeSpace.space.world.cbTypes.add(cbtype);
            }
    }

    public function napeInit() {
        FlxNapeSpace.init();
        FlxNapeSpace.space.gravity.set(Vec2.weak(0,300));
        addCbTypes();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        #if windows
		FlxG.mouse.visible = false;
        #end

        #if html5
		FlxG.mouse.visible = false;
        #end
    }
}