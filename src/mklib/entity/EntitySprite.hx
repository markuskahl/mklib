package mklib.entity;

import flixel.FlxG;
import mklib.state.State;
import flixel.FlxSprite;

class EntitySprite extends FlxSprite{
    

    public var iid:String;
    public var state:State;

    public function new(entity:ldtk.Entity) {
        
        super(entity.pixelX,entity.pixelY);
        iid=entity.iid;
        width=entity.width;
        height=entity.height;
        state=cast FlxG.state;
        
    }

}