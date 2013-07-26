package fr.kapit.lab.demo.model
{
import flash.events.Event;
import flash.events.EventDispatcher;

import fr.kapit.actionscript.system.IDisposable;
import fr.kapit.lab.demo.ui.views.MainView;
import fr.kapit.visualizer.Visualizer;

/**
 * Dispatched when a visualizer component is registered to
 * the application model.
 */
[Event(name="datavizComponentAssigned", type="flash.events.Event")]


[Bindable]
/**
 * Application model (seems obvious).
 */
public class ApplicationModel extends EventDispatcher implements IDisposable
{
	public var searchTag:String;
	
	public var searchMessage:String;
	
	public var twitterCallState:String;
	
	protected var _isEmptySearch:Boolean = false;
	public function set isEmptySearch(value:Boolean):void
	{
		_isEmptySearch = value;
		if(value)
		{
			mainView.currentState = "noresult";
			searchMessage = "Your Search \"" + searchTag + "\" did not match any tweets"
		}
		else
		{
			mainView.currentState = "normal";
		}
	}
	
	
	/**
	 * Abstraction to control the visualizer instance.
	 * An instance is created when a visualizer component is registered
	 * to the application model.
	 *
	 * @see #visualizer
	 */
	protected var _visualizerModel:VisualizerModel = null;
	/**
	 * Diagrammer wrapper.
	 */
	[Bindable(event="visualizerModelUpdated")]
	public function get visualizerModel():VisualizerModel
	{
		return _visualizerModel;
	}
	/**
	 * Diagrammer component.
	 * Should be Initialized as the application starts.
	 */
	public function get visualizer():Visualizer
	{
		if (null == _visualizerModel)
			return null;
		return _visualizerModel.visualizer;
	}

	/**
	 * @private
	 */
	public function set visualizer(value:Visualizer):void
	{
		if (value == visualizer)
			return;
		
		if (null != visualizerModel)
		{
			_visualizerModel.dispose(false);
			_visualizerModel = null;
		}
		if (null != value)
		{
			_visualizerModel = new VisualizerModel(value);
			dispatchEvent(new Event("visualizerModelUpdated"));
		}
		
		dispatchEvent(new Event("datavizComponentAssigned"));
	}
	
	protected var _mainView:MainView;
	public function get mainView():MainView
	{
		return _mainView;
	}
	public function set mainView(value:MainView):void
	{
		_mainView = value;
	}
	/**
	 * Constructor.
	 */
	public function ApplicationModel()
	{
	}


	/**
	 * Explicit references clean up.
	 * The current instance may not be considered usable there after, so
	 * one should call the <code>dispose()</code> method before an
	 * object gets "destroyed".
	 * <p>
	 * The <code>recursive</code> parameter is intended to be used
	 * on composite classes : for example, a collection may try to apply
	 * <code>dispose()</code> on each of its elements.
	 * </p>
	 *
	 * @see http://en.wikipedia.org/wiki/Dispose
	 *
	 * @param recursive
	 * 		if set to <code>true</code> then the clean up is recusively done.
	 */
	public function dispose(recursive:Boolean=false):void
	{
		if (null != _visualizerModel)
		{
			_visualizerModel.dispose(recursive);
			_visualizerModel = null;
		}
	}


}
}