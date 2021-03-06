#FLASH:
    
    import VidPlayer.VidPlayer;
    
    var options = {
      //these are the default options for the video player.
      //Please note that "source" is the only required property. The rest are optional.
      
      //required:
      source : null, 
      
      //optional (along with default values if not specified):
      width : 320,
      height : 240,
      buffer_time : 8,
      autoplay : true,
      mute : true,
      controlsBorderFill : 0xFFFFFF,
      buttonsBGFill : 0x000000,
      buttonsFill : 0xFFFFFF,
      progressFill :  [ 0x6699CC, 0x306496 ],
      progressBufferFill:  [ 0xCCCCCC, 0x333333 ],
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
      preload : false,
      pauseAt : false,
      clickTag : false,
      jsTrackFunction : false,
      trackingPixel : false,
      letterBox : false,
      previewSource: null,
      fullSource: null
    };
    
    var myVideoPlayer:VidPlayer = new VidPlayer( options );
    addChild( myVideoPlayer );
    


The options can all also be passed in via FlashVars in the HTML - eg:

    <param name="flashVars" value="source=http://videoads.washingtonpost.com/son_in_law_tv.f4v&autoplay=false&mute=false" />


#HTML:

    <object type="application/x-shockwave-flash" data="VidPlayer.swf" width="700" height="400" id="videoPlayer" name="videoPlayer" style="outline:none;">
      <param name="movie" value="VidPlayer.swf" />
      <param name="quality" value="high" />
      <param name="bgcolor" value="#000000" />
      <param name="wmode" value="transparent" />
      <param name="scale" value="noscale " />
      <param name="menu" value="true" />
      <param name="devicefont" value="false" />
      <param name="allowScriptAccess" value="always" />
      <param name="flashVars" value="source=http://videoads.washingtonpost.com/son_in_law_tv.f4v&mute=false&autoplay=false&standAlone=true" />
    </object>



#JAVASCRIPT INTERACTION:

function for referencing the video player swf
    

    function thisMovie(movieName) {
      if (navigator.appName.indexOf("Microsoft") != -1) {
        return window[movieName];
      } else {
        return document[movieName];
      }
    }


##attr:
######How to use: 

    attr(object with video player options:Object);

######EXAMPLE:
this will switch video and poster when called and will start playing the new video:
    

    thisMovie("ID/name of video player swf").attr({
      source : 'http://videoads.washingtonpost.com/Smartwater_Sizzle_15sec_10.20.11.v6_HR.f4v',
      poster : 'http://media.washingtonpost.com/wp-adv/advertisers/smartwater/2011/poster.jpg',
      autoplay : false
    });



##bind:
######How to use: 


    bind(event:String, javascript_function:String, param1(optional), param2(optional), param3(optional), param4(optional));
    
can bind events to: "pause", "play", "stop", "mute", "unmute", "scrub", "all"

######EXAMPLE:

this will call 'console.log("video has been paused")' when the user pauses the video:


    thisMovie("ID/name of video player swf").bind('pause','console.log','video has been paused')

This will render a tracking pixel on ANY interaction with the player:
    
    

    function vidPlayerAddPixel(src) {
      var i = document.createElement("img");
      i.src = src;
      i.height = "1";
      i.width = "1";
      i.style.display = "none";
      document.body.appendChild(i);
    }
    
    thisMovie("ID/name of video player swf").bind('all','vidPlayerAddPixel','myPixelURL'); 
   

##unbind:
######How to use: 
   

    unbind(event:String);
    
the "event" argument is optional. If omitted, all bind events will be cleared.

######EXAMPLE:

this will clear all 'pause' events added via bind:
    

    thisMovie("ID/name of video player swf").unbind('pause');



##BASIC CONTROLS WITH JAVASCRIPT:

##play:
######EXAMPLE:

    thisMovie("ID/name of video player swf").play();

##pause:
######EXAMPLE:

    thisMovie("ID/name of video player swf").pause();

##stop:
######EXAMPLE:

    thisMovie("ID/name of video player swf").stop();

##mute:
######EXAMPLE:

    thisMovie("ID/name of video player swf").mute();

##unmute:
######EXAMPLE:

    thisMovie("ID/name of video player swf").unmute();
    

##Last updated by Mike Spencer 7/16/12