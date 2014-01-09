package away3d.materials.methods;

	import away3d.*;
	import away3d.cameras.*;
	import away3d.core.base.*;
	import away3d.core.managers.*;
	import away3d.events.*;
	import away3d.lights.*;
	import away3d.lights.shadowmaps.*;
	import away3d.materials.compilation.*;
	
	import flash.events.*;
	
	//use namespace arcane;

	/**
	 * CascadeShadowMapMethod is a shadow map method to apply cascade shadow mapping on materials.
	 * Must be used with a DirectionalLight with a CascadeShadowMapper assigned to its shadowMapper property.
	 *
	 * @see away3d.lights.shadowmaps.CascadeShadowMapper
	 */
	class CascadeShadowMapMethod extends ShadowMapMethodBase
	{
		var _baseMethod:SimpleShadowMapMethodBase;
		var _cascadeShadowMapper:CascadeShadowMapper;
		var _depthMapCoordVaryings:Array<ShaderRegisterElement>;
		var _cascadeProjections:Array<ShaderRegisterElement>;
		
		/**
		 * Creates a new CascadeShadowMapMethod object.
		 *
		 * @param shadowMethodBase The shadow map sampling method used to sample individual cascades (fe: HardShadowMapMethod, SoftShadowMapMethod)
		 */
		public function new(shadowMethodBase:SimpleShadowMapMethodBase)
		{
			super(shadowMethodBase.castingLight);
			_baseMethod = shadowMethodBase;
			if (!(_castingLight is DirectionalLight))
				throw new Error("CascadeShadowMapMethod is only compatible with DirectionalLight");
			_cascadeShadowMapper = _castingLight.shadowMapper as CascadeShadowMapper;
			
			if (!_cascadeShadowMapper)
				throw new Error("CascadeShadowMapMethod requires a light that has a CascadeShadowMapper instance assigned to shadowMapper.");
			
			_cascadeShadowMapper.addEventListener(Event.CHANGE, onCascadeChange, false, 0, true);
			_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated, false, 0, true);
		}

		/**
		 * The shadow map sampling method used to sample individual cascades. These are typically those used in conjunction
		 * with a DirectionalShadowMapper.
		 *
		 * @see HardShadowMapMethod
		 * @see SoftShadowMapMethod
		 */
		public var baseMethod(get, set) : SimpleShadowMapMethodBase;
		public function get_baseMethod() : SimpleShadowMapMethodBase
		{
			return _baseMethod;
		}
		
		public function set_baseMethod(value:SimpleShadowMapMethodBase) : SimpleShadowMapMethodBase
		{
			if (_baseMethod == value)
				return;
			_baseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_baseMethod = value;
			_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated, false, 0, true);
			invalidateShaderProgram();
		}

		/**
		 * @inheritDoc
		 */
		override public function initVO(vo:MethodVO):Void
		{
			var tempVO:MethodVO = new MethodVO();
			_baseMethod.initVO(tempVO);
			vo.needsGlobalVertexPos = true;
			vo.needsProjection = true;
		}

		/**
		 * @inheritDoc
		 */
		public var sharedRegisters(null, set) : Void;
		override public function set_sharedRegisters(value:ShaderRegisterData) : Void
		{
			super.sharedRegisters = value;
			_baseMethod.sharedRegisters = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function initConstants(vo:MethodVO):Void
		{
			var fragmentData:Array<Float> = vo.fragmentData;
			var vertexData:Array<Float> = vo.vertexData;
			var index:Int = vo.fragmentConstantsIndex;
			fragmentData[index] = 1.0;
			fragmentData[index + 1] = 1/255.0;
			fragmentData[index + 2] = 1/65025.0;
			fragmentData[index + 3] = 1/16581375.0;
			
			fragmentData[index + 6] = .5;
			fragmentData[index + 7] = -.5;
			
			index = vo.vertexConstantsIndex;
			vertexData[index] = .5;
			vertexData[index + 1] = -.5;
			vertexData[index + 2] = 0;
		}

		/**
		 * @inheritDoc
		 */
		override function cleanCompilationData():Void
		{
			super.cleanCompilationData();
			_cascadeProjections = null;
			_depthMapCoordVaryings = null;
		}

		/**
		 * @inheritDoc
		 */
		override public function getVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			var code:String = "";
			var dataReg:ShaderRegisterElement = regCache.getFreeVertexConstant();
			
			initProjectionsRegs(regCache);
			vo.vertexConstantsIndex = dataReg.index*4;
			
			var temp:ShaderRegisterElement = regCache.getFreeVertexVectorTemp();
			
			// For loop conversion - 						for (var i:Int = 0; i < _cascadeShadowMapper.numCascades; ++i)
			
			var i:Int;
			
			for (i in 0..._cascadeShadowMapper.numCascades) {
				code += "m44 " + temp + ", " + _sharedRegisters.globalPositionVertex + ", " + _cascadeProjections[i] + "\n" +
					"add " + _depthMapCoordVaryings[i] + ", " + temp + ", " + dataReg + ".zzwz\n";
			}
			
			return code;
		}

		/**
		 * Creates the registers for the cascades' projection coordinates.
		 */
		private function initProjectionsRegs(regCache:ShaderRegisterCache):Void
		{
			_cascadeProjections = new Array<ShaderRegisterElement>(_cascadeShadowMapper.numCascades);
			_depthMapCoordVaryings = new Array<ShaderRegisterElement>(_cascadeShadowMapper.numCascades);
			
			// For loop conversion - 						for (var i:Int = 0; i < _cascadeShadowMapper.numCascades; ++i)
			
			var i:Int;
			
			for (i in 0..._cascadeShadowMapper.numCascades) {
				_depthMapCoordVaryings[i] = regCache.getFreeVarying();
				_cascadeProjections[i] = regCache.getFreeVertexConstant();
				regCache.getFreeVertexConstant();
				regCache.getFreeVertexConstant();
				regCache.getFreeVertexConstant();
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var numCascades:Int = _cascadeShadowMapper.numCascades;
			var depthMapRegister:ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var planeDistanceReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var planeDistances:Array<String> = new <String>[ planeDistanceReg + ".x", planeDistanceReg + ".y", planeDistanceReg + ".z", planeDistanceReg + ".w" ];
			var code:String;
			
			vo.fragmentConstantsIndex = decReg.index*4;
			vo.texturesIndex = depthMapRegister.index;
			
			var inQuad:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(inQuad, 1);
			var uvCoord:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(uvCoord, 1);
			
			// assume lowest partition is selected, will be overwritten later otherwise
			code = "mov " + uvCoord + ", " + _depthMapCoordVaryings[numCascades - 1] + "\n";
			
			// For loop conversion - 						for (var i:Int = numCascades - 2; i >= 0; --i)
			
			var i:Int;
			
			for (i in numCascades - 2...0) {
				var uvProjection:ShaderRegisterElement = _depthMapCoordVaryings[i];
				
				// calculate if in texturemap (result == 0 or 1, only 1 for a single partition)
				code += "slt " + inQuad + ".z, " + _sharedRegisters.projectionFragment + ".z, " + planeDistances[i] + "\n"; // z = x > minX, w = y > minY
				
				var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
				
				// linearly interpolate between old and new uv coords using predicate value == conditional toggle to new value if predicate == 1 (true)
				code += "sub " + temp + ", " + uvProjection + ", " + uvCoord + "\n" +
					"mul " + temp + ", " + temp + ", " + inQuad + ".z\n" +
					"add " + uvCoord + ", " + uvCoord + ", " + temp + "\n";
			}
			
			regCache.removeFragmentTempUsage(inQuad);
			
			code += "div " + uvCoord + ", " + uvCoord + ", " + uvCoord + ".w\n" +
				"mul " + uvCoord + ".xy, " + uvCoord + ".xy, " + dataReg + ".zw\n" +
				"add " + uvCoord + ".xy, " + uvCoord + ".xy, " + dataReg + ".zz\n";
			
			code += _baseMethod.getCascadeFragmentCode(vo, regCache, decReg, depthMapRegister, uvCoord, targetReg) +
				"add " + targetReg + ".w, " + targetReg + ".w, " + dataReg + ".y\n";
			
			regCache.removeFragmentTempUsage(uvCoord);
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _castingLight.shadowMapper.depthMap.getTextureForStage3D(stage3DProxy));
			
			var vertexData:Array<Float> = vo.vertexData;
			var vertexIndex:Int = vo.vertexConstantsIndex;
			
			vo.vertexData[vo.vertexConstantsIndex + 3] = -1/(_cascadeShadowMapper.depth*_epsilon);
			
			var numCascades:Int = _cascadeShadowMapper.numCascades;
			vertexIndex += 4;
			// For loop conversion - 			for (var k:Int = 0; k < numCascades; ++k)
			var k:Int;
			for (k in 0...numCascades) {
				_cascadeShadowMapper.getDepthProjections(k).copyRawDataTo(vertexData, vertexIndex, true);
				vertexIndex += 16;
			}
			
			var fragmentData:Array<Float> = vo.fragmentData;
			var fragmentIndex:Int = vo.fragmentConstantsIndex;
			fragmentData[uint(fragmentIndex + 5)] = 1 - _alpha;
			
			var nearPlaneDistances:Array<Float> = _cascadeShadowMapper.nearPlaneDistances;
			
			fragmentIndex += 8;
			// For loop conversion - 			for (var i:UInt = 0; i < numCascades; ++i)
			var i:UInt = 0;
			for (i in 0...numCascades)
				fragmentData[uint(fragmentIndex + i)] = nearPlaneDistances[i];
			
			_baseMethod.activateForCascade(vo, stage3DProxy);
		}

		/**
		 * @inheritDoc
		 */
		override function setRenderState(vo:MethodVO, renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
		{
		}

		/**
		 * Called when the shadow mappers cascade configuration changes.
		 */
		private function onCascadeChange(event:Event):Void
		{
			invalidateShaderProgram();
		}

		/**
		 * Called when the base method's shader code is invalidated.
		 */
		private function onShaderInvalidated(event:ShadingMethodEvent):Void
		{
			invalidateShaderProgram();
		}
	}

