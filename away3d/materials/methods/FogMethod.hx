package away3d.materials.methods;

	//import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	
	//use namespace arcane;

	/**
	 * FogMethod provides a method to add distance-based fog to a material.
	 */
	class FogMethod extends EffectMethodBase
	{
		var _minDistance:Float = 0;
		var _maxDistance:Float = 1000;
		var _fogColor:UInt;
		var _fogR:Float;
		var _fogG:Float;
		var _fogB:Float;

		/**
		 * Creates a new FogMethod object.
		 * @param minDistance The distance from which the fog starts appearing.
		 * @param maxDistance The distance at which the fog is densest.
		 * @param fogColor The colour of the fog.
		 */
		public function new(minDistance:Float, maxDistance:Float, fogColor:UInt = 0x808080)
		{
			super();
			this.minDistance = minDistance;
			this.maxDistance = maxDistance;
			this.fogColor = fogColor;
		}

		/**
		 * @inheritDoc
		 */
		override public function initVO(vo:MethodVO):Void
		{
			vo.needsProjection = true;
		}

		/**
		 * @inheritDoc
		 */
		override public function initConstants(vo:MethodVO):Void
		{
			var data:Array<Float> = vo.fragmentData;
			var index:Int = vo.fragmentConstantsIndex;
			data[index + 3] = 1;
			data[index + 6] = 0;
			data[index + 7] = 0;
		}

		/**
		 * The distance from which the fog starts appearing.
		 */
		public var minDistance(get, set) : Float;
		public function get_minDistance() : Float
		{
			return _minDistance;
		}
		
		public function set_minDistance(value:Float) : Float
		{
			_minDistance = value;
		}

		/**
		 * The distance at which the fog is densest.
		 */
		public var maxDistance(get, set) : Float;
		public function get_maxDistance() : Float
		{
			return _maxDistance;
		}
		
		public function set_maxDistance(value:Float) : Float
		{
			_maxDistance = value;
		}

		/**
		 * The colour of the fog.
		 */
		public var fogColor(get, set) : UInt;
		public function get_fogColor() : UInt
		{
			return _fogColor;
		}
		
		public function set_fogColor(value:UInt) : UInt
		{
			_fogColor = value;
			_fogR = ((value >> 16) & 0xff)/0xff;
			_fogG = ((value >> 8) & 0xff)/0xff;
			_fogB = (value & 0xff)/0xff;
		}

		/**
		 * @inheritDoc
		 */
		override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			var data:Array<Float> = vo.fragmentData;
			var index:Int = vo.fragmentConstantsIndex;
			data[index] = _fogR;
			data[index + 1] = _fogG;
			data[index + 2] = _fogB;
			data[index + 4] = _minDistance;
			data[index + 5] = 1/(_maxDistance - _minDistance);
		}

		/**
		 * @inheritDoc
		 */
		override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var fogColor:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var fogData:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code:String = "";
			vo.fragmentConstantsIndex = fogColor.index*4;
			
			code += "sub " + temp2 + ".w, " + _sharedRegisters.projectionFragment + ".z, " + fogData + ".x          \n" +
				"mul " + temp2 + ".w, " + temp2 + ".w, " + fogData + ".y					\n" +
				"sat " + temp2 + ".w, " + temp2 + ".w										\n" +
				"sub " + temp + ", " + fogColor + ", " + targetReg + "\n" + 			// (fogColor- col)
				"mul " + temp + ", " + temp + ", " + temp2 + ".w					\n" +			// (fogColor- col)*fogRatio
				"add " + targetReg + ", " + targetReg + ", " + temp + "\n"; // fogRatio*(fogColor- col) + col
			
			regCache.removeFragmentTempUsage(temp);
			
			return code;
		}
	}

