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
		var cb1 = Tags.get(tag1);
		var cb2 = Tags.get(tag2);
		if (cb1 == null || cb2 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register CollisionBeginListener for "$tag1" and "$tag2" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, cb1, cb2, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	public static function addCollisionEndListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		var cb2 = Tags.get(tag2);
		if (cb1 == null || cb2 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register CollisionEndListener for "$tag1" and "$tag2" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.END, InteractionType.COLLISION, cb1, cb2, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	public static function addCollisionOngoingListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		var cb2 = Tags.get(tag2);
		if (cb1 == null || cb2 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register CollisionOngoingListener for "$tag1" and "$tag2" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.ONGOING, InteractionType.COLLISION, cb1, cb2, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	public static function addSensorBeginListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		var cb2 = Tags.get(tag2);
		if (cb1 == null || cb2 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register SensorBeginListener for "$tag1" and "$tag2" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, cb1, cb2, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	public static function addSensorEndListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		var cb2 = Tags.get(tag2);
		if (cb1 == null || cb2 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register SensorEndListener for "$tag1" and "$tag2" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.END, InteractionType.SENSOR, cb1, cb2, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	public static function addSensorOngoingListener(tag1:String, tag2:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		var cb2 = Tags.get(tag2);
		if (cb1 == null || cb2 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register SensorOngoingListener for "$tag1" and "$tag2" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.ONGOING, InteractionType.SENSOR, cb1, cb2, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	public static function addSensorBeginListenerANY(tag1:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		if (cb1 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register SensorBeginListenerANY for "$tag1" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, cb1, CbType.ANY_BODY, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	public static function addSensorEndListenerANY(tag1:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		if (cb1 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register SensorEndListenerANY for "$tag1" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.END, InteractionType.SENSOR, cb1, CbType.ANY_BODY, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}

	public static function addSensorOngoingListenerANY(tag1:String, handler:InteractionCallback->Void):Void
	{
		var cb1 = Tags.get(tag1);
		if (cb1 == null || FlxNapeSpace.space == null)
		{
			trace('Warning: Could not register SensorOngoingListenerANY for "$tag1" (CbType or space is null)');
			return;
		}
		var listener:InteractionListener = new InteractionListener(CbEvent.ONGOING, InteractionType.SENSOR, cb1, CbType.ANY_BODY, handler);
		FlxNapeSpace.space.listeners.add(listener);
	}
}
