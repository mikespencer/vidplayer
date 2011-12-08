package VidPlayer {
	
	//import required classes
	import com.greensock.*;
	import VidPlayer.VidPlayerEvent;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.display.Loader;
	import flash.display.Graphics;
	import flash.display.GradientType;
	import flash.display.SpreadMethod;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.events.NetStatusEvent;
	import flash.events.MouseEvent;	
	import flash.geom.Matrix;
	import flash.media.Video;
	import flash.media.SoundTransform;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import flash.display.LoaderInfo;
	import flash.external.ExternalInterface;
    import flash.display.StageScaleMode;
	import flash.display.StageAlign;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;
	import flash.net.navigateToURL;
	
	
	public class VidPlayer extends MovieClip{

		//declare class variables		
		private var data = {
			//these are the default options for the video player
			width : 320,
			height : 240,
			buffer_time : 8,
			source : null,
			autoplay : true,
			mute : true,
			controlsBorderFill : 0xFFFFFF,
			buttonsBGFill : 0x000000,
			buttonsFill : 0xFFFFFF,
			progressFill :  [ 0x6699CC, 0x306496 ],
			progressBGFill:  [ 0xDDDDDD, 0x666666 ],
			poster : false,
			controls_alpha : 0.7,
			pause_alpha : 0.7,
			play_alpha : 0.7,
			x : 0,
			y : 0,
			useFlashVars : true,
			standAlone : false,
			track_play : false,
			track_pause : false,
			track_end : false,
			preload : true,
			pauseAt : false,
			clickTag : false,
			jsTrackFunction : false,
			trackingPixel : false,
			letterBox : false
		};
		private var isBuffering:Boolean = false;
		private var isStopped:Boolean = true;
		private var lastVolume:Number = 1;
		private var wrapper:MovieClip = new MovieClip();
		private var controls_mc:MovieClip = new MovieClip();
		private var btnMute:MovieClip = new MovieClip();
		private var btnUnmute:MovieClip = new MovieClip();
		private var posterImage:Loader;
		private var bigPlay:Sprite = new Sprite();
		private var bigPause:Sprite = new Sprite();
		private var poster:MovieClip = new MovieClip();		
		private var btnPlay:MovieClip = new MovieClip();
		private var btnPause:MovieClip = new MovieClip();
		private var controls_mask:Shape = new Shape();
		private var trackBG:Sprite = new Sprite();
		private var mcProgressBG:MovieClip = new MovieClip();		
		private var mcProgressFill:MovieClip = new MovieClip();
		private var message_mc:MovieClip = new MovieClip();		
		private var interacted:Boolean = false;
		private var tmrDisplay:Timer;	
		private var vidDisplay:Video;
		private var ncConnection:NetConnection;
		private var nsStream:NetStream;
		private var meta = null;
		private var pauseAt:uint;
		private var isMessage:Boolean = false;
		private var playEvt:VidPlayerEvent = new VidPlayerEvent('play');
		private var pauseEvt:VidPlayerEvent = new VidPlayerEvent('pause');
		private var stopEvt:VidPlayerEvent = new VidPlayerEvent('stop');
		private var scrubEvt:VidPlayerEvent = new VidPlayerEvent('scrub');
		private var muteEvt:VidPlayerEvent = new VidPlayerEvent('mute');
		private var unmuteEvt:VidPlayerEvent = new VidPlayerEvent('unmute');
		private var vidPlayerEvents = {
			"play" : {
				"type" : VidPlayerEvent.PLAY,
				"fncache" : []
			},
			"pause" : {
				"type" : VidPlayerEvent.PAUSE,
				"fncache" : []
			},
			"stop" : {
				"type" : VidPlayerEvent.STOP,
				"fncache" : []
			},
			"mute" : {
				"type" : VidPlayerEvent.MUTE,
				"fncache" : []
			},
			"unmute" : {
				"type" : VidPlayerEvent.UNMUTE,
				"fncache" : []
			},
			"scrub" : {
				"type" : VidPlayerEvent.SCRUB,
				"fncache" : []
			}
		};
		
		//constructor
		public function VidPlayer(obj:Object = null) {
			for(var key in obj){
				if(typeof data[key] != 'undefined' && obj.hasOwnProperty(key) && data.hasOwnProperty(key)){
					 //overwrite defaults
					data[key] = obj[key];
				}
			}
			this.addEventListener( Event.ADDED_TO_STAGE, addedToStage );
		}
		
		private function addedToStage( e:Event ){
			this.removeEventListener( Event.ADDED_TO_STAGE, addedToStage );
			var paramObj = LoaderInfo(root.loaderInfo).parameters;
			if(data.useFlashVars && paramObj){
				for (var param in paramObj){
					 //overwrite defaults with flashVars
					if(typeof data[param] != 'undefined' && data.hasOwnProperty(param) && paramObj.hasOwnProperty(param)){
						data[param] = paramObj[param];
					}
				}
			}
			if(data.source){
				if(data.standAlone && data.standAlone != 'false'){
					isStandAlonePlayer();
				}
				else{
					init();
				}
			}
			else{
				trace("A \"source\" property is required for VidPlayer. This can still be passed in via flashVars.");
			}
		}
		
		private function init(){		
			this.addChild(wrapper);
			create_timer();
			create_ncConnection();
			create_nsStream();
			create_vidDisplay();
			if(data.poster){
				create_poster();
			}
			create_btnPlay();
			create_btnPause();			
			create_controls_mc();
			exec();
		}
		
		private function exec(){
			if( !!data.preload && data.preload !== 'false' && !data.preloadLoaded ){
				nsStream.play(data.source);
				nsStream.pause();
				nsStream.seek(0);
			}

			lastVolume = data.mute && data.mute != 'false' ? 0 : 1;
			setVolume(lastVolume)
			this.x = data.x;
			this.y = data.y;
			if(data.autoplay && data.autoplay != 'false'){
				playClicked();
				if(!!data.pauseAt && data.pauseAt != 'false' && !interacted){
					var t = parseInt(data.pauseAt) is Number ? parseInt(data.pauseAt) * 1000 : 30000
					pauseAt = setTimeout(pauseClicked, t);
				}
			}
			hide_btnPause();
		}
		
		private function stageResize(e = null){ //This function solves the problem of stageHeight/Width being 0 in IE when swf is dynamically added.
			if(e!==null){ stage.removeEventListener( Event.RESIZE, stageResize); }
			
			data.height = stage.stageHeight;
			data.width = stage.stageWidth;
			data.x = data.y = 0;
			
			if(data.height > 0 && data.width > 0){
				init();
			}
			else{
				stage.addEventListener( Event.RESIZE, stageResize);
			}
		}
		
		private function isStandAlonePlayer(){
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stageResize();
		}
		
		private function create_ncConnection(){
			ncConnection = new NetConnection();
			ncConnection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			ncConnection.connect(null);
		}
		
		private function create_nsStream(){
			nsStream=new NetStream(ncConnection);
			nsStream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			nsStream.client= {onMetaData : metaHandler};
			nsStream.bufferTime=0;
		}
		
		private function play_pause_bg(radius:Number = 24):Sprite{
			var circle:Sprite = new Sprite();
			circle.graphics.lineStyle(3,data.buttonsFill);
			circle.graphics.beginFill(data.buttonsBGFill);
			circle.graphics.drawCircle(radius,radius,radius);
			circle.graphics.endFill();
			return circle;
		}
		
		private function create_btnPlay(radius:Number = 24){
			wrapper.addChild(btnPlay);
			btnPlay.x=btnPlay.y=0;
			btnPlay.alpha = data.play_alpha;
			btnPlay.buttonMode=true;
			btnPlay.useHandCursor=true;
			
			btnPlay.addChild(bigPlay);
			bigPlay.x=bigPlay.y=0;
			bigPlay.graphics.lineStyle();
			bigPlay.graphics.beginFill(0xFFFFFF,0);
			bigPlay.graphics.drawRect(0,0,data.width,data.height);
			bigPlay.graphics.endFill();
			
			var play_symbol:MovieClip = new MovieClip();
			
			btnPlay.addChild(play_symbol)
			play_symbol.addChild(play_pause_bg(radius));
			
			var triangleHeight:uint = radius;
			var triangle:Sprite = new Sprite();
			var startX = radius/1.45;
			var startY= radius-triangleHeight/2;
			triangle.graphics.beginFill(data.buttonsFill);
			triangle.graphics.moveTo(startX, startY);
			triangle.graphics.lineTo(startX, startY);
			triangle.graphics.lineTo(startX + triangleHeight/1.2,startY + triangleHeight/2);
			triangle.graphics.lineTo(startX, startY + triangleHeight);
			triangle.graphics.endFill();
			
			play_symbol.addChild(triangle);
			center(play_symbol,23/2);
			/*var play_symbol:Loader = new Loader();
			play_symbol.load(new URLRequest(data.play_button_source));
			btnPlay.addChild(play_symbol);
			play_symbol.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e){									   
				center(play_symbol,23/2);
			})*/
			if(data.clickTag && data.clickTag != 'false'){
				play_symbol.addEventListener(MouseEvent.CLICK, playClicked);
				bigPlay.addEventListener(MouseEvent.CLICK, function(e){changePage(data.clickTag)});
			} else{
				btnPlay.addEventListener(MouseEvent.CLICK, playClicked);
			}
		}
				
		private function create_btnPause(radius:Number = 24){
			wrapper.addChild(btnPause);
			btnPause.x=0;
			btnPause.y=0;
			btnPause.alpha = data.pause_alpha;
			btnPause.buttonMode=true;
			btnPause.useHandCursor=true;
			
			btnPause.addChild(bigPause);
			bigPause.x=bigPause.y=0;
			bigPause.graphics.lineStyle();
			bigPause.graphics.beginFill(0xFFFFFF,0);
			bigPause.graphics.drawRect(0,0,data.width,data.height);
			bigPause.graphics.endFill();
			
			var pause_symbol:MovieClip = new MovieClip();
			btnPause.addChild(pause_symbol);
			
			var line1:Sprite = new Sprite();
			var line2:Sprite = new Sprite();
			line1.graphics.lineStyle();
			line1.graphics.beginFill(data.buttonsFill);
			line1.graphics.drawRect(radius-8,radius/2, 3,radius);
			line1.graphics.endFill();
			line2.graphics.lineStyle();
			line2.graphics.beginFill(data.buttonsFill);
			line2.graphics.drawRect(radius+5,radius/2, 3,radius);
			line2.graphics.endFill();
			
			pause_symbol.addChild(play_pause_bg(radius));
			pause_symbol.addChild(line1);
			pause_symbol.addChild(line2);
			center(pause_symbol,23/2);
			/*var pause_symbol:Loader = new Loader();
			pause_symbol.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e){									   
				center(pause_symbol,23/2);
			})
			pause_symbol.load(new URLRequest(data.pause_button_source));
			btnPause.addChild(pause_symbol);*/
			if(data.clickTag && data.clickTag != 'false'){
				pause_symbol.addEventListener(MouseEvent.CLICK, pauseClicked);
				bigPause.addEventListener(MouseEvent.CLICK, function(e){changePage(data.clickTag);pauseClicked(e)});
			} else{
				btnPause.addEventListener(MouseEvent.CLICK, pauseClicked);
			}
		}
		
		private function create_controls_mc(){
			wrapper.addChild(controls_mc);
			create_trackBG();
			create_mcProgressBG();
			create_mcProgressFill();
			create_horizontalLine();
			create_vertLine();
			create_btnMute();
			create_btnUnmute();
			controls_mc.x = 0;
			controls_mc.y = data.height - 23;
			controls_mc.useHandCursor = true;
			controls_mc.buttonMode = true;
			controls_mc.alpha = data.controls_alpha;
			create_controls_mask();
			if(data.autoplay && data.autoplay != 'false')controls_mc.y = data.height;
			add_controls_mc_listeners();
		}
		
		private function create_trackBG(){
			var fType:String = GradientType.LINEAR;
			var colours:Array =data.progressBGFill;
			var alphas:Array = [ 1, 1 ];
			var ratios:Array = [ 0, 255 ];
			var matr:Matrix = new Matrix();
				matr.createGradientBox( 1, 22,  (Math.PI/180)*90, 0, 0 );
			var sprMethod:String = SpreadMethod.PAD;
			var g:Graphics = trackBG.graphics;
				g.beginGradientFill( fType, colours, alphas, ratios, matr, sprMethod );
				g.drawRect( 0, 1, data.width-23, 22 );
			controls_mc.addChild( trackBG );
		}
		
		private function create_mcProgressBG(){
			var fType:String = GradientType.LINEAR;
			var colours:Array = [ 0xCCCCCC, 0x333333 ];
			var alphas:Array = [ 1, 1 ];
			var ratios:Array = [ 0, 255 ];
			var matr:Matrix = new Matrix();
				matr.createGradientBox( 1, 22,  (Math.PI/180)*90, 0, 0 );
			var sprMethod:String = SpreadMethod.PAD;
			var g:Graphics = mcProgressBG.graphics;
				g.beginGradientFill( fType, colours, alphas, ratios, matr, sprMethod );
				g.drawRect( 0, 1, 1, 22 );
			controls_mc.addChild( mcProgressBG );
		}
		
		private function create_mcProgressFill(){
			var fType:String = GradientType.LINEAR;
			var colours:Array =data.progressFill;
			var alphas:Array = [ 1, 1 ];
			var ratios:Array = [ 0, 255 ];
			var matr:Matrix = new Matrix();
				matr.createGradientBox( 1, 22,  (Math.PI/180)*90, 0, 0 );
			var sprMethod:String = SpreadMethod.PAD;
			var g:Graphics = mcProgressFill.graphics;
				g.beginGradientFill( fType, colours, alphas, ratios, matr, sprMethod );
				g.drawRect( 0, 1, 1, 22 );
			controls_mc.addChild( mcProgressFill );
		}
		
		private function create_vertLine(){
			controls_mc.addChild(drawLine( data.width-23, 1, 1, 22, data.controlsBorderFill ) );
		}
		
		private function create_horizontalLine(){
			controls_mc.addChild( drawLine( 0, 0, data.width, 1, data.controlsBorderFill ) );
		}
		
		private function drawLine(x:Number, y:Number, w:Number, h:Number, colour = false):Sprite {
			var line:Sprite = new Sprite();
			line.graphics.lineStyle();
			line.graphics.beginFill( colour is Number ? colour : data.buttonsFill );
			line.graphics.drawRect(x,y,w,h);
			line.graphics.endFill();
			return line;
		}
		private function volumeBG(alpha:Number=1):Sprite{
			var bg:Sprite = new Sprite();
			bg.graphics.lineStyle();
			bg.graphics.beginFill(data.buttonsBGFill ,alpha);
			bg.graphics.drawRect(0,0,22,22);
			bg.graphics.endFill();
			return bg;
		}
		
		private function volumeIcon():MovieClip{
			var container:MovieClip = new MovieClip();
			var bg:Sprite = new Sprite();
			
			container.addChild(volumeBG());				
			container.addChild(drawLine(5,9,3,4));
			container.addChild(drawLine(8,8,1,6));
			container.addChild(drawLine(9,7,1,8));
			container.addChild(drawLine(10,6,1,10));
			container.addChild(drawLine(11,5,1,12));
			
			container.addChild(drawLine(12,10.5,1,1));
			container.addChild(drawLine(14,8.5,1,5));
			container.addChild(drawLine(16,6.5,1,9));

			return container;
		}
		
		private function create_btnMute(){
			controls_mc.addChild(btnMute);
			btnMute.addChild(volumeIcon());
			btnMute.x = data.width-22;
			btnMute.y = 1;
		}
		
		private function create_btnUnmute(){
			var redLine:Sprite = new Sprite();

			redLine.graphics.lineStyle(2, 0xCC0000);
			redLine.graphics.moveTo(3, 19);
			redLine.graphics.lineTo(19, 3);
			redLine.graphics.endFill();
			
			controls_mc.addChild(btnUnmute);
			btnUnmute.addChild(volumeBG(0));
			btnUnmute.addChild(redLine);
			btnUnmute.x = data.width-22;
			btnUnmute.y = 1;
		}		
		
		private function create_controls_mask(){
			wrapper.addChild(controls_mask);
			controls_mask.x = controls_mc.x;
			controls_mask.y = controls_mc.y;
			controls_mask.graphics.lineStyle();
			controls_mask.graphics.beginFill(0xFFFFFF,1);
			controls_mask.graphics.drawRect(0,0,data.width,controls_mc.height);
			controls_mask.graphics.endFill();
			controls_mc.mask = controls_mask;
		}
		
		private function add_controls_mc_listeners(){
			btnMute.addEventListener(MouseEvent.CLICK, mute);
			btnUnmute.addEventListener(MouseEvent.CLICK, unMute);
		}
		
		public function displayMessage(msg:String = '', fade_speed:Number = 0.3){
			var bg:Sprite = new Sprite();
			var fmt:TextFormat = new TextFormat();
			var txt:TextField = new TextField();

			message_mc.addChild(bg);
			bg.graphics.lineStyle();
			bg.graphics.beginFill(0x000000,0.4);
			bg.graphics.drawRect(0,0,data.width,data.height);
			bg.graphics.endFill();
			
			message_mc.addChild(txt);
			txt.text = msg;
			txt.y = 10;
			txt.x =  10;
		
			txt.selectable = false;
			txt.border = false;
			txt.autoSize = TextFieldAutoSize.LEFT;
			fmt.bold = true;
			fmt.color = 0xFFFFFF; 
			fmt.font = 'Arial';
			fmt.size = 12;
			txt.setTextFormat(fmt);			
			
			message_mc.alpha = 0;
			wrapper.addChildAt(message_mc, wrapper.getChildIndex(controls_mc)-1); //add message_mc behind controls_mc

			TweenLite.to(message_mc, fade_speed, {alpha:1});
			isMessage=true;
		}
		
		public function removeMessage(fade_speed:Number = 0.3){
			TweenLite.to(message_mc, fade_speed, {alpha:0 , onComplete: function(){
				var l = message_mc.numChildren;
				while(l--){
					message_mc.removeChildAt(l);
				}
				wrapper.removeChild(message_mc);
				isMessage=false;
			}});
		}
		
		private function create_vidDisplay(){
			vidDisplay = new Video(data.width, data.height);
			vidDisplay.attachNetStream(nsStream);
			vidDisplay.smoothing=true;
			vidDisplay.visible=true;
			vidDisplay.x = vidDisplay.y = 0;
			wrapper.addChildAt(vidDisplay,0);
		}
		
		private function create_poster(){
			var bg:Sprite = new Sprite();
			bg.x = 0;
			bg.y = 0;
			bg.graphics.lineStyle();
			bg.graphics.beginFill(0x000000,1);
			bg.graphics.drawRect(0,0,data.width,data.height);
			bg.graphics.endFill();
			poster.addChild(bg);
			wrapper.addChild(poster);
			update_poster(false);
		}
		
		private function update_poster(remove_old_poster = true){
			if(remove_old_poster){
				poster.removeChild(posterImage)
			}
			posterImage = new Loader();
			posterImage.load(new URLRequest(data.poster));
			posterImage.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e){				
				center(posterImage);
			});
			poster.addChild(posterImage);
		}
		
		private function create_timer(){
			tmrDisplay=new Timer(15);
			tmrDisplay.addEventListener(TimerEvent.TIMER, updateDisplay);
		}
		
		private function setVolume(intVolume:Number = 0):void {		
			var sndTransform= new SoundTransform(intVolume);
			lastVolume=intVolume;
			nsStream.soundTransform= sndTransform;
			if (intVolume == 1) {
				// btnMute is the volume Icon
				// btnUnmute is the red line with invisible square background click area over the top of btnMute.
				// so we only have to hide btnUnmute... btnMute wants to be visible all the time
				btnUnmute.visible= false;
			} else {
				btnUnmute.visible= true;
			}
		}
		
		public function stopVideoPlayer(){
			dispatchEvent(stopEvt);
			isStopped = true;
			nsStream.pause();
			nsStream.seek(0);
			
			if(!interacted && !!data.pauseAt && data.pauseAt != 'false'){
				clearpauseAt();
			}
			
			mcProgressFill.width=1;
						
			mcProgressBG.removeEventListener(MouseEvent.MOUSE_DOWN, start_mov_seek);
			mcProgressFill.removeEventListener(MouseEvent.MOUSE_DOWN, start_mov_seek);			
			wrapper.removeEventListener(MouseEvent.MOUSE_OVER, show_controls);
			wrapper.removeEventListener(MouseEvent.MOUSE_OUT, hide_controls);		
			wrapper.removeEventListener(MouseEvent.MOUSE_OVER,show_btnPause);
			wrapper.removeEventListener(MouseEvent.MOUSE_OUT,hide_btnPause);
			tmrDisplay.removeEventListener(TimerEvent.TIMER, updateDisplay);

			vidDisplay.visible= false;
			if(data.poster)poster.visible = true;
			show_controls();
			show_btnPlay();
			hide_btnPause();
		}
		
		private function letterBox(container, target, vOffset:Number = 0){
			var ratio = Math.min(container.width / target.width, container.height / target.height);
			target.width = target.width * ratio;
			target.height = target.height * ratio;			
			if(target.height < container.height){
				target.y = (container.height/2)-(target.height/2)-vOffset; 
			} else{
				target.x = (container.width/2)-(target.width/2); 
			}
		}

		private function metaHandler(info:Object):void {
			// this function is fired twice, for some reason, so this check prevents the below executing more than once per video
			if(!meta){
				meta=info;
				if(data.letterBox && data.letterBox != 'false' && meta.hasOwnProperty('height') && meta.hasOwnProperty('width')){
					vidDisplay.width = meta['width'];
					vidDisplay.height = meta['height'];
					vidDisplay.x = data.x;
					vidDisplay.y = data.y;
					letterBox({ width : data.width, height : data.height },vidDisplay);
				}
				vidDisplay.visible=true;
				tmrDisplay.start();
			}
		}

		private function updateDisplay(e){
			mcProgressFill.width= nsStream.time*trackBG.width/meta.duration;
			mcProgressBG.width= nsStream.bytesLoaded * trackBG.width / nsStream.bytesTotal;
		}
		private function netStatusHandler(e){
			switch (e.info.code) {
				case "NetStream.Play.StreamNotFound" : 
					trace("Stream not found: " + data.source);
					tmrDisplay.removeEventListener(TimerEvent.TIMER, updateDisplay);
					stopVideoPlayer();
					displayMessage('sorry, the video could not be found.');
					hide_btnPlay();
				break;
				
				case "NetStream.Play.Stop" :
					isBuffering = false;
					tmrDisplay.removeEventListener(TimerEvent.TIMER, updateDisplay);
					stopVideoPlayer();
					try{wrapper.removeChild(message_mc)}catch(e){trace('message_mc is not on the stage, so it could not be removed.')}
					if(data.track_end && data.track_end != 'false')addTracking('end',data.track_end);
				break;
		
				case "NetStream.Buffer.Full" : 
					if(isBuffering){
						buffer_full();
					}
				break;
				
				case "NetStream.Buffer.Empty" : 
					buffer_empty();
				break;
			}
		}
		private function buffer_empty(){
			isBuffering = true;
			nsStream.bufferTime=data.buffer_time;
			playClicked();
			hide_btnPause();
			show_controls();
			
			wrapper.removeEventListener(MouseEvent.MOUSE_OVER, show_controls);
			wrapper.removeEventListener(MouseEvent.MOUSE_OUT, hide_controls);		
			wrapper.removeEventListener(MouseEvent.MOUSE_OVER,show_btnPause);
			wrapper.removeEventListener(MouseEvent.MOUSE_OUT,hide_btnPause);

			displayMessage('buffering video...');
		}
		private function buffer_full(){
			isBuffering = false;		
			nsStream.bufferTime=0;
			wrapper.addEventListener(MouseEvent.MOUSE_OVER, show_controls);
			wrapper.addEventListener(MouseEvent.MOUSE_OUT, hide_controls);
			wrapper.addEventListener(MouseEvent.MOUSE_OVER,show_btnPause);
			wrapper.addEventListener(MouseEvent.MOUSE_OUT,hide_btnPause);
			
			removeMessage();
			hide_controls();
			hide_btnPause();
		}
		public function mute(e:Event = null){
			addPixel(e);
			if(e){
				dispatchEvent(muteEvt);
			}
			setVolume(0);
			if(!interacted && !!data.pauseAt && data.pauseAt != 'false'){
				clearpauseAt();
			}
		}
		public function unMute(e:Event = null){
			addPixel(e);
			if(e){
				dispatchEvent(unmuteEvt);
			}
			setVolume(1);
			if(!interacted && !!data.pauseAt && data.pauseAt != 'false'){
				clearpauseAt();
			}
		}
		public function playClicked(e:Event = null){
			addPixel(e);
			if(e){
				dispatchEvent(playEvt);
			}
			if(isMessage){try{removeMessage()}catch(e){}}
			
			if((!data.preload || data.preload === 'false') && !data.preloadLoaded){
				nsStream.play(data.source);
				nsStream.pause();
				nsStream.seek(0);
				data.preloadLoaded=true;
			}
			if(isStopped){
				isStopped = false;
				vidDisplay.visible= true;
				if(data.poster)poster.visible = false;
				tmrDisplay.addEventListener(TimerEvent.TIMER, updateDisplay);
				mcProgressBG.addEventListener(MouseEvent.MOUSE_DOWN, start_mov_seek);
				mcProgressFill.addEventListener(MouseEvent.MOUSE_DOWN, start_mov_seek);
			}
			if(data.track_play && data.track_play != 'false' && e!=null){
				addTracking('play',data.track_play);
			}
			wrapper.addEventListener(MouseEvent.MOUSE_OVER, show_controls);
			wrapper.addEventListener(MouseEvent.MOUSE_OUT, hide_controls);
			
			nsStream.resume();
		
			hide_btnPlay();
			show_btnPause();
			
			wrapper.addEventListener(MouseEvent.MOUSE_OVER,show_btnPause);
			wrapper.addEventListener(MouseEvent.MOUSE_OUT,hide_btnPause);
		}		
		public function pauseClicked(e:Event = null){
			addPixel(e);
			if(e){
				dispatchEvent(pauseEvt);
			}
			nsStream.pause();
			wrapper.removeEventListener(MouseEvent.MOUSE_OVER, show_controls);
			wrapper.removeEventListener(MouseEvent.MOUSE_OUT, hide_controls);		
			wrapper.removeEventListener(MouseEvent.MOUSE_OVER,show_btnPause);
			wrapper.removeEventListener(MouseEvent.MOUSE_OUT,hide_btnPause);
			
			if(data.track_pause && data.track_pause != 'false' && e!=null){
				addTracking('pause',data.track_pause);
			}
			if(!interacted && !!data.pauseAt && data.pauseAt != 'false'){
				clearpauseAt();
			}
			show_controls();
			show_btnPlay();
			hide_btnPause();
		}
		public function clearpauseAt(){
			clearTimeout(pauseAt);
			interacted = true;
		}
		public function show_controls(e:Event = null){
			TweenLite.to(controls_mc, 0.3, {x:0, y:data.height - controls_mc.height});
		}
		public function hide_controls(e:Event = null){
			TweenLite.to(controls_mc, 0.3, {x:0, y:data.height});
		}
		private function show_btnPause(e:Event = null){
			btnPause.visible = true;
		}
		private function hide_btnPause(e:Event = null){
			btnPause.visible = false;
		}
		private function show_btnPlay(e:Event = null){
			btnPlay.visible = true;
		}
		private function hide_btnPlay(e:Event = null){
			btnPlay.visible = false;
		}
		private function center(arg, vOffset:Number = 0){
			if(arg.height > data.height || arg.width > data.width){								  
				var ratio = Math.min(data.width / arg.width, data.height / arg.height);
				arg.width = arg.width * ratio;
				arg.height = arg.height * ratio;
			}
			arg.x = (data.width/2)-(arg.width/2); 
			arg.y = (data.height/2)-(arg.height/2)-vOffset;  
		}
		private function start_mov_seek(e:MouseEvent):void{
			stage.addEventListener(MouseEvent.MOUSE_UP, stop_mov_seek);
			stage.addEventListener(Event.MOUSE_LEAVE, stop_mov_seek);
			if(!isBuffering)wrapper.removeEventListener(MouseEvent.MOUSE_OUT, hide_controls);		
			if(!interacted && !!data.pauseAt && data.pauseAt != 'false'){
				clearpauseAt();
			}
			tmrDisplay.addEventListener(TimerEvent.TIMER, mov_seek);
		}
		private function stop_mov_seek(e:MouseEvent):void{
			addPixel(e);
			if(e){
				dispatchEvent(scrubEvt);
			}
			stage.removeEventListener(MouseEvent.MOUSE_UP, stop_mov_seek);
			stage.removeEventListener(Event.MOUSE_LEAVE, stop_mov_seek);
			if(!isBuffering)wrapper.addEventListener(MouseEvent.MOUSE_OUT, hide_controls);

			tmrDisplay.removeEventListener(TimerEvent.TIMER, mov_seek);
		}
		private function mov_seek(e:TimerEvent){
			nsStream.seek( Math.round((controls_mc.mouseX < mcProgressBG.width ? controls_mc.mouseX : mcProgressBG.width) * meta.duration) / trackBG.width); //the check is to stop you scrubbing past what is buffered
			//nsStream.seek(Math.round(controls_mc.mouseX * meta.duration) / trackBG.width);
		}
		public function addTracking(event:String, func=true){
			//trace('tracking added for ' + event)
			if(ExternalInterface.available){
				if(func == true || func == 'true'){
					ExternalInterface.call('wpAd.videoplayer.addPixel', event);
				}
				else{
					ExternalInterface.call(func, event);
				}
			}
		}
		private function oldSwitchVideo(video){
			stopVideoPlayer();
			data.source = video;
			data.autoplay = true;
			data.mute = lastVolume ? false : true;
			data.preloadLoaded = false;
			data.pauseAt = false;
			exec();
			hide_controls();
		}
		public function switchVideo(video = false){
			//more for use with letterBox'ing
			meta = null;
			vidDisplay.visible=false;
			
			if(video){
				oldSwitchVideo(video);
				return true;
			}
			stopVideoPlayer();
			data.mute = lastVolume ? false : true;
			data.preloadLoaded = false;
			exec();
			hide_controls();
		}
		
		private function updateData(arg){
			for(var key in arg){
				if(arg.hasOwnProperty(key) && data.hasOwnProperty(key)){
					data[key] = arg[key];
				}
			}
			data.autoplay = arg.hasOwnProperty('autoplay') ? Boolean(arg.autoplay) : true;
			data.pauseAt = arg.hasOwnProperty('pauseAt') ? arg.pauseAt : false;
			data.buffer_time = arg.hasOwnProperty('buffer_time') ? Number(arg.buffer_time) : 8;
			if(arg.hasOwnProperty('poster')){
				update_poster(true);
			}
			if(arg.hasOwnProperty('source')){
				switchVideo();
			}
		}
		public function attr(arg = null){
			if(arg is String){
				return data[arg];
			} else if(arg is Object){
				updateData(arg);
				return true;
			}
			return data;
		}
		public function addPixel(e):void{
			if(e && data.jsTrackFunction && data.trackingPixel){
				if(ExternalInterface.available) {
					ExternalInterface.call(data.jsTrackFunction, data.trackingPixel);
					//ExternalInterface.call(jsAddPixelFunction(data.trackingPixel));
				} else {
					navigateToURL(new URLRequest('javascript:'+data.jsTrackFunction+'("'+data.trackingPixel+'");'), '_self');
					//navigateToURL(new URLRequest('javascript:'+jsAddPixelFunction(data.trackingPixel), '_self');
				}
			}
		}
		
		//4 optional arguments added
		public function bind(evt:String, fn:String, arg1='', arg2='', arg3='', arg4=''):void{
			var extIntCall = function(e){
				ExternalInterface.call(fn,arg1,arg2,arg3,arg4);
			}
			if(vidPlayerEvents.hasOwnProperty(evt) || evt == 'all'){
				if(evt == 'all'){
					for(var key in vidPlayerEvents){
						if(key != 'stop'){
							this.addEventListener(vidPlayerEvents[key].type, extIntCall)
							vidPlayerEvents[key].fncache.push(extIntCall);
						}
					}
				} else {
					this.addEventListener(vidPlayerEvents[evt].type, extIntCall)
					vidPlayerEvents[evt].fncache.push(extIntCall);
				}
			}
		}
		
		public function unbind(e:String = null):void{
			var key:String, len:Number, i:Number;
			for(key in vidPlayerEvents){
				if((e == null || e == key || (e == 'all' && key != 'stop')) && this.hasEventListener(vidPlayerEvents[key].type)){
					len=vidPlayerEvents[key].fncache.length;
					for(i = 0; i<len; i++){
						this.removeEventListener(vidPlayerEvents[key].type, vidPlayerEvents[key].fncache[i]);
					}
					vidPlayerEvents[key].fncache = [];
				}
			}
		}
		
		private function changePage(url:*, window:String = "_blank"):void {
			var req:URLRequest = url is String ? new URLRequest(url) : url;
			if (!ExternalInterface.available) {
				navigateToURL(req, window);
			} else {
				var strUserAgent:String = String(ExternalInterface.call("function() {return navigator.userAgent;}")).toLowerCase();
				if (strUserAgent.indexOf("firefox") != -1 || (strUserAgent.indexOf("msie") != -1 && uint(strUserAgent.substr(strUserAgent.indexOf("msie") + 5, 3)) >= 6)) {
					ExternalInterface.call("window.open", req.url, window);
				} else {
					navigateToURL(req, window);
				}
			}
		}
	}
}