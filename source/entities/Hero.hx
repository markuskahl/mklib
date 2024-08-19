package entities;

import mklib.entity.EntitySprite;
import flixel.util.FlxColor;
import ldtk.Entity;

@:keep
class Hero extends EntitySprite{
    

    public var _v:Data.Entity_Hero;

    public function new(entity:ldtk.Entity) {
        
        super(entity);

        makeGraphic(entity.width,entity.height,FlxColor.WHITE);
   
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
    }

}