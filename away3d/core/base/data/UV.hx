package away3d.core.base.data;

	
	/**
	 * Texture coordinates value object.
	 */
	class UV
	{
		var _u:Float;
		var _v:Float;
		
		/**
		 * Creates a new <code>UV</code> object.
		 *
		 * @param    u        [optional]    The horizontal coordinate of the texture value. Defaults to 0.
		 * @param    v        [optional]    The vertical coordinate of the texture value. Defaults to 0.
		 */
		public function new(u:Float = 0, v:Float = 0)
		{
			_u = u;
			_v = v;
		}
		
		/**
		 * Defines the vertical coordinate of the texture value.
		 */
		public var v(get, set) : Float;
		public function get_v() : Float
		{
			return _v;
		}
		
		public function set_v(value:Float) : Float
		{
			_v = value;
		}
		
		/**
		 * Defines the horizontal coordinate of the texture value.
		 */
		public var u(get, set) : Float;
		public function get_u() : Float
		{
			return _u;
		}
		
		public function set_u(value:Float) : Float
		{
			_u = value;
		}
		
		/**
		 * returns a new UV value Object
		 */
		public function clone():UV
		{
			return new UV(_u, _v);
		}
		
		/**
		 * returns the value object as a string for trace/debug purpose
		 */
		public function toString():String
		{
			return _u + "," + _v;
		}
	
	}

