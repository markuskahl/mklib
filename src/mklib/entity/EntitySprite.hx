package mklib.entity;

import flixel.FlxG;
import mklib.state.State;
import flixel.FlxSprite;

class EntitySprite extends FlxSprite
{
    public var _entity:ldtk.Entity;
    public var iid:String;
    public var state:State;

    public function new(entity:ldtk.Entity)
    {
        _entity = entity;
        super(entity.pixelX, entity.pixelY);
        iid = entity.iid;
        width = entity.width;
        height = entity.height;
        if (FlxG.state != null && Std.isOfType(FlxG.state, State))
        {
            state = cast FlxG.state;
        }
    }
}