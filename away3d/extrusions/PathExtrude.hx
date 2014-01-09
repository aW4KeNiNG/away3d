package away3d.extrusions;

	import away3d.bounds.BoundingVolumeBase;
	import away3d.core.base.Geometry;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.SubMesh;
	import away3d.core.base.data.UV;
	import away3d.core.base.data.Vertex;
	import away3d.core.math.Vector3DUtils;
	import away3d.entities.Mesh;
	import away3d.materials.MaterialBase;
	import away3d.paths.IPath;
	import away3d.paths.IPathSegment;
	import away3d.tools.helpers.MeshHelper;
	
	import away3d.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	[Deprecated]
	class PathExtrude extends Mesh
	{
		var _varr:Array<Vertex>;
		var _doubles:Array<Vertex> = new Array<Vertex>();
		var _upAxis:Vector3D = new Vector3D(0, 1, 0);
		var _trans:Matrix3D = new Matrix3D();
		
		private var LIMIT:UInt = 196605;
		private var MAXRAD:Float = 1.2;
		var _path:IPath;
		var _profile:Array<Vector3D>;
		var _centerMesh:Bool;
		var _scales:Array<Vector3D>;
		var _rotations:Array<Vector3D>;
		var _materials:Array<MaterialBase>;
		var _activeMaterial:MaterialBase;
		var _subdivision:UInt;
		var _coverAll:Bool;
		var _coverSegment:Bool;
		var _flip:Bool;
		var _mapFit:Bool;
		var _closePath:Bool;
		var _alignToPath:Bool;
		var _smoothScale:Bool;
		var _smoothSurface:Bool;
		var _isClosedProfile:Bool;
		var _maxIndProfile:UInt;
		var _matIndex:UInt = 0;
		var _segv:Float;
		var _geomDirty:Bool = true;
		var _subGeometry:SubGeometry;
		var _MaterialsSubGeometries:Array<SubGeometryList> = new Array<SubGeometryList>();
		var _uva:UV;
		var _uvb:UV;
		var _uvc:UV;
		var _uvd:UV;
		var _uvs:Array<Float>;
		var _vertices:Array<Float>;
		var _indices:Array<UInt>;
		var _normals:Array<Float>;
		var _normalTmp:Vector3D;
		var _normal0:Vector3D;
		var _normal1:Vector3D;
		var _normal2:Vector3D;
		var _keepExtremes:Bool;
		var _distribute:Bool;
		var _distributeU:Bool;
		var _distributedU:Array<Float>;
		var _startPoints:Array<Vector3D>;
		var _endPoints:Array<Vector3D>;
		
		/**
		 * Creates a new <code>PathExtrude</code>
		 *
		 * @param    material                [optional]     MaterialBase. The PathExtrude (Mesh) material. Optional in constructor, material must be set before PathExtrude object is rendered. Required for the class to work.
		 * @param    path                    [optional]     Path. Defines the <code>Path</code> object representing path to extrude along. Required for the class to work.
		 * @param    profile                [optional]     Vector.&lt;Vector3D&gt;. Defines an Vector.&lt;Vector3D&gt; of Vector3D objects representing the profile information to be projected along the Path object. Required for the class to work.
		 * @param    subdivision            [optional]    uint. Howmany steps between each PathSegment. If the path holds curves, the higher this value, the higher the curve fidelity. Default and minimum is 2;
		 * @param    coverall                [optional]     Boolean. Defines the uv mapping, when true a unique material is stretched along the entire path/shape. Default is true.
		 * @param    coverSegment    [optional]     Boolean. Defines the uv mapping, when true and coverall is false a unique material is stretched along one PathSegment. Default is false.
		 * @param    alignToPath        [optional]    Boolean. If the profile must follow the path or keep its original orientation.
		 * @param    centerMesh        [optional]     Boolean. If the geometry needs to be recentered in its own object space. If the position after generation is set to 0,0,0, the object would be centered in worldspace. Default is false.
		 * @param    mapFit                [optional]    Boolean. The UV mapping is percentually spreaded over the width of the path, making texture looking nicer and edits for applications such as a race track, road, more easy. Affects the uv's u values and set distributeU to false. Default is false.
		 * @param    flip                    [optional]    Boolean. If the faces must be reversed depending on Vector3D's orientation. Default is false.
		 * @param    closePath            [optional]    Boolean. If the last PathSegment entered must be welded back to first one. Executed in a straight manner, its recommanded to pass the first entry to the Path again, as last entry if curves are involved.
		 * @param    materials            [optional]    Vector.&lt;MaterialBase&gt;. An optional Vector.&lt;MaterialBase&gt; of different materials that can be alternated along the path if coverAll is false.
		 * @param    scales                [optional]    An optional Vector.&lt;Vector3D&gt; of <code>Vector3D</code> objects that defines a series of scales to be set on each PathSegment.
		 * @param    smoothScale        [optional]    Boolean. Defines if the scale must be interpolated between values or keep their full aspect on each PathSegment.
		 * @param    rotations            [optional]    An optional Vector.&lt;Vector3D&gt; of <code>Vector3D</code> objects that defines a series of rotations to be set on each PathSegment.
		 * @param    smoothSurface    [optional]    An optional Boolean. Defines if the surface of the mesh must be smoothed or not. Default is true.
		 * @param    distribute            [optional]    Boolean. If the mesh subdivision is evenly spreaded over the entire mesh. Depending on path definition, segments are possibly not having the same amount of subdivision.
		 * @param    distributeU            [optional]    Boolean. If the mesh uv' u value is procentually spreaded over the entire mesh surface. Prevents the source map to be stretched. Default is true.
		 * @param    keepExtremes        [optional]    Boolean. If the the first and last profile coordinates must be kept accessible, in order to feed classes such as DelaunayMesh. Default is false;
		 */
		function PathExtrude(material:MaterialBase = null, path:IPath = null, profile:Array<Vector3D> = null, subdivision:UInt = 2, coverAll:Bool = true, coverSegment:Bool = false, alignToPath:Bool = true, centerMesh:Bool = false, mapFit:Bool = false, flip:Bool = false, closePath:Bool = false, materials:Array<MaterialBase> = null, scales:Array<Vector3D> = null, smoothScale:Bool = true, rotations:Array<Vector3D> = null, smoothSurface:Bool = true, distribute:Bool = false, distributeU:Bool = true, keepExtremes:Bool = false)
		{
			distribute = distribute;
			
			var geom:Geometry = new Geometry();
			_subGeometry = new SubGeometry();
			super(geom, material);
			
			_activeMaterial = this.material;
			_path = path;
			this.profile = profile;
			this.subdivision = subdivision;
			_coverSegment = coverSegment;
			_coverAll = (_coverSegment)? false : coverAll;
			_alignToPath = alignToPath;
			_centerMesh = centerMesh;
			_mapFit = mapFit;
			_flip = flip;
			_closePath = closePath;
			_materials = (materials)? materials : new Array<MaterialBase>();
			_scales = scales;
			_smoothScale = smoothScale;
			_rotations = rotations;
			_smoothSurface = smoothSurface;
			_distributeU = distributeU;
			_keepExtremes = keepExtremes;
		}
		
		public var upAxis(get, set) : Vector3D;
		
		public function get_upAxis() : Vector3D
		{
			return _upAxis;
		}
		
		public function set_upAxis(value:Vector3D) : Vector3D
		{
			_upAxis = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get_bounds() : BoundingVolumeBase
		{
			if (_geomDirty)
				buildExtrude();
			
			return super.bounds;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get_geometry() : Geometry
		{
			if (_geomDirty)
				buildExtrude();
			
			return super.geometry;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get_subMeshes() : Array<SubMesh>
		{
			if (_geomDirty)
				buildExtrude();
			
			return super.subMeshes;
		}
		
		/**
		 * Defines whether the mesh is recentered of not after generation
		 */
		public var centerMesh(get, set) : Bool;
		public function get_centerMesh() : Bool
		{
			return _centerMesh;
		}
		
		public function set_centerMesh(val:Bool) : Bool
		{
			if (_centerMesh == val)
				return;
			
			_centerMesh = val;
			
			if (_centerMesh && this.geometry.subGeometries.length > 0)
				MeshHelper.recenter(this);
			else
				invalidateGeometry();
		}
		
		/**
		 * Defines the uv's u values are spreaded procentually over the entire surface to prevent the maps to be stretched.
		 */
		public var distributeU(get, set) : Bool;
		public function get_distributeU() : Bool
		{
			return _distributeU;
		}
		
		public function set_distributeU(val:Bool) : Bool
		{
			if (_distributeU == val)
				return;
			
			_distributeU = val;
			
			if (val && _mapFit)
				_mapFit = false;
			if (!val && _distributedU)
				_distributedU = null;
			
			invalidateGeometry();
		}
		
		/**
		 * Invalidates the geometry, causing it to be rebuillded when requested.
		 */
		private function invalidateGeometry():Void
		{
			_geomDirty = true;
			invalidateBounds();
		}
		
		/**
		 * Defines the <code>Path</code> object representing path to extrude along. Required.
		 */
		public var path(get, set) : IPath;
		public function get_path() : IPath
		{
			return _path;
		}
		
		public function set_path(val:IPath) : IPath
		{
			_path = val;
			_geomDirty = true;
		}
		
		/**
		 * Defines a Vector.&lt;Vector3D&gt; of Vector3D objects representing the profile information to be projected along the Path object. Required.
		 */
		public var profile(get, set) : Array<Vector3D>;
		public function get_profile() : Array<Vector3D>
		{
			return _profile;
		}
		
		public function set_profile(val:Array<Vector3D>) : Array<Vector3D>
		{
			_profile = val;
			
			if (_profile != null)
				_isClosedProfile = (_profile[0].x == _profile[_profile.length - 1].x && _profile[0].y == _profile[_profile.length - 1].y && _profile[0].z == _profile[_profile.length - 1].z);
			
			_geomDirty = true;
		}
		
		/**
		 * An optional Vector.&lt;Vector3D&gt; of <code>Vector3D</code> objects that defines a series of scales to be set on each PathSegment.
		 */
		public var scales(get, set) : Array<Vector3D>;
		public function get_scales() : Array<Vector3D>
		{
			return _scales;
		}
		
		public function set_scales(val:Array<Vector3D>) : Array<Vector3D>
		{
			_scales = val;
			_geomDirty = true;
		}
		
		/**
		 * An optional Vector.&lt;Vector3D&gt; of <code>Vector3D</code> objects that defines a series of rotations to be set on each PathSegment.
		 */
		public var rotations(get, set) : Array<Vector3D>;
		public function get_rotations() : Array<Vector3D>
		{
			return _rotations;
		}
		
		public function set_rotations(val:Array<Vector3D>) : Array<Vector3D>
		{
			_rotations = val;
			_geomDirty = true;
		}
		
		/**
		 * An optional Vector.&lt;MaterialBase&gt;. It defines a series of materials to be set on each PathSegment if coverAll is set to false.
		 */
		public var materials(get, set) : Array<Vector3D>;
		public function get_materials() : Array<MaterialBase>
		{
			return _materials;
		}
		
		public function set_materials(val:Array<MaterialBase>) : Array<Vector3D>
		{
			if (val == null)
				return;
			_materials = val;
			_geomDirty = true;
		}
		
		/**
		 * Defines the subdivisions created in the mesh for each PathSegment. Defaults to 2, minimum 2.
		 */
		public var subdivision(get, set) : Int;
		public function get_subdivision() : Int
		{
			return _subdivision;
		}
		
		public function set_subdivision(val:Int) : Int
		{
			val = (val < 2)? 2 : val;
			
			if (_subdivision == val)
				return;
			
			_subdivision = val;
			_geomDirty = true;
		}
		
		/**
		 * Defines if the texture(s) should be stretched to cover the entire mesh or per step between segments. Defaults to true.
		 */
		public var coverAll(get, set) : Bool;
		public function get_coverAll() : Bool
		{
			return _coverAll;
		}
		
		public function set_coverAll(val:Bool) : Bool
		{
			if (_coverAll == val)
				return;
			
			_coverAll = val;
			_geomDirty = true;
		}
		
		/**
		 * Defines if the mesh subdivision is spread evenly over the entire geometry. Possibly resulting in uneven subdivision per segments.
		 * Uv mapping is less distorted on complex shapes once applied. Depending on Path length, extra construct time might be significant.
		 * Defaults to false.
		 */
		public var distribute(get, set) : Bool;
		public function get_distribute() : Bool
		{
			return _distribute;
		}
		
		public function set_distribute(val:Bool) : Bool
		{
			if (_distribute == val)
				return;
			
			_distribute = val;
			_geomDirty = true;
		}
		
		/**
		 * Defines if the surface of the mesh must be smoothed or not.
		 */
		public var smoothSurface(get, set) : Bool;
		public function get_smoothSurface() : Bool
		{
			return _smoothSurface;
		}
		
		public function set_smoothSurface(val:Bool) : Bool
		{
			if (_smoothSurface == val)
				return;
			
			_smoothSurface = val;
			_geomDirty = true;
		}
		
		/**
		 * Defines if the texture(s) should applied per segment. Default false.
		 */
		public function set_coverSegment(b:Bool) : Void
		{
			_coverSegment = b;
		}
		
		public var coverSegment(get, set) : Void;
		
		public function get_coverSegment() : Void
		{
			return _coverSegment;
		}
		
		/**
		 * Defines if the texture(s) should be projected on the geometry evenly spreaded over the source bitmapdata or using distance/percent. Default is false.
		 * The mapping considers first and last profile points are the most distant from each other. Most left and most right on the map.
		 * Note that it is NOT suitable for most cases. It is helpfull for roads definition, usually seen from above with simple profile. It prevents then distorts and eases map designs.
		 */
		public var mapFit(get, set) : Bool;
		public function get_mapFit() : Bool
		{
			return _mapFit;
		}
		
		public function set_mapFit(val:Bool) : Bool
		{
			if (_mapFit == val)
				return;
			
			if (val && _distributeU)
				_distributeU = false;
			
			_mapFit = val;
			_geomDirty = true;
		}
		
		/**
		 * Defines if the generated faces should be inversed. Default false.
		 */
		public var flip(get, set) : Bool;
		public function get_flip() : Bool
		{
			return _flip;
		}
		
		public function set_flip(val:Bool) : Bool
		{
			if (_flip == val)
				return;
			
			_flip = val;
			_geomDirty = true;
		}
		
		/**
		 * Defines if the last PathSegment should join the first one and close the loop. Defaults to false.
		 */
		public var closePath(get, set) : Bool;
		public function get_closePath() : Bool
		{
			return _closePath;
		}
		
		public function set_closePath(val:Bool) : Bool
		{
			if (_closePath == val)
				return;
			
			_closePath = val;
			_geomDirty = true;
		}
		
		/**
		 * Defines if the array of profile points should be orientated on path or not. Default true. Note that Path object's worldaxis property might need to be changed. default = 0,1,0.
		 *
		 * @see #profile
		 */
		public var aligntoPath(get, null) : Bool;
		public function get_aligntoPath() : Bool
		{
			return _alignToPath;
		}
		
		public var alignToPath(null, set) : Void;
		
		public function set_alignToPath(val:Bool) : Void
		{
			if (_alignToPath == val)
				return;
			
			_alignToPath = val;
			_geomDirty = true;
		}
		
		/**
		 * Defines if a scaling of a PathSegment defined from the scales array of <code>Vector3D</code> objects should affect the whole PathSegment evenly or be smoothly interpolated from previous PathSegment scale. Defaults to true.
		 */
		public var smoothScale(get, set) : Bool;
		public function get_smoothScale() : Bool
		{
			return _smoothScale;
		}
		
		public function set_smoothScale(val:Bool) : Bool
		{
			if (_smoothScale == val)
				return;
			
			_smoothScale = val;
			_geomDirty = true;
		}
		
		/**
		 * Defines if the first and last transformed vector3d's of the profile are kept.
		 * For instance to be able to pass these coordinates to DelaunayMesh class, to close the extrude, if it was a tube.
		 * @see getStartProfile
		 * @see getEndProfile
		 */
		public var keepExtremes(get, set) : Bool;
		public function get_keepExtremes() : Bool
		{
			return _keepExtremes;
		}
		
		public function set_keepExtremes(b:Bool) : Bool
		{
			_keepExtremes = b;
		}
		
		/**
		 * returns a vector of vector3d's representing the transformed profile coordinates at the start of the extrude shape
		 * null if "keepExtremes" is false or if the extrusion has not been builded yet.
		 */
		public var startProfile(get, null) : Array<Vector3D>;
		public function get_startProfile() : Array<Vector3D>
		{
			if (!_path || !_startPoints)
				return null;
			
			return _startPoints;
		}
		
		/**
		 * returns a vector of vector3d's representing the transformed profile coordinates at the end of the extrude shape
		 * null if "keepExtremes" is false or if the extrusion has not been builded yet.
		 */
		public var endProfile(get, null) : Array<Vector3D>;
		public function get_endProfile() : Array<Vector3D>
		{
			if (!_path || !_endPoints)
				return null;
			
			return _endPoints;
		}
		
		private function orientateAt(target:Vector3D, position:Vector3D):Void
		{
			var xAxis:Vector3D;
			var yAxis:Vector3D;
			var zAxis:Vector3D = target.subtract(position);
			
			zAxis.normalize();
			
			if (zAxis.length > 0.1) {
				xAxis = _upAxis.crossProduct(zAxis);
				xAxis.normalize();
				
				yAxis = xAxis.crossProduct(zAxis);
				yAxis.normalize();
				
				var rawData:Array<Float> = _trans.rawData;
				
				rawData[0] = xAxis.x;
				rawData[1] = xAxis.y;
				rawData[2] = xAxis.z;
				
				rawData[4] = -yAxis.x;
				rawData[5] = -yAxis.y;
				rawData[6] = -yAxis.z;
				
				rawData[8] = zAxis.x;
				rawData[9] = zAxis.y;
				rawData[10] = zAxis.z;
				
				_trans.rawData = rawData;
			}
		}
		
		private function generate(points:Array<Array<Vector3D>>, offsetV:Int = 0, closedata:Bool = false):Void
		{
			var uvlength:Int = (points.length - 1) + offsetV;
			var offset:UInt;
			
			// For loop conversion - 						for (var i:UInt = 0; i < points.length - 1; ++i)
			
			var i:UInt = 0;
			
			for (i in 0...points.length - 1) {
				_varr = new Array<Vertex>();
				offset = (closedata)? i + uvlength : i;
				
				extrudePoints(points[i], points[i + 1], (1/uvlength)*offset, uvlength, offset/(_subdivision - 1));
				
				if (i == 0 && _isClosedProfile)
					_doubles = Lambda.array(_varr);
			}
			_varr = _doubles = null;
		}
		
		private function extrudePoints(points1:Array<Vector3D>, points2:Array<Vector3D>, vscale:Float, indexv:Int, indexp:Float):Void
		{
			var i:Int;
			var j:Int;
			
			var stepx:Float;
			var stepy:Float;
			var stepz:Float;
			
			var va:Vertex;
			var vb:Vertex;
			var vc:Vertex;
			var vd:Vertex;
			
			var u1:Float;
			var u2:Float;
			var index:UInt = 0;
			
			var v1:Float = 0;
			var v2:Float = 0;
			
			var countloop:Int = points1.length;
			
			var mat:MaterialBase;
			
			if (_mapFit) {
				var dist:Float = 0;
				var tdist:Float;
				var bleft:Vector3D;
				// For loop conversion - 				for (i = 0; i < countloop; ++i)
				for (i in 0...countloop) {
					// For loop conversion - 					for (j = 0; j < countloop; ++j)
					for (j in 0...countloop) {
						if (i != j) {
							tdist = Vector3D.distance(points1[i], points1[j]);
							if (tdist > dist) {
								dist = tdist;
								bleft = points1[i];
							}
						}
					}
				}
				
			} else {
				var bu:Float = 0;
				var bincu:Float = 1/(countloop - 1);
			}
			
			function getDouble(x:Float, y:Float, z:Float):Vertex
			{
				// For loop conversion - 				for (var i:Int = 0; i < _doubles.length; ++i)
				var i:Int;
				for (i in 0..._doubles.length) {
					if (_doubles[i].x == x && _doubles[i].y == y && _doubles[i].z == z) {
						return _doubles[i];
					}
				}
				return new Vertex(x, y, z);
			}
			
			// For loop conversion - 						for (i = 0; i < countloop; ++i)
			
			for (i in 0...countloop) {
				stepx = points2[i].x - points1[i].x;
				stepy = points2[i].y - points1[i].y;
				stepz = points2[i].z - points1[i].z;
				
				// For loop conversion - 								for (j = 0; j < 2; ++j)
				
				for (j in 0...2) {
					if (_isClosedProfile && _doubles.length > 0)
						_varr.push(getDouble(points1[i].x + (stepx*j), points1[i].y + (stepy*j), points1[i].z + (stepz*j)));
					else
						_varr.push(new Vertex(points1[i].x + (stepx*j), points1[i].y + (stepy*j), points1[i].z + (stepz*j)));
				}
			}
			
			var floored:UInt = _coverSegment? indexp : 0;
			
			if (_materials && _materials.length > 0) {
				
				if (_coverSegment && indexp - floored == 0)
					_matIndex = (_matIndex + 1 > _materials.length - 1)? 0 : _matIndex + 1;
				else if (!coverAll && !_coverSegment)
					_matIndex = (_matIndex + 1 > _materials.length - 1)? 0 : _matIndex + 1;
			}
			
			mat = ( _coverAll || !_materials || _materials.length == 0)? this.material : _materials[_matIndex];
			
			var covSub:Bool = _coverAll && _subdivision > 1;
			var cosegSub:Bool = _coverSegment && _subdivision > 1;
			
			// For loop conversion - 						for (i = 0; i < countloop - 1; ++i)
			
			for (i in 0...countloop - 1) {
				
				if (_distributeU) {
					u1 = _distributedU[i];
					u2 = _distributedU[i + 1];
					
				} else if (_mapFit) {
					u1 = 1 - Vector3D.distance(points1[i], bleft)/dist;
					u2 = 1 - Vector3D.distance(points1[i + 1], bleft)/dist;
					
				} else {
					u1 = 1 - bu;
					bu += bincu;
					u2 = 1 - bu;
				}
				
				v1 = (covSub)? vscale : ( (cosegSub)? indexp - floored : 0 );
				v2 = (covSub)? vscale + (1/indexv) : ( (cosegSub)? v1 + _segv : 1 );
				
				_uva.u = u1;
				_uva.v = v1;
				_uvb.u = u1;
				_uvb.v = v2;
				_uvc.u = u2;
				_uvc.v = v2;
				_uvd.u = u2;
				_uvd.v = v1;
				
				va = _varr[index];
				vb = _varr[index + 1];
				vc = _varr[index + 3];
				vd = _varr[index + 2];
				
				if (_flip) {
					addFace(vb, va, vc, _uvb, _uva, _uvc, mat);
					addFace(vc, va, vd, _uvc, _uva, _uvd, mat);
					
				} else {
					addFace(va, vb, vc, _uva, _uvb, _uvc, mat);
					addFace(va, vc, vd, _uva, _uvc, _uvd, mat);
				}
				
				if (_mapFit)
					u1 = u2;
				
				index += 2;
			}
		}
		
		private function initHolders():Void
		{
			if (!_uva) {
				_uva = new UV(0, 0);
				_uvb = new UV(0, 0);
				_uvc = new UV(0, 0);
				_uvd = new UV(0, 0);
				_normal0 = new Vector3D(0.0, 0.0, 0.0);
				_normal1 = new Vector3D(0.0, 0.0, 0.0);
				_normal2 = new Vector3D(0.0, 0.0, 0.0);
				_normalTmp = new Vector3D(0.0, 0.0, 0.0);
			}
			
			if (_materials && _materials.length > 0) {
				var sglist:SubGeometryList = new SubGeometryList();
				_MaterialsSubGeometries.push(sglist);
				sglist.subGeometry = new SubGeometry();
				_subGeometry = sglist.subGeometry;
				
				sglist.uvs = _uvs = new Array<Float>();
				sglist.vertices = _vertices = new Array<Float>();
				if (_smoothSurface)
					sglist.normals = _normals = new Array<Float>();
				sglist.indices = _indices = new Array<UInt>();
				sglist.material = this.material;
				if (sglist.material.name == null)
					sglist.material.name = "baseMaterial";
				
				_matIndex = _materials.length;
				
			} else {
				_uvs = new Array<Float>();
				_vertices = new Array<Float>();
				_indices = new Array<UInt>();
				if (_smoothSurface)
					_normals = new Array<Float>();
				else
					_subGeometry.autoDeriveVertexNormals = true;
				_subGeometry.autoDeriveVertexTangents = true;
			}
		}
		
		private function getSubGeometryListFromMaterial(mat:MaterialBase):SubGeometryList
		{
			var sglist:SubGeometryList;
			
			// For loop conversion - 						for (var i:UInt = 0; i < _MaterialsSubGeometries.length; ++i)
			
			var i:UInt = 0;
			
			for (i in 0..._MaterialsSubGeometries.length) {
				if (_MaterialsSubGeometries[i].material == mat) {
					sglist = _MaterialsSubGeometries[i];
					break;
				}
			}
			
			if (!sglist) {
				sglist = new SubGeometryList();
				_MaterialsSubGeometries.push(sglist);
				sglist.subGeometry = new SubGeometry();
				sglist.uvs = new Array<Float>();
				sglist.vertices = new Array<Float>();
				sglist.indices = new Array<UInt>();
				sglist.material = mat;
				if (_smoothSurface)
					sglist.normals = new Array<Float>();
			}
			
			return sglist;
		}
		
		private function calcNormal(v0:Vertex, v1:Vertex, v2:Vertex):Void
		{
			var dx1:Float = v2.x - v0.x;
			var dy1:Float = v2.y - v0.y;
			var dz1:Float = v2.z - v0.z;
			var dx2:Float = v1.x - v0.x;
			var dy2:Float = v1.y - v0.y;
			var dz2:Float = v1.z - v0.z;
			
			var cx:Float = dz1*dy2 - dy1*dz2;
			var cy:Float = dx1*dz2 - dz1*dx2;
			var cz:Float = dy1*dx2 - dx1*dy2;
			var d:Float = 1/Math.sqrt(cx*cx + cy*cy + cz*cz);
			
			_normal0.x = _normal1.x = _normal2.x = cx*d;
			_normal0.y = _normal1.y = _normal2.y = cy*d;
			_normal0.z = _normal1.z = _normal2.z = cz*d;
		}
		
		private function addFace(v0:Vertex, v1:Vertex, v2:Vertex, uv0:UV, uv1:UV, uv2:UV, mat:MaterialBase):Void
		{
			var subGeom:SubGeometry;
			var uvs:Array<Float>;
			var vertices:Array<Float>;
			var normals:Array<Float>;
			var indices:Array<UInt>;
			var sglist:SubGeometryList;
			var startMat:Bool;
			
			if (_activeMaterial != mat && _materials && _materials.length > 0) {
				_activeMaterial = mat;
				sglist = getSubGeometryListFromMaterial(mat);
				_subGeometry = subGeom = sglist.subGeometry;
				_uvs = uvs = sglist.uvs;
				_vertices = vertices = sglist.vertices;
				_indices = indices = sglist.indices;
				_normals = normals = sglist.normals;
				startMat = true;
				
			} else {
				subGeom = _subGeometry;
				uvs = _uvs;
				vertices = _vertices;
				indices = _indices;
				normals = _normals;
			}
			
			if (vertices.length + 9 > LIMIT) {
				subGeom.updateVertexData(vertices);
				subGeom.updateIndexData(indices);
				subGeom.updateUVData(uvs);
				if (_smoothSurface)
					subGeom.updateVertexNormalData(normals);
				
				this.geometry.addSubGeometry(subGeom);
				this.subMeshes[this.subMeshes.length - 1].material = mat;
				
				subGeom = new SubGeometry();
				subGeom.autoDeriveVertexTangents = true;
				if (!_smoothSurface)
					subGeom.autoDeriveVertexNormals = true;
				
				if (_MaterialsSubGeometries && _MaterialsSubGeometries.length > 1) {
					
					sglist = getSubGeometryListFromMaterial(mat);
					sglist.subGeometry = _subGeometry = subGeom;
					sglist.uvs = _uvs = uvs = new Array<Float>();
					sglist.vertices = _vertices = vertices = new Array<Float>();
					sglist.indices = _indices = indices = new Array<UInt>();
					if (_smoothSurface)
						sglist.normals = _normals = normals = new Array<Float>();
					
				} else {
					
					_subGeometry = subGeom;
					uvs = _uvs = new Array<Float>();
					vertices = _vertices = new Array<Float>();
					indices = _indices = new Array<UInt>();
					normals = _normals = new Array<Float>();
				}
			}
			
			var bv0:Bool;
			var bv1:Bool;
			var bv2:Bool;
			
			var ind0:UInt;
			var ind1:UInt;
			var ind2:UInt;
			
			if (_smoothSurface && !startMat) {
				var uvind:UInt;
				var uvindV:UInt;
				var vind:UInt;
				var vindy:UInt;
				var vindz:UInt;
				var ind:UInt;
				var indlength:UInt = indices.length;
				calcNormal(v0, v1, v2);
				var ab:Float;
				
				if (indlength > 0) {
					var back:Float = indlength - _maxIndProfile;
					var limitBack:UInt = (back < 0)? 0 : back;
					
					// For loop conversion - 										for (var i:UInt = indlength - 1; i > limitBack; --i)
					
					var i:UInt = 0;
					
					for (i in indlength - 1...limitBack) {
						ind = indices[i];
						vind = ind*3;
						vindy = vind + 1;
						vindz = vind + 2;
						uvind = ind*2;
						uvindV = uvind + 1;
						
						if (bv0 && bv1 && bv2)
							break;
						
						if (!bv0 && vertices[vind] == v0.x && vertices[vindy] == v0.y && vertices[vindz] == v0.z) {
							
							_normalTmp.x = normals[vind];
							_normalTmp.y = normals[vindy];
							_normalTmp.z = normals[vindz];
							ab = Vector3D.angleBetween(_normalTmp, _normal0);
							
							if (ab < MAXRAD) {
								_normal0.x = (_normalTmp.x + _normal0.x)*.5;
								_normal0.y = (_normalTmp.y + _normal0.y)*.5;
								_normal0.z = (_normalTmp.z + _normal0.z)*.5;
								
								if (_coverAll || uvs[uvind] == uv0.u && uvs[uvindV] == uv0.v) {
									bv0 = true;
									ind0 = ind;
									continue;
								}
							}
						}
						
						if (!bv1 && vertices[vind] == v1.x && vertices[vindy] == v1.y && vertices[vindz] == v1.z) {
							
							_normalTmp.x = normals[vind];
							_normalTmp.y = normals[vindy];
							_normalTmp.z = normals[vindz];
							ab = Vector3D.angleBetween(_normalTmp, _normal1);
							
							if (ab < MAXRAD) {
								_normal1.x = (_normalTmp.x + _normal1.x)*.5;
								_normal1.y = (_normalTmp.y + _normal1.y)*.5;
								_normal1.z = (_normalTmp.z + _normal1.z)*.5;
								
								if (_coverAll || uvs[uvind] == uv1.u && uvs[uvindV] == uv1.v) {
									bv1 = true;
									ind1 = ind;
									continue;
								}
							}
						}
						
						if (!bv2 && vertices[vind] == v2.x && vertices[vindy] == v2.y && vertices[vindz] == v2.z) {
							
							_normalTmp.x = normals[vind];
							_normalTmp.y = normals[vindy];
							_normalTmp.z = normals[vindz];
							ab = Vector3D.angleBetween(_normalTmp, _normal2);
							
							if (ab < MAXRAD) {
								_normal2.x = (_normalTmp.x + _normal2.x)*.5;
								_normal2.y = (_normalTmp.y + _normal2.y)*.5;
								_normal2.z = (_normalTmp.z + _normal2.z)*.5;
								
								if (_coverAll || uvs[uvind] == uv2.u && uvs[uvindV] == uv2.v) {
									bv2 = true;
									ind2 = ind;
									continue;
								}
							}
							
						}
					}
				}
			}
			
			if (!bv0) {
				ind0 = vertices.length/3;
				vertices.push(v0.x, v0.y, v0.z);
				uvs.push(uv0.u, uv0.v);
				if (_smoothSurface)
					normals.push(_normal0.x, _normal0.y, _normal0.z);
			}
			
			if (!bv1) {
				ind1 = vertices.length/3;
				vertices.push(v1.x, v1.y, v1.z);
				uvs.push(uv1.u, uv1.v);
				if (_smoothSurface)
					normals.push(_normal1.x, _normal1.y, _normal1.z);
			}
			
			if (!bv2) {
				ind2 = vertices.length/3;
				vertices.push(v2.x, v2.y, v2.z);
				uvs.push(uv2.u, uv2.v);
				if (_smoothSurface)
					normals.push(_normal2.x, _normal2.y, _normal2.z);
			}
			
			indices.push(ind0, ind1, ind2);
		}
		
		private function distributeVectors():Array<Array<Vector3D>>
		{
			var segs:Array<Array<Vector3D>> = _path.getPointsOnCurvePerSegment(_subdivision);
			var nSegs:Array<Array<Vector3D>> = new Array<Array<Vector3D>>();
			
			var seg:Array<Vector3D>;
			var j:UInt;
			var estLength:Float = 0;
			var vCount:UInt;
			
			var v:Vector3D;
			var tmpV:Vector3D = new Vector3D();
			var prevV:Vector3D;
			
			// For loop conversion - 						for (var i:UInt = 0; i < segs.length; ++i)
			
			var i:UInt = 0;
			
			for (i in 0...segs.length) {
				seg = segs[i];
				// For loop conversion - 				for (j = 0; j < _subdivision; ++j)
				for (j in 0..._subdivision) {
					if (prevV)
						estLength += Vector3D.distance(prevV, seg[j]);
					prevV = seg[j];
					vCount++;
				}
			}
			var step:Float = estLength/vCount;
			var tPrecision:Float = 0.001;
			var t:Float = 0;
			var ps:IPathSegment;
			
			var tmpVDist:Float = 0;
			var diff:Float = 0;
			var ignore:Bool;
			
			// For loop conversion - 						for (i = 0; i < segs.length; ++i)
			
			for (i in 0...segs.length) {
				ps = _path.getSegmentAt(i);
				ignore = false;
				t = diff;
				seg = new Array<Vector3D>();
				
				while (t < 1) {
					
					if (segs.length == 0) {
						v = segs[i][0];
						seg.push(v);
						prevV = v;
						continue;
					}
					
					tmpVDist = 0;
					while (tmpVDist < step) {
						t += tPrecision;
						if (t > 1 && i < segs.length - 1) {
							ignore = true;
							break;
						} else {
							tmpV = ps.getPointOnSegment(t, tmpV);
							tmpVDist = Vector3D.distance(prevV, tmpV);
						}
					}
					
					diff = 1 - t;
					if (!ignore) {
						v = new Vector3D(tmpV.x, tmpV.y, tmpV.z);
						prevV = v;
						seg.push(v);
					}
				}
				
				nSegs.push(seg);
			}
			
			segs = null;
			
			return nSegs;
		}
		
		private function generateUlist():Void
		{
			_distributedU = Array<Float>([0]);
			var tdist:Float = 0;
			var dist:Float = 0;
			var tmpDists:Array<Float> = new Array<Float>();
			// For loop conversion - 			for (var i:UInt = 0; i < _profile.length - 1; ++i)
			var i:UInt = 0;
			for (i in 0..._profile.length - 1) {
				tmpDists[i] = Vector3D.distance(_profile[i], _profile[i + 1]);
				tdist += tmpDists[i];
			}
			// For loop conversion - 			for (i = 1; i < _profile.length; ++i)
			for (i in 1..._profile.length) {
				_distributedU[i] = (tmpDists[i - 1] + dist)/tdist;
				dist += tmpDists[i - 1];
			}
			
			tmpDists = null;
		}
		
		private function buildExtrude():Void
		{
			if (_path == null || _path.numSegments == 0 || _profile == null || _profile.length < 2)
				throw new Error("PathExtrude error: invalid Path or profile with unsufficient data");
			
			_geomDirty = false;
			initHolders();
			
			_maxIndProfile = _profile.length*9;
			
			var vSegPts:Array<Array<Vector3D>>;
			
			if (_distribute)
				vSegPts = distributeVectors();
			else
				vSegPts = _path.getPointsOnCurvePerSegment(_subdivision);
			
			if (_distributeU)
				generateUlist();
			
			var vPtsList:Array<Vector3D> = new Array<Vector3D>();
			var vSegResults:Array<Array<Vector3D>> = new Array<Array<Vector3D>>();
			var atmp:Array<Vector3D>;
			var tmppt:Vector3D = new Vector3D(0, 0, 0);
			
			var i:UInt = 0;
			var j:UInt;
			var k:UInt;
			
			var nextpt:Vector3D;
			if (_coverSegment)
				_segv = 1/(_subdivision - 1);
			
			var lastP:Array<Vector3D>
			if (_closePath)
				lastP = new Array<Vector3D>();
			
			var rescale:Bool = (_scales != null);
			var lastscale:Vector3D;
			if (rescale)
				lastscale = (_scales[0] == null)? new Vector3D(1, 1, 1) : _scales[0];
			
			var rotate:Bool = (_rotations != null);
			
			if (rotate && _rotations.length > 0) {
				var lastrotate:Vector3D = _rotations[0];
				var nextrotate:Vector3D;
				var rotation:Array<Vector3D> = new Array<Vector3D>();
				var tweenrot:Vector3D;
			}
			
			if (_smoothScale && rescale) {
				var nextscale:Vector3D = new Vector3D(1, 1, 1);
				var vScales:Array<Vector3D> = Array<Vector3D>([lastscale]);
				if (_scales.length != _path.numSegments + 2) {
					var lastScl:Vector3D = _scales[_scales.length - 1];
					while (_scales.length != _path.numSegments + 2)
						_scales.push(lastScl);
				}
			}
			
			var tmploop:UInt = _profile.length;
			// For loop conversion - 			for (i = 0; i < vSegPts.length; ++i)
			for (i in 0...vSegPts.length) {
				if (rotate) {
					lastrotate = (_rotations[i] == null)? lastrotate : _rotations[i];
					nextrotate = (_rotations[i + 1] == null)? lastrotate : _rotations[i + 1];
					rotation = Array<Vector3D>([lastrotate]);
					rotation = rotation.concat(Vector3DUtils.subdivide(lastrotate, nextrotate, _subdivision));
				}
				
				if (rescale)
					lastscale = (!_scales[i])? lastscale : _scales[i];
				
				if (_smoothScale && rescale) {
					nextscale = (!_scales[i + 1])? (!_scales[i])? lastscale : _scales[i] : _scales[i + 1];
					vScales = vScales.concat(Vector3DUtils.subdivide(lastscale, nextscale, _subdivision));
				}
				
				// For loop conversion - 								for (j = 0; j < vSegPts[i].length; ++j)
				
				for (j in 0...vSegPts[i].length) {
					
					atmp = new Array<Vector3D>();
					atmp = atmp.concat(_profile);
					vPtsList = new Array<Vector3D>();
					
					if (rotate)
						tweenrot = rotation[j];
					
					if (_alignToPath) {
						_trans = new Matrix3D();
						if (i == vSegPts.length - 1 && j == vSegPts[i].length - 1) {
							
							if (_closePath) {
								nextpt = vSegPts[0][0];
								orientateAt(nextpt, vSegPts[i][j]);
							} else {
								nextpt = vSegPts[i][j - 1];
								orientateAt(vSegPts[i][j], nextpt);
							}
							
						} else {
							nextpt = (j < vSegPts[i].length - 1)? vSegPts[i][j + 1] : vSegPts[i + 1][0];
							orientateAt(nextpt, vSegPts[i][j]);
						}
					}
					
					// For loop conversion - 										for (k = 0; k < tmploop; ++k)
					
					for (k in 0...tmploop) {
						
						if (rescale && !_smoothScale) {
							atmp[k].x *= lastscale.x;
							atmp[k].y *= lastscale.y;
							atmp[k].z *= lastscale.z;
						}
						
						if (_alignToPath) {
							tmppt = new Vector3D();
							
							tmppt.x = atmp[k].x*_trans.rawData[0] + atmp[k].y*_trans.rawData[4] + atmp[k].z*_trans.rawData[8] + _trans.rawData[12];
							tmppt.y = atmp[k].x*_trans.rawData[1] + atmp[k].y*_trans.rawData[5] + atmp[k].z*_trans.rawData[9] + _trans.rawData[13];
							tmppt.z = atmp[k].x*_trans.rawData[2] + atmp[k].y*_trans.rawData[6] + atmp[k].z*_trans.rawData[10] + _trans.rawData[14];
							
							if (rotate)
								tmppt = Vector3DUtils.rotatePoint(tmppt, tweenrot);
							
							tmppt.x += vSegPts[i][j].x;
							tmppt.y += vSegPts[i][j].y;
							tmppt.z += vSegPts[i][j].z;
							
						} else
							tmppt = new Vector3D(atmp[k].x + vSegPts[i][j].x, atmp[k].y + vSegPts[i][j].y, atmp[k].z + vSegPts[i][j].z);
						
						vPtsList.push(tmppt);
					}
					
					if (_closePath && i == vSegPts.length - 1 && j == vSegPts[i].length - 1)
						break;
					
					if (_closePath)
						lastP = vPtsList;
					
					vSegResults.push(vPtsList);
					
				}
			}
			
			if (rescale && _smoothScale) {
				// For loop conversion - 				for (i = 0; i < vScales.length; ++i)
				for (i in 0...vScales.length) {
					// For loop conversion - 					for (j = 0; j < vSegResults[i].length; ++j)
					for (j in 0...vSegResults[i].length) {
						vSegResults[i][j].x *= vScales[i].x;
						vSegResults[i][j].y *= vScales[i].y;
						vSegResults[i][j].z *= vScales[i].z;
					}
				}
				vScales = null;
			}
			
			if (rotate)
				rotation = null;
			
			if (_closePath) {
				var stepx:Float;
				var stepy:Float;
				var stepz:Float;
				var c:Array<Vector3D>;
				var c2:Array<Array<Vector3D>> = new Array<Array<Vector3D>>();
				
				// For loop conversion - 								for (i = 1; i < _subdivision + 1; ++i)
				
				for (i in 1..._subdivision + 1) {
					c = new Array<Vector3D>();
					// For loop conversion - 					for (j = 0; j < lastP.length; ++j)
					for (j in 0...lastP.length) {
						stepx = (vSegResults[0][j].x - lastP[j].x)/_subdivision;
						stepy = (vSegResults[0][j].y - lastP[j].y)/_subdivision;
						stepz = (vSegResults[0][j].z - lastP[j].z)/_subdivision;
						c.push(new Vector3D(lastP[j].x + (stepx*i), lastP[j].y + (stepy*i), lastP[j].z + (stepz*i)));
					}
					c2.push(c);
				}
				
				c2[0] = lastP;
				generate(c2, (_coverAll)? vSegResults.length : 0, _coverAll);
				c = null;
				c2 = null;
			}
			
			if (_keepExtremes) {
				_startPoints = new Array<Vector3D>();
				_endPoints = new Array<Vector3D>();
				var offsetEnd:UInt = vSegResults.length - 1;
				
				// For loop conversion - 								for (i = 0; i < tmploop; ++i)
				
				for (i in 0...tmploop) {
					_startPoints[i] = vSegResults[0][i];
					_endPoints[i] = vSegResults[offsetEnd][i];
				}
				
			} else if (_startPoints) {
				
				// For loop conversion - 								for (i = 0; i < tmploop; ++i)
				
				for (i in 0...tmploop)
					_startPoints[i] = _endPoints[i] = null;
				_startPoints = _endPoints = null;
			}
			
			generate(vSegResults, (_closePath && _coverAll)? 1 : 0, (_closePath && !_coverAll));
			
			vSegPts = null;
			_varr = null;
			
			if (_MaterialsSubGeometries && _MaterialsSubGeometries.length > 0) {
				var sglist:SubGeometryList;
				var sg:SubGeometry;
				// For loop conversion - 				for (i = 0; i < _MaterialsSubGeometries.length; ++i)
				for (i in 0..._MaterialsSubGeometries.length) {
					sglist = _MaterialsSubGeometries[i];
					sg = sglist.subGeometry;
					if (sg && sglist.vertices.length > 0) {
						this.geometry.addSubGeometry(sg);
						this.subMeshes[this.subMeshes.length - 1].material = sglist.material;
						sg.updateVertexData(sglist.vertices);
						sg.updateIndexData(sglist.indices);
						sg.updateUVData(sglist.uvs);
						
						if (_smoothSurface)
							sg.updateVertexNormalData(sglist.normals);
					}
				}
				
			} else {
				
				_subGeometry.updateVertexData(_vertices);
				_subGeometry.updateIndexData(_indices);
				_subGeometry.updateUVData(_uvs);
				
				if (_smoothSurface)
					_subGeometry.updateVertexNormalData(_normals);
				
				this.geometry.addSubGeometry(_subGeometry);
			}
			
			if (_centerMesh)
				MeshHelper.recenter(this);
		}
	}
}

import away3d.core.base.SubGeometry;
import away3d.materials.MaterialBase;

class SubGeometryList
{
	public var uvs:Array<Float>;
	public var vertices:Array<Float>;
	public var normals:Array<Float>;
	public var indices:Array<UInt>;
	public var subGeometry:SubGeometry;
	public var material:MaterialBase;

