package dragonBones.display
{
	import dragonBones.objects.Node;
	
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	
	/**
	 * A display bridge for Starling engine
	 *
	 */
	public class StarlingDisplayBridge implements IDisplayBridge
	{
		protected var _display:DisplayObject;
		
		/**
		 * @inheritDoc
		 */
		public function get display():Object
		{
			return _display;
		}
		
		public function set display(value:Object):void
		{
			if(_display == value){
				return;
			}
			if(_display)
			{
				var parent:DisplayObjectContainer = _display.parent;
				if(parent)
				{
					var index:int = _display.parent.getChildIndex(_display);
				}
				removeDisplay();
			}
			_display = value as DisplayObject;
			addDisplay(parent, index);
		}
		/**
		 * Creates a new <code>StarlingDisplayBridge</code> object
		 */
		public function StarlingDisplayBridge()
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public function update(matrix:Matrix, node:Node, colorTransform:ColorTransform):void
		{
			var pivotX:Number = node.pivotX + _display.pivotX;
			var pivotY:Number = node.pivotY + _display.pivotY;
			matrix.tx -= matrix.a * pivotX + matrix.c * pivotY;
			matrix.ty -= matrix.b * pivotX + matrix.d * pivotY;
			
			//if(updateStarlingDisplay)
			//{
				//_display.transformationMatrix = matrix;
			//}
			//else
			//{
				_display.transformationMatrix.copyFrom(matrix);
			//}
		}
		
		/**
		 * @inheritDoc
		 */
		public function addDisplay(container:Object, index:int = -1):void
		{
			if(container && _display)
			{
				if(index < 0)
				{
					container.addChild(_display);
				}
				else
				{
					container.addChildAt(_display, Math.min(index, container.numChildren));
				}
			}
		}
		/**
		 * @inheritDoc
		 */
		public function removeDisplay():void
		{
			if(_display && _display.parent)
			{
				_display.parent.removeChild(_display);
			}
		}
	}
}