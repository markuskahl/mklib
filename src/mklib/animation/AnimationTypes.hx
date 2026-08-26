package mklib.animation;

typedef FrameConfig = {
	var width:Int;
	var height:Int;
	var ?spacing:Int;
	var ?margin:Int;
}

typedef AnimationClip = {
	var name:String;
	var fps:Int;
	var loop:Bool;
	var flipX:Bool;
	var flipY:Bool;
	var frames:Array<Int>;
}

typedef SpriteSheetData = {
	var imagePath:String;
	var config:FrameConfig;
	var animations:Array<AnimationClip>;
	var defaultAnimation:String;
}
