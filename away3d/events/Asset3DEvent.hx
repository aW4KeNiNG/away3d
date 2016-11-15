/**
 * Dispatched whenever a ressource (asset) is parsed and created completly.
 */
package away3d.events;

import away3d.library.assets.IAsset;
import openfl.events.Event;

class Asset3DEvent extends Event {
	public var asset(get, never):IAsset;
	public var assetPrevName(get, never):String;

	static public var ASSET_COMPLETE:String = "assetComplete";
	static public var ENTITY_COMPLETE:String = "entityComplete";
	static public var SKYBOX_COMPLETE:String = "skyboxComplete";
	static public var CAMERA_COMPLETE:String = "cameraComplete";
	static public var MESH_COMPLETE:String = "meshComplete";
	static public var GEOMETRY_COMPLETE:String = "geometryComplete";
	static public var SKELETON_COMPLETE:String = "skeletonComplete";
	static public var SKELETON_POSE_COMPLETE:String = "skeletonPoseComplete";
	static public var CONTAINER_COMPLETE:String = "containerComplete";
	static public var TEXTURE_COMPLETE:String = "textureComplete";
	static public var TEXTURE_PROJECTOR_COMPLETE:String = "textureProjectorComplete";
	static public var MATERIAL_COMPLETE:String = "materialComplete";
	static public var ANIMATOR_COMPLETE:String = "animatorComplete";
	static public var ANIMATION_SET_COMPLETE:String = "animationSetComplete";
	static public var ANIMATION_STATE_COMPLETE:String = "animationStateComplete";
	static public var ANIMATION_NODE_COMPLETE:String = "animationNodeComplete";
	static public var STATE_TRANSITION_COMPLETE:String = "stateTransitionComplete";
	static public var SEGMENT_SET_COMPLETE:String = "segmentSetComplete";
	static public var LIGHT_COMPLETE:String = "lightComplete";
	static public var LIGHTPICKER_COMPLETE:String = "lightPickerComplete";
	static public var EFFECTMETHOD_COMPLETE:String = "effectMethodComplete";
	static public var SHADOWMAPMETHOD_COMPLETE:String = "shadowMapMethodComplete";
	static public var ASSET_RENAME:String = "assetRename";
	static public var ASSET_CONFLICT_RESOLVED:String = "assetConflictResolved";
	static public var TEXTURE_SIZE_ERROR:String = "textureSizeError";
	private var _asset:IAsset;
	private var _prevName:String;

	public function new(type:String, asset:IAsset = null, prevName:String = null) {
		super(type);
		_asset = asset;
		if (prevName != null)
			_prevName = prevName;
		else
			_prevName = ((_asset != null) ? _asset.name : null);
	}

	private function get_asset():IAsset {
		return _asset;
	}

	private function get_assetPrevName():String {
		return _prevName;
	}

	override public function clone():Event {
		var a = new Asset3DEvent(type, asset, assetPrevName);
		#if html 
		a.target = this.target;
		a.currentTarget = this.currentTarget;
		#end
		return a;
	}
}

