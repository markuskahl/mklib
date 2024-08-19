package mklib.entity;

import nape.geom.Vec2;
import mklib.tools.Tags;
import flixel.util.FlxColor;
import mklib.state.State;
import flixel.FlxG;
import flixel.input.FlxAccelerometer;
import nape.callbacks.CbType;
import ldtk.Json.TilesetRect;
import ldtk.Json.EntityReferenceInfos;
import dn.FilePath;
import ldtk.Json.GridPoint;
import ldtk.Point;
import ldtk.Json.Tile;
import haxe.Json;
import ldtk.Json.FieldDefJson;
import ldtk.Json.FieldType;
import flixel.addons.nape.FlxNapeSprite;


class EntityNapeSprite extends FlxNapeSprite{

    public var _entity:ldtk.Entity;
    public var iid:String;
    public var state:State;

    public function new(entity:ldtk.Entity) {
        
        iid=entity.iid;

        _entity=entity;

        super(entity.pixelX,entity.pixelY);

        state=cast FlxG.state;

    }

    public function addCbType(name:String=null):Void {
        
        if(name==null){

            for (inst in _entity.json.fieldInstances) {
                
                if(inst.__identifier=="Tag"){
                    
                    if(Tags.exist(inst.__value)){
                        body.cbTypes.add(Tags.get(inst.__value));
                    }
                    
                }
                
            }
            
        }else{
            
            if(Tags.exist(name)){
                
                body.cbTypes.add(Tags.get(name));
                
            }
        }

        body.userData.instance=this;
    }

    public function updateShapePosition():Void {
        body.position.set(Vec2.weak(_entity.pixelX+(_entity.width/2),_entity.pixelY+(_entity.height/2)));
    }
    
}
