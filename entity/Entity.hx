package mklib.entity;

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


class Entity extends FlxNapeSprite{

    public var _entity:ldtk.Entity;
    public var iid:String;
    public var state:PlayState;
    

    public function new(entity:ldtk.Entity) {
        
        _entity=entity;
        iid=_entity.iid;

        super(entity.pixelX,entity.pixelY);

        state=cast FlxG.state;

    }

    public function setFields() {
        
        trace(_entity.json.fieldInstances);


        for (field in _entity.json.fieldInstances)
            {
                
                // String, Int, Float, Text, Bool, Color, Enum, Point, Path, EntityRef, Tile    


                try
                {
                    //Reflect.setProperty(this, field.__identifier, field.__value);
        
                    
                    if(Reflect.hasField(this,field.__identifier)){

                        switch field.__type{
                            case "String":{
                                var v:String=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }
                            case "Int":{
                                var v:Int=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }
    
                            case "Float":{
                                var v:Float=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }

                            case "Point":{
                                var v:GridPoint=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }

                            case "Bool":{
                                var v:Bool=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }

                            case "Color":{
                                var v:String=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }

                            case "Tile":{
                                var v:Tile=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }

                            case "FilePath":{
                                var v:String=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }
    
                            case "EntityRef":{
                                var v:EntityReferenceInfos=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }

                            // ******************** Arrays ***************************

                            case "Array<String>":{
                                var v:Array<String>=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }

                            case "Array<Int>":{
                                var v:Array<Int>=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }

                            case "Array<Float>":{
                                var v:Array<Float>=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }

                            case "Array<Point>":{
                                var v:Array<Point>=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }

                            case "Array<Bool>":{
                                var v:Array<Bool>=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }

                            case "Array<Color>":{
                                var v:Array<String>=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }

                            case "Array<Tile>":{
                                var v:Array<Tile>=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }

                            case "Array<FilePath>":{
                                var v:Array<String>=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }

                            case "Array<EntityRef>":{
                                var v:Array<EntityReferenceInfos>=cast field.__value;
                                Reflect.setField(this,field.__identifier,v);
                            }
                        }

                    }



                }
                catch (e)
                {
                    trace("variable not found");
                }
            }
    }

    public function getInt(name:String):Int {

        var r:Int=0;

        for (i in 0..._entity.json.fieldInstances.length) {
            if(_entity.json.fieldInstances[i].__identifier==name && _entity.json.fieldInstances[i].__type=="Int"){
                r=cast _entity.json.fieldInstances[i].__value;
            }
        }

        return r;
    }

    public function getFloat(name:String):Float {

        var r:Float=0;

        for (i in 0..._entity.json.fieldInstances.length) {
            if(_entity.json.fieldInstances[i].__identifier==name && _entity.json.fieldInstances[i].__type=="Float"){
                r=cast _entity.json.fieldInstances[i].__value;
            }
        }

        return r;
    }

    public function getString(name:String):String {

        var r:String="";

        for (i in 0..._entity.json.fieldInstances.length) {
            if(_entity.json.fieldInstances[i].__identifier==name && _entity.json.fieldInstances[i].__type=="String"){
                r=cast _entity.json.fieldInstances[i].__value;
            }
        }

        return r;
    }

    public function getBool(name:String):Bool {

        var r:Bool=true;

        for (i in 0..._entity.json.fieldInstances.length) {
            if(_entity.json.fieldInstances[i].__identifier==name && _entity.json.fieldInstances[i].__type=="Bool"){
                r=cast _entity.json.fieldInstances[i].__value;
            }
        }

        return r;
    }

    public function getPoint(name:String):GridPoint {

        var p:GridPoint={cx:0,cy:0};

        for (i in 0..._entity.json.fieldInstances.length) {
            
            if(_entity.json.fieldInstances[i].__identifier==name && _entity.json.fieldInstances[i].__type=="Point"){
                p=cast _entity.json.fieldInstances[i].__value;
            }
        }

        return p;
    }

    public function getFilePath(name:String):String {

        var v:String="";

        for (i in 0..._entity.json.fieldInstances.length) {
            
            if(_entity.json.fieldInstances[i].__identifier==name && _entity.json.fieldInstances[i].__type=="FilePath"){
                v=cast _entity.json.fieldInstances[i].__value;
            }
        }

        return v;
    }

    public function getColor(name:String):String {

        var v:String="";

        for (i in 0..._entity.json.fieldInstances.length) {
            
            if(_entity.json.fieldInstances[i].__identifier==name && _entity.json.fieldInstances[i].__type=="Color"){
                v=cast _entity.json.fieldInstances[i].__value;
            }
        }

        return v;
    }

    public function getEntityRef(name:String):EntityReferenceInfos {

        var v:EntityReferenceInfos=null;

        for (i in 0..._entity.json.fieldInstances.length) {
            
            if(_entity.json.fieldInstances[i].__identifier==name && _entity.json.fieldInstances[i].__type=="EntityRef"){
                v=cast _entity.json.fieldInstances[i].__value;
            }
        }

        return v;
    }

    public function getTile(name:String):Tile {

        var v:Tile=null;

        for (i in 0..._entity.json.fieldInstances.length) {

            if(_entity.json.fieldInstances[i].__identifier==name && _entity.json.fieldInstances[i].__type=="Tile"){
                v=cast _entity.json.fieldInstances[i].__value;
            }
        }

        return v;
    }

    public function getEnum(name:String):Dynamic {

        var v:Dynamic=null;

        for (i in 0..._entity.json.fieldInstances.length) {

            var type:String="LocalEnum."+name;

            if(_entity.json.fieldInstances[i].__identifier==name && _entity.json.fieldInstances[i].__type==type){
                v=cast _entity.json.fieldInstances[i].__value;
            }
        }

        return v;
    }
    


    public function getArrayString(name:String):Array<String> {

        var r:Array<String>=[];

        for (i in 0..._entity.json.fieldInstances.length) {

            trace(_entity.json.fieldInstances[i].__type);

            if(_entity.json.fieldInstances[i].__identifier==name && _entity.json.fieldInstances[i].__type=="Array<String>"){
                r=cast _entity.json.fieldInstances[i].__value;
            }
        }

        return r;
    }

    public function getArrayInt(name:String):Array<Int> {

        var r:Array<Int>=[];

        for (i in 0..._entity.json.fieldInstances.length) {

            trace(_entity.json.fieldInstances[i].__type);

            if(_entity.json.fieldInstances[i].__identifier==name && _entity.json.fieldInstances[i].__type=="Array<Int>"){
                r=cast _entity.json.fieldInstances[i].__value;
            }
        }

        return r;
    }

    public function getArrayFloat(name:String):Array<Float> {

        var r:Array<Float>=[];

        for (i in 0..._entity.json.fieldInstances.length) {

            trace(_entity.json.fieldInstances[i].__type);

            if(_entity.json.fieldInstances[i].__identifier==name && _entity.json.fieldInstances[i].__type=="Array<Float>"){
                r=cast _entity.json.fieldInstances[i].__value;
            }
        }

        return r;
    }

    public function getArrayTile(name:String):Array<Tile> {

        var r:Array<Tile>=[];

        for (i in 0..._entity.json.fieldInstances.length) {

            trace(_entity.json.fieldInstances[i].__type);

            if(_entity.json.fieldInstances[i].__identifier==name && _entity.json.fieldInstances[i].__type=="Array<Tile>"){
                r=cast _entity.json.fieldInstances[i].__value;
            }
        }

        return r;
    }

    public function getArrayPoint(name:String):Array<GridPoint> {

        var r:Array<GridPoint>=[];

        for (i in 0..._entity.json.fieldInstances.length) {

            if(_entity.json.fieldInstances[i].__identifier==name && _entity.json.fieldInstances[i].__type=="Array<Point>"){
                r=cast _entity.json.fieldInstances[i].__value;
            }
        }

        return r;
    }

    public function getArrayEnum(name:String):Array<Dynamic> {

        var r:Array<Dynamic>=[];

        for (i in 0..._entity.json.fieldInstances.length) {

            var type:String= "Array<LocalEnum."+name+">";

            if(_entity.json.fieldInstances[i].__identifier==name && _entity.json.fieldInstances[i].__type==type){
                r=cast _entity.json.fieldInstances[i].__value;
            }
        }

        return r;
    }



}
