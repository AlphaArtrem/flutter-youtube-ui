import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_ui/helper/functions.dart';
import 'package:youtube_ui/helper/loading.dart';
import 'package:youtube_ui/helper/youtubeAPI.dart';

class VideoPlayer extends StatefulWidget {
  final Map videoDetails;
  VideoPlayer(this.videoDetails);
  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  YoutubePlayerController _controller;
  TextEditingController _idController;
  TextEditingController _seekToController;

  PlayerState _playerState;
  YoutubeMetaData _videoMetaData;
  double _volume = 100;
  bool _muted = false;
  bool _isPlayerReady = false;
  List _videos = [];
  List<Widget> _videosWidgets = [];
  Map _channelDetails = {};

  static String key = 'AIzaSyAqMLu_Grl4Q6AMxT_ieSDF_Ul6jkchk6c';
  YoutubeAPI _api = YoutubeAPI(key);

  void setup() async{
    String id;
    try{
      id = widget.videoDetails["id"];
    }catch(e){
      id = widget.videoDetails["id"]["videoId"];
    }
    _controller = YoutubePlayerController(
      initialVideoId: id,
      flags: const YoutubePlayerFlags(
        mute: false,
        autoPlay: true,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    )..addListener(listener);
    _idController = TextEditingController();
    _seekToController = TextEditingController();
    _videoMetaData = const YoutubeMetaData();
    _playerState = PlayerState.unknown;
    _videos = await _api.getRelatedVideos(id);

    List<String> ids = [];

    for(int i = 0; i < _videos.length; i++){
      ids.add(_videos[i]["snippet"]["channelId"]);
    }

    List channels = await _api.getChannelDetails(ids);
    for(Map channel in channels){
      _channelDetails[channel['id']] = channel;
    }
    setState(() {});

    for(int index = 0 ; index < _videos.length && _videos.isNotEmpty; index++){
      String publishedAt = uploadDuration(_videos[index]["snippet"]["publishedAt"]);
      String thumbnail  = _videos[index]["snippet"]["thumbnails"]["high"]["url"];

      _videosWidgets.add(Container(
        child: Column(
          children: <Widget>[
            GestureDetector(
              onTap: () async{
                Map videoDetails = _videos[index];
                videoDetails["channelImage"] = _channelDetails[_videos[0]["snippet"]['channelId']]["snippet"]["thumbnails"]["default"]["url"];
                videoDetails["subscriberCount"] = _channelDetails[_videos[0]["snippet"]['channelId']]["statistics"]["subscriberCount"];
                _controller.pause();
                await Navigator.push(context, MaterialPageRoute(
                    builder : (context) => VideoPlayer(videoDetails)
                ));
                _controller.play();
              },
              child: AspectRatio(
                child: Image(
                  image: NetworkImage(thumbnail),
                  fit: BoxFit.cover,
                ),
                aspectRatio: 16 / 9,
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(_channelDetails[_videos[0]["snippet"]['channelId']]["snippet"]["thumbnails"]["default"]["url"]),
              ),
              title: Text(
                _videos[index]["snippet"]['title'],
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15.0),
              ),
              subtitle: Text(_videos[index]["snippet"]['channelTitle'] + " \u22C5 " + publishedAt, style: TextStyle(color: Colors.grey, fontSize: 12.0)),
              trailing: Icon(Icons.more_vert),
            ),
          ],
        ),
      ));
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    setup();
  }

  void listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {
        _playerState = _controller.value.playerState;
        _videoMetaData = _controller.metadata;
      });
    }
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page.
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    _idController.dispose();
    _seekToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String publishedAt = uploadDuration(widget.videoDetails["snippet"]["publishedAt"]);
    String viewCount;
    try{
      viewCount = formatViewCount(widget.videoDetails["statistics"]["viewCount"]) + " \u22C5 ";
    }catch(e){
      viewCount = "";
    }
    return _videosWidgets.isEmpty ? Container(color: Colors.white, child: spinkit,) : YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.blueAccent,
        topActions: <Widget>[
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(widget.videoDetails["snippet"]['title'], style: const TextStyle(color: Colors.white, fontSize: 18.0,), overflow: TextOverflow.ellipsis, maxLines: 1,),
          ),
        ],
        onEnded: (data) {
          //_controller.load(_ids[(_ids.indexOf(data.videoId) + 1) % _ids.length]);
          _showSnackBar('Video Ended');
        },
      ),
      builder: (context, player) => Scaffold(
        key: _scaffoldKey,
        body: ListView(
          children: [
            player,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 15, top: 15),
                  child: Text(widget.videoDetails["snippet"]['title'], style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16.0),),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 5.0),
                  child: Text(viewCount + publishedAt, style: TextStyle(color: Colors.grey, fontSize: 12.0)),
                ),
                Container(
                  margin: EdgeInsets.only(top: 15.0),
                  padding: const EdgeInsets.only(top: 10.0, left: 8.0, bottom: 10.0),
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Colors.grey[300]),
                        bottom: BorderSide(color: Colors.grey[300])
                    )
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(widget.videoDetails["channelImage"]),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.videoDetails["snippet"]['channelTitle'], style: TextStyle( fontSize: 15.0, fontWeight: FontWeight.w400)),
                                  SizedBox(height: 5),
                                  Text(formatViewCount(widget.videoDetails['subscriberCount']), style: TextStyle( fontSize: 12.0, fontWeight: FontWeight.w400, color: Colors.grey[500])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text("SUBSCRIBE", style: TextStyle( fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.red)),
                      SizedBox(width: 15),
                    ],
                  ),
                )
              ],
            ),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 10, bottom: 10),
            child: Text('Related videos', style: TextStyle(fontSize: 15.0),),
          ),
          Container(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _videosWidgets
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w300,
            fontSize: 16.0,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
      ),
    );
  }

}