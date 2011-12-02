package VidPlayer {
	
	import flash.events.Event;
	public class VidPlayerEvent extends Event {
	
		public static const PLAY:String = "play";
		public static const PAUSE:String = "pause";
		public static const STOP:String = "stop";
		public static const SCRUB:String = "scrub";
		public static const MUTE:String = "mute";
		public static const UNMUTE:String = "unmute";

		public function VidPlayerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false):void {
			super(type, bubbles, cancelable);
		}

	}
}
