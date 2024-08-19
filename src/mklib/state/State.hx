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

class State extends FlxState{

    public var project:Data;
    public var tags:Map<String,CbType>=new Map();
    public var levelName:String;
    public var levelData:Data.Data_Level;

    public function new(LevelName:String="Level_0") {
        
        super();
        this.levelName=LevelName;
        project=new Data();
        levelData=project.all_worlds.Default.getLevel(LevelName);

    }
    
    override function create():Void {
        
        super.create();

    }

    public function resolveLayer(layerName:String):ldtk.Layer{
        return levelData.resolveLayer(layerName);
    }

    public function renderEntityLayer(entities:Array<Dynamic>,packageName:String="entities"):FlxSpriteGroup {
        var container = new FlxSpriteGroup();
        add(container);
        
        for (i in 0...entities.length) {

            var entity:ldtk.Entity=entities[i];
            
            var className:String = packageName+"."+entity.identifier;

            var cl = Type.resolveClass(className);

            if (cl != null) {
                var instance = Type.createInstance(cl, [entity]);
                add(instance);

                
            } else {
                trace('Klasse ' + className + ' konnte nicht gefunden werden.');
            }
        }


        return container;
    }

    public function renderTileLayer(layerName:String):FlxSpriteGroup
    {
        var container = new FlxSpriteGroup();
        add(container);

        var layer:ldtk.Layer=resolveLayer(layerName);
        
        if(layer.type==LayerType.Tiles){
            
            var tileLayer:ldtk.Layer_Tiles = cast(layer,Layer_Tiles);
            tileLayer.render(container);

        }

        return container;
    }

    public function addCbTypes():Void 
    {
        
        var jsonTags:ldtk.Json.EnumDefJson = project.getEnumDefJson("Tags");

        for (value in jsonTags.values) {
            var cbtype:CbType=new CbType();
            tags.set(value.id,cbtype);
            FlxNapeSpace.space.world.cbTypes.add(cbtype);
        }
    }

    public function napeInit(gx:Int, gy:Int):Void {
        FlxNapeSpace.init();
        FlxNapeSpace.space.gravity.set(Vec2.weak(gx,gy));
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