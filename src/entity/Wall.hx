package mklib.entity;

import nape.geom.Vec2;
import flixel.util.FlxColor;



class Wall extends mklib.entity.Entity{
    
    public function new(entity:ldtk.Entity) {
        
        
        super(entity);

        makeGraphic(entity.width,entity.height,FlxColor.WHITE);

        createRectangularBody(entity.width,entity.height);


        body.position.set(Vec2.weak(x+(width/2),y+(height/2)));
        body.allowMovement=false;
        body.allowRotation=false;

        visible=false;
        //alpha=.6;

        setBodyMaterial(0,0,0,0);

        body.cbTypes.add(state.tags.get("Wall"));


    }


}