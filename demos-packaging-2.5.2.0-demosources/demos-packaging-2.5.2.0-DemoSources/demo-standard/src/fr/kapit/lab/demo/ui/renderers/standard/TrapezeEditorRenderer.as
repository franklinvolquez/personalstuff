package fr.kapit.lab.demo.ui.renderers.standard
{
	import flash.display.Graphics;
	
	import fr.kapit.diagrammer.renderers.DefaultEditorRenderer;
	
	public class TrapezeEditorRenderer extends AbstractEditorRenderer
	{
		public function TrapezeEditorRenderer()
		{
			super();
			_itemWidth = 50;
			_itemHeight = 50;
			backgroundColors=[0xFDFDFD, 0xE9E9E9];
		}
		
		override protected function drawShape(w:Number, h:Number, roundRadius:Number, g:Graphics=null):void
		{
			graphics.lineStyle(getThickness(),getColor(),_borderAlpha,false,'none');
			var cmd:Vector.<int> = new Vector.<int>();
			var path:Vector.<Number> = new Vector.<Number>();
			path.push(w/6, 0,
				w*5/6, 0,
				w, h,
				0, h,
				w/6, 0);
			
			cmd.push(1,2,2,2,2);
			graphics.drawPath(cmd,path);
		}
	}
}