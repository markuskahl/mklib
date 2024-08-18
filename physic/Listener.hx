package mklib.physic;


import flixel.addons.nape.FlxNapeSpace;
import mklib.tools.Tags;
import nape.callbacks.CbEvent;
import nape.callbacks.CbType;
import nape.callbacks.InteractionCallback;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionType;

class Listener
{
	public static function addCollisionBeginListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var listener:InteractionListener = new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, Tags.get(tag1), Tags.get(tag2), handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	public static function addCollisionEndListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var listener:InteractionListener = new InteractionListener(CbEvent.END, InteractionType.COLLISION, Tags.get(tag1), Tags.get(tag2), handler);

		FlxNapeSpace.space.listeners.add(listener);
	}

	public static function addCollisionOngoingListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var listener:InteractionListener = new InteractionListener(CbEvent.ONGOING, InteractionType.COLLISION, Tags.get(tag1), Tags.get(tag2), handler);

		FlxNapeSpace.space.listeners.add(listener);
	}

	public static function addSensorBeginListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var listener:InteractionListener = new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, Tags.get(tag1), Tags.get(tag2), handler);

		FlxNapeSpace.space.listeners.add(listener);
	}

	public static function addSensorEndListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var listener:InteractionListener = new InteractionListener(CbEvent.END, InteractionType.SENSOR, Tags.get(tag1), Tags.get(tag2), handler);

		FlxNapeSpace.space.listeners.add(listener);
	}

	public static function addSensorOngoingListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var listener:InteractionListener = new InteractionListener(CbEvent.ONGOING, InteractionType.SENSOR, Tags.get(tag1), Tags.get(tag2), handler);

		FlxNapeSpace.space.listeners.add(listener);
	}

	public static function addSensorBeginListenerANY(tag1:String, handler:InteractionCallback->Void):Void
	{
		var listener:InteractionListener = new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, Tags.get(tag1), CbType.ANY_BODY, handler);

		FlxNapeSpace.space.listeners.add(listener);
	}

	public static function addSensorEndListenerANY(tag1:String, handler:InteractionCallback->Void):Void
	{
		var listener:InteractionListener = new InteractionListener(CbEvent.END, InteractionType.SENSOR, Tags.get(tag1), CbType.ANY_BODY, handler);

		FlxNapeSpace.space.listeners.add(listener);
	}

	public static function addSensorOngoingListenerANY(tag1:String, handler:InteractionCallback->Void):Void
	{
		var listener:InteractionListener = new InteractionListener(CbEvent.ONGOING, InteractionType.SENSOR, Tags.get(tag1), CbType.ANY_BODY, handler);

		FlxNapeSpace.space.listeners.add(listener);
	}
}
