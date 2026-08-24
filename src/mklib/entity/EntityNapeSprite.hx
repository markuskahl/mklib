package mklib.entity;

import nape.geom.Vec2;
import mklib.tools.Tags;
import mklib.state.State;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSprite;

class EntityNapeSprite extends FlxNapeSprite
{
    public var _entity:ldtk.Entity;
    public var iid:String;
    public var state:State;

    public function new(entity:ldtk.Entity)
    {
        iid = entity.iid;
        _entity = entity;
        super(entity.pixelX, entity.pixelY);

        if (FlxG.state != null && Std.isOfType(FlxG.state, State))
        {
            state = cast FlxG.state;
        }
    }

    public function addCbType(name:String = null):Void
    {
        if (body == null)
        {
            trace("Warning: Cannot add CbType because body is not yet initialized!");
            return;
        }

        if (name == null)
        {
            if (_entity != null && _entity.json != null && _entity.json.fieldInstances != null)
            {
                for (inst in _entity.json.fieldInstances)
                {
                    if (inst.__identifier == "Tag" || inst.__identifier == "Tags")
                    {
                        if (Std.isOfType(inst.__value, Array))
                        {
                            var arr:Array<Dynamic> = cast inst.__value;
                            for (val in arr)
                            {
                                var tagStr:String = Std.string(val);
                                if (Tags.exist(tagStr))
                                {
                                    body.cbTypes.add(Tags.get(tagStr));
                                }
                            }
                        }
                        else
                        {
                            var tagStr:String = Std.string(inst.__value);
                            if (Tags.exist(tagStr))
                            {
                                body.cbTypes.add(Tags.get(tagStr));
                            }
                        }
                    }
                }
            }
        }
        else
        {
            if (Tags.exist(name))
            {
                body.cbTypes.add(Tags.get(name));
            }
        }

        body.userData.instance = this;
    }

    public function updateShapePosition():Void
    {
        if (body != null && _entity != null)
        {
            body.position.setxy(_entity.pixelX + (_entity.width / 2), _entity.pixelY + (_entity.height / 2));
        }
    }
}
