package away3d.events;

import openfl.events.Event;

class LightEvent extends Event {

	static public var CASTS_SHADOW_CHANGE:String = "castsShadowChange";

	public function new(type:String) {
		super(type);
	}

	override public function clone():Event {
		return new LightEvent(type);
	}
}

