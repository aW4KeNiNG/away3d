/**
 * A particle animation node used to apply a constant acceleration vector to the motion of a particle.
 */
package away3d.animators.nodes;

import openfl.errors.Error;
import away3d.animators.data.ParticleProperties;
import away3d.animators.data.ParticlePropertiesMode;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.materials.passes.MaterialPassBase;
import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.states.ParticleAccelerationState;
import openfl.geom.Vector3D;

class ParticleAccelerationNode extends ParticleNodeBase {

	/** @private */
	static public var ACCELERATION_INDEX:Int = 0;

	/** @private */
	public var _acceleration:Vector3D;

	/**
	 * Reference for acceleration node properties on a single particle (when in local property mode).
	 * Expects a <code>Vector3D</code> object representing the direction of acceleration on the particle.
	 */
	static public var ACCELERATION_VECTOR3D:String = "AccelerationVector3D";

	/**
	 * Creates a new <code>ParticleAccelerationNode</code>
	 *
	 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
	 * @param    [optional] acceleration    Defines the default acceleration vector of the node, used when in global mode.
	 */
	public function new(mode:Int, acceleration:Vector3D = null) {
		super("ParticleAcceleration", mode, 3);
		_stateClass = ParticleAccelerationState;
		_acceleration = acceleration ;
		if (_acceleration == null)_acceleration = new Vector3D();
	}

	/**
	 * @inheritDoc
	 */
	override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String {

		var accelerationValue:ShaderRegisterElement = ((_mode == ParticlePropertiesMode.GLOBAL)) ? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
		animationRegisterCache.setRegisterIndex(this, ACCELERATION_INDEX, accelerationValue.index);
		var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
		animationRegisterCache.addVertexTempUsages(temp, 1);
		var code:String = "mul " + temp + "," + animationRegisterCache.vertexTime + "," + accelerationValue + "\n";
		if (animationRegisterCache.needVelocity) {
			var temp2:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			code += "mul " + temp2 + "," + temp + "," + animationRegisterCache.vertexTwoConst + "\n";
			code += "add " + animationRegisterCache.velocityTarget + ".xyz," + temp2 + ".xyz," + animationRegisterCache.velocityTarget + ".xyz\n";
		}
		animationRegisterCache.removeVertexTempUsage(temp);
		code += "mul " + temp + "," + temp + "," + animationRegisterCache.vertexTime + "\n";
		code += "add " + animationRegisterCache.positionTarget + ".xyz," + temp + "," + animationRegisterCache.positionTarget + ".xyz\n";
		return code;
	}

	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):ParticleAccelerationState {
		return cast(animator.getAnimationState(this), ParticleAccelerationState) ;
	}

	/**
	 * @inheritDoc
	 */
	override public function generatePropertyOfOneParticle(param:ParticleProperties):Void {
		var tempAcceleration:Vector3D = param.nodes.get(ACCELERATION_VECTOR3D);
		if (tempAcceleration == null) throw new Error("there is no " + ACCELERATION_VECTOR3D + " in param!");
		_oneData[0] = tempAcceleration.x / 2;
		_oneData[1] = tempAcceleration.y / 2;
		_oneData[2] = tempAcceleration.z / 2;
	}
}

