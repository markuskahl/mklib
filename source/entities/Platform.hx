package entities;

import mklib.entity.EntityNapeSprite;
import flixel.util.FlxColor;
import flixel.addons.nape.FlxNapeSprite;
import flixel.FlxSprite;

@:keep
class Platform extends EntityNapeSprite{
    public function new(entity:ldtk.Entity) {
        
        super(entity);

        makeGraphic(entity.width,entity.height,FlxColor.RED);
        createRectangularBody(entity.width,entity.height);
        body.allowMovement=false;

        updateShapePosition();

        addCbType();
        
    }
}