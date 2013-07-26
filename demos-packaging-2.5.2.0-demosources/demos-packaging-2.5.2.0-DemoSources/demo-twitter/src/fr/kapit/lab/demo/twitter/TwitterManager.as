package fr.kapit.lab.demo.twitter
{
	import com.swfjunkie.tweetr.Tweetr;
	import com.swfjunkie.tweetr.data.objects.SearchResultData;
	import com.swfjunkie.tweetr.data.objects.TrendData;
	import com.swfjunkie.tweetr.events.TweetEvent;
	
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import fr.kapit.lab.demo.ui.views.MainView;
	
	import mx.controls.Alert;
	
	public class TwitterManager
	{
		/**
		 * The number of tweets to be received per request.
		 */
		private static const TWEETS_PER_REQUEST:int = 10;
		
		/**
		 * The number of nodes after which no requests are sent in order to limit the size of the graph.
		 */
		private static const NODES_LIMIT:int = 100;

		/**
		 * The time between two successive search requests.
		 */
		private static const TIME:int = 5000;
		
		/**
		 * The application main view. 
		 */
		private var _mainView:MainView;
		
		/**
		 * Used to communicate with the Twitter API.
		 */
		private var _twitter:Tweetr;
		
		/**
		 * A list that contains the list of the tags in the graph.
		 */
		private var _tags:Array;
		
		/**
		 * A list that contains the tags for which to send the following search requests.
		 */
		private var _requestQueue:Array;
		
		/**
		 * The tag that is currently processed.
		 */
		private var _currentTag:String;
		
		private var _isFirstSearch:Boolean;
		private var _searchTag:String;

		/**
		 * A timer used to periodically send search requests.
		 */
		private var _timer:Timer;
		
		
		/**
		 * Constructor.
		 */
		public function TwitterManager()
		{
			_twitter = new Tweetr();
			
			_requestQueue = [];
			_tags = [];
			
			_twitter.addEventListener(TweetEvent.FAILED, onFault);
		}

		/**
		 * Sends a request to receive the trending topics.
		 */
		public function getTrends():void
		{
			_twitter.removeEventListener(TweetEvent.COMPLETE, handleTagSearch);
			_twitter.addEventListener(TweetEvent.COMPLETE, handleTrends);
			_twitter.trends();
		}
		
		/**
		 * Searchs for tweets and tags related to the given tag and adds displays them in a graph.
		 * 
		 * @param tag the tag to be used in the search
		 * @param exclude a space separated list of words to be excluded from the search.
		 */
		public function search(tag:String, exclude:String = null):void
		{
			_twitter.removeEventListener(TweetEvent.COMPLETE, handleTrends);
			_twitter.addEventListener(TweetEvent.COMPLETE, handleTagSearch);
			
			_isFirstSearch = true;
			_searchTag = tag;
			
			mainView.menubar.limitReached = false;
			
			reset();
			addTag(formatTag(tag));
			continueSearch();
		}
		public function setTimerOnStandBy():void
		{
			if (_timer)
				_timer.stop();
		}
		/**
		 * Pauses the search.
		 */
		public function pause():void
		{
			setTimerOnStandBy();
			mainView.appModel.twitterCallState = "idle";
			_twitter.removeEventListener(TweetEvent.COMPLETE, handleTagSearch);
		}
		
		/**
		 * Resumes the search after it has been paused.
		 */
		public function resume():void
		{
			_twitter.addEventListener(TweetEvent.COMPLETE, handleTagSearch);
			startTimer();
		}
		
		/**
		 * Restarts the search.
		 */
		public function restart():void
		{
			setTimerOnStandBy();
			search(_searchTag);
		}
		
		/**
		 * Adds the tag to <code>_tags</code> array.
		 */
		private function addTag(tag:String):void
		{
			if (_tags)
				_tags.push(tag)
			else
				_tags = [tag];
		}
		
		/**
		 * Transforms the tag to lower case and removes the "#" charcter.
		 * 
		 * @return the formatted tag.
		 */
		private function formatTag(tag:String):String
		{
			if (!tag || tag.length == 0)
				return null;
			
			if (tag.charAt(0) == "#")
				tag = tag.slice(1);
			
			return tag.toLowerCase();
		}
		
		/**
		 * Starts a search with the top tending topic.
		 */
		private function handleTrends(event:TweetEvent):void
		{
			if (event.responseArray.length == 0)
				return;
			
			mainView.appModel.twitterCallState = "loaded";
			
			var trend:TrendData = event.responseArray[0];
			
			search(trend.name);
		}
		
		/**
		 * Adds the received tweets to the graph and parses their text to
		 * extract the the corresponding tags.
		 */
		private function handleTagSearch(event:TweetEvent):void
		{
			mainView.appModel.twitterCallState = "loaded";
			
			if(_isFirstSearch)
			{
				_isFirstSearch = false;
				mainView.appModel.isEmptySearch = ( event.responseArray.length==0);
			}
			var tags:Array;
			var array:Array;
			var tag:String;
			var t:String;
			
			for each(var tweet:SearchResultData in event.responseArray)
			{
				array = tweet.text.match(/#\w+/g);
				tags = [];
				
				for each(tag in array)
				{
					t = formatTag(tag);
					if (t && t.length>0)
						tags.push(t);
				}
				
				for each(tag in tags)
				{
					if (_tags.indexOf(tag) == -1)
						addTag(tag);
				}
				
				if (tags.indexOf(_currentTag) == -1)
					tags.push(_currentTag);
				
				_mainView.addTweet(tweet, tags);
			}
			
			startTimer();
		}
		
		/**
		 * Is used to go back to the initial state.
		 */
		private function reset():void
		{
			setTimerOnStandBy();
			_mainView.visualizer.removeAll();
			_tags = null;
			_requestQueue= null;
		}
		
		/**
		 * Starts a timer that will be used to periodically send a search request.
		 */
		private function startTimer():void
		{
			if (!_timer)
			{
				_timer = new Timer(TIME);
				_timer.addEventListener(TimerEvent.TIMER, handleTimer);
			}
			_timer.start();
			
			mainView.appModel.twitterCallState = "loading";
		}
		
		/**
		 * Sends a search request and stops the timer that will be restarted when the search response is received.
		 */
		private function handleTimer(event:TimerEvent):void
		{
			setTimerOnStandBy();
			continueSearch();
		}
		
		/**
		 * Sends a search request if the number of nodes in the graph is lower
		 * than <code>NODES_LIMIT</code> and stops the timer otherwise.
		 */
		private function continueSearch():void
		{
			if (_mainView && _mainView.visualizer && _mainView.visualizer.graph &&
				_mainView.visualizer.graph.nodes && _mainView.visualizer.graph.nodes.length > NODES_LIMIT)
			{
				if (_timer)
					_timer.stop();
				mainView.menubar.limitReached = true;
				mainView.appModel.twitterCallState = "idle";
				return;
			}
			
			if (!_requestQueue || _requestQueue.length==0)
				_requestQueue = _tags.concat();
			_currentTag = _requestQueue.shift();
			if (_currentTag)
				_twitter.search(_currentTag, null, TWEETS_PER_REQUEST);
		}
		
		private function onFault(event:TweetEvent):void
		{
			if (event.info != "200")
			{
				//Alert.show(event.info);
				search("twitter");
			}
		}
		
		/**
		 * The main view where the graph is displayed.
		 */
		public function get mainView():MainView
		{
			return _mainView;
		}
		
		public function set mainView(value:MainView):void
		{
			_mainView = value;
		}
		
	}
}