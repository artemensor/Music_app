import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

typedef void OnError(Exception exception);
String songsDirectoryPath;
String localFilePath;
String kUrl =
    "https://www.mediacollege.com/downloads/sound-effects/nature/forest/rainforest-ambient.mp3";

String title_song = "test";
String author_song = "test2";
bool online = true;


void main() {
  final title = "Oppa";
  runApp(MaterialApp(home: Scaffold(body:
   Home(
     //title:title, 
     //channel : IOWebSocketChannel.connect('ws://192.168.1.115:5000/ws')
     ))));
}

enum PlayerState { stopped, playing, paused, next }

class AudioApp extends StatefulWidget {
  final VoidCallback onNextSelected;
  const AudioApp({Key key, this.onNextSelected}) : super(key: key);

  
  @override
  _AudioAppState createState() => new _AudioAppState();
}

class _AudioAppState extends State<AudioApp> {
  Duration duration;
  Duration position;
  Future<List<Post>> futurePosts;
  AudioPlayer audioPlayer;
  bool repeat_flag = false;

  void updateText() {
    stop();
    _playLocal();
  }
  void playSongOnline() {
    stop();
    play();
  }

  String url;
  List<String> entries2 = [];
  PlayerState playerState = PlayerState.stopped;

  get isPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;

  get durationText =>
      duration != null ? duration.toString().split('.').first : '';

  get positionText =>
      position != null ? position.toString().split('.').first : '';

  bool isMuted = false;

  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;
  void presso()
  {
    
    setState(() {
      entries2 = SongList(songsDirectoryPath);
    });
  }
  void someAction(String urlSong)
  {
    
    futurePosts = fetchPost(urlSong);
    
    // futurePosts.then((result) {
    //   kUrl2 = result.url;
    // });
    print("linked");
  }
  Future initfunc() async {
    final dir = await getExternalStorageDirectory();
    songsDirectoryPath = dir.path;
    
  }
  @override
  void initState() {
    super.initState();
    initAudioPlayer();
    initfunc();
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _audioPlayerStateSubscription.cancel();
    audioPlayer.stop();
    super.dispose();
  }

  void initAudioPlayer() {
    audioPlayer = AudioPlayer();
    _positionSubscription = audioPlayer.onAudioPositionChanged
        .listen((p) => setState(() => position = p));
    _audioPlayerStateSubscription =
        audioPlayer.onPlayerStateChanged.listen((s) {
      if (s == AudioPlayerState.PLAYING) {
        setState(() => duration = audioPlayer.duration);
      } else if (s == AudioPlayerState.STOPPED) {
        print("step 2");
        onComplete();
        setState(() {
          position = duration;
        });
      }
    }, onError: (msg) {
      setState(() {
        playerState = PlayerState.stopped;
        duration = Duration(seconds: 0);
        position = Duration(seconds: 0);
      });
    });
  }
  Future playSome(String url_song) async {
    await audioPlayer.play(url_song);
    setState(() {
      playerState = PlayerState.playing;
    });
  }

  Future play() async {
    await audioPlayer.play(kUrl);
    setState(() {
      playerState = PlayerState.playing;
    });
  }

  Future _playLocal() async {
    await audioPlayer.play(localFilePath, isLocal: true);
    setState(() => playerState = PlayerState.playing);
  }

  Future pause() async {
    await audioPlayer.pause();
    setState(() => playerState = PlayerState.paused);
  }

  Future stop() async {
    print("step 0");
    setState(() {
      print("step 1");
      playerState = PlayerState.stopped;
      position = Duration();
    });
    await audioPlayer.stop();
    
  }

  Future mute(bool muted) async {
    await audioPlayer.mute(muted);
    setState(() {
      isMuted = muted;
    });
  }

  Future onComplete() async{
    print("step 3");
    //print("we over");
    if(playerState == PlayerState.playing)
    {
      print("step 4");
      //setState(() => playerState = PlayerState.stopped);
      if(repeat_flag){
        if(online){
          play();
        }
        else{
          _playLocal();
        }
      }
      else{
        // play next song with play_next
        widget.onNextSelected();
        await audioPlayer.play(kUrl);
        setState(() {
          playerState = PlayerState.playing;
        });
      }
    }
    else{
      //we already stopped
    }
    

    // if (repeat_flag){
    //   if(online){
    //     play();
    //   }
    //   else{
    //     _playLocal();
    //   }
    // }
    // else{
    //   play_next();
    // }

  }
  Future play_next() async{
    //playerState = PlayerState.next;
    print("next");
    if (online){
      print(online);
      //Search +
      widget.onNextSelected();
      

      setState(() {
        playerState = PlayerState.stopped;
        position = Duration();
      });
      await audioPlayer.stop();
      

      await audioPlayer.play(kUrl);
      setState(() {
        playerState = PlayerState.playing;
      });
    }
    else{
      //Library ? select next in memory
    }
    
  }
  void play_random(){
    print("random");
  }

  void repeat(){
    //print("repeat");
    setState(() {
      repeat_flag = !repeat_flag;
    });
    

  }

  Future<Uint8List> _loadFileBytes(String url, {OnError onError}) async {
    Uint8List bytes;
    try {
      bytes = await readBytes(url);
    } on ClientException {
      rethrow;
    }
    return bytes;
  }
  
  List<String> SongList(String path) // path to directory with songs
  {
    var systemTempDir = new Directory(path);
    List<String> songList = new List<String>();
    List<FileSystemEntity> entitySongs = systemTempDir.listSync(recursive: true, followLinks: false).toList();
    for(int j=0;j<entitySongs.length;j++)
    {
      songList.add(entitySongs[j].path.substring(path.length+1,));
    }    
    return songList;
  }
  Future _loadFile() async {
    final bytes = await _loadFileBytes(kUrl,
        onError: (Exception exception) =>
            print('_loadFile => exception $exception'));

    final dir = await getExternalStorageDirectory();
    final file = File('${dir.path}/$author_song-$title_song.mp3');//change name

    await file.writeAsBytes(bytes);
    if (await file.exists())
      setState(() {
        localFilePath = file.path;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       title: Text('Music App'),
     ),
      body:  Center(
        child: new Material(
            elevation: 2.0,
            color: Colors.grey[200],
            child: new Center(
              child: new Column(
                  
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    
                    new Material(child: _buildPlayer()),
                    localFilePath != null
                        ? new Text(author_song + " - " + title_song)
                        : new Container(),
                    new Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(children: <Widget>[ 
                        new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: () => _loadFile(),
                              iconSize: 32.0,
                              icon: Icon(Icons.cloud_download),
                              color: Colors.cyan,
                            ),
                            IconButton(
                              onPressed: () => play_random(),
                              iconSize: 32.0,
                              icon: Icon(Icons.call_missed_outgoing),
                              color: Colors.cyan,
                            ),
                            // new RaisedButton(
                            //   onPressed: () => _playLocal(),
                            //   child: new Text('play local'),
                            // ),
                            // new RaisedButton(
                            //   onPressed: () => play(),
                            //   child: new Text('play online'),
                            // ),
                           
                            // new RaisedButton(
                            //   onPressed: () => presso(),
                            //   child: new Text('update'),
                            // ),
                            
                            
                          ]),
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          //   children: <Widget>[
                              
                              
                          //     new RaisedButton(
                          //     onPressed: () => play_random(),
                          //     child: new Text('Random'),
                          //     ),
                            
                          // ],)
                          ],
                        )
                    ),
                    localFilePath != null
                        ? new Text(localFilePath + "  -  LAST downloaded")
                        : new Container(),
                    // new RaisedButton(
                    //           onPressed: () => someAction(myController.text),
                    //           child: new Text('search'),
                    //         ),
                    // // new RaisedButton(
                    // //           onPressed: () {Navigator.pushNamed(context, '/second');}, 
                    // //           child: Text('open2')
                    // //           ),
                    // // new RaisedButton(
                    // //           onPressed: () {Navigator.pushNamed(context, '/third');}, 
                    // //           child: Text('open3')
                    //           // ),
                    // new TextField(
                    //   controller: myController,
                    // ),
                    //Expanded(child:_buildSuggestions())
                  ]),
            )))
    );
  }

  Widget _buildPlayer() => Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                onPressed: isPlaying ? null : () => play(),
                iconSize: 64.0,
                icon: Icon(Icons.play_arrow),
                color: Colors.cyan,
              ),
              IconButton(
                onPressed: isPlaying ? () => pause() : null,
                iconSize: 64.0,
                icon: Icon(Icons.pause),
                color: Colors.cyan,
              ),
              IconButton(
                onPressed: isPlaying || isPaused ? () => stop() : null,
                iconSize: 64.0,
                icon: Icon(Icons.stop),
                color: Colors.cyan,
              ),
              IconButton(
                onPressed: () => play_next(),
                iconSize: 64.0,
                icon: Icon(Icons.skip_next),
                color: Colors.cyan,
              ),
            ]),
            if (duration != null)
              Slider(
                  value: position?.inMilliseconds?.toDouble() ?? 0.0,
                  onChanged: (double value) {
                    return audioPlayer.seek((value / 1000).roundToDouble());
                  },
                  min: 0.0,
                  max: duration.inMilliseconds.toDouble()),
            if (position != null) _buildMuteButtons(),
            if (position != null) _buildProgressView()
          ],
        ),
      );

  Row _buildProgressView() => Row(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(
            value: position != null && position.inMilliseconds > 0
                ? (position?.inMilliseconds?.toDouble() ?? 0.0) /
                    (duration?.inMilliseconds?.toDouble() ?? 0.0)
                : 0.0,
            valueColor: AlwaysStoppedAnimation(Colors.cyan),
            backgroundColor: Colors.grey.shade400,
          ),
        ),
        Text(
          position != null
              ? "${positionText ?? ''} / ${durationText ?? ''}"
              : duration != null ? durationText : '',
          style: TextStyle(fontSize: 24.0),
        )
      ]);

  Row _buildMuteButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        if (!isMuted)
          FlatButton.icon(
            onPressed: () => mute(true),
            icon: Icon(
              Icons.headset_off,
              color: Colors.cyan,
            ),
            label: Text('Mute', style: TextStyle(color: Colors.cyan)),
          ),
        if (isMuted)
          FlatButton.icon(
            onPressed: () => mute(false),
            icon: Icon(Icons.headset, color: Colors.cyan),
            label: Text('Unmute', style: TextStyle(color: Colors.cyan)),
          ),
        if (!repeat_flag)
          FlatButton.icon(
            onPressed: () => repeat(),
            icon: Icon(Icons.repeat, color: Colors.grey),
            label: Text('Repeat', style: TextStyle(color: Colors.grey)),
          ),
        if (repeat_flag)
          FlatButton.icon(
            onPressed: () => repeat(),
            //iconSize: 64.0,
            icon: Icon(Icons.repeat_one, color: Colors.cyan),
            label: Text('Repeat', style: TextStyle(color: Colors.cyan)),
            
          ),
      ],
    );
  }
}




//HOME




class Home extends StatefulWidget {

  // final String title;
  // final WebSocketChannel channel;

  // Home({Key key, @required this.title, @required this.channel})
  //     : super(key: key);

 @override
 State<StatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends State<Home>  with SingleTickerProviderStateMixin{

  
  int _currentIndex = 0;
  static GlobalKey<_AudioAppState> _keyChild1 = GlobalKey<_AudioAppState>();
  static GlobalKey<_SearchState> _keyChild2 = GlobalKey<_SearchState>();
  //static GlobalKey<_SearchState> _keyChild2 = GlobalKey<_SearchState>();

  //final List<Widget> _children = [Library(onCountSelected: ()=>{_keyChild1.currentState.updateText()},),AudioApp(key: _keyChild1),Search(onCountSelected: ()=>_keyChild1.currentState.playSongOnline())];
  final List<Widget> _children = [
    AudioApp(key: _keyChild1, onNextSelected: ()=>{_keyChild2.currentState.getNext()},),
    Library(onCountSelected: ()=>{_keyChild1.currentState.updateText()},),
    Search(key: _keyChild2,onCountSelected: ()=>_keyChild1.currentState.playSongOnline(),
    title: "Search",
    channel : IOWebSocketChannel.connect('ws://192.168.1.115:5000/ws'))];


void onTabTapped(int index) {
  //_keyChild1.currentState.updateText("Update from Parent");
  if (index == 3)
  {
    //_sendMessage("pip123", "mobile");
  }
  else{
   setState(() {
     _currentIndex = index;
   });
  }
 }
 @override
 Widget build(BuildContext context) {
   return Scaffold(
     body: Stack(children: <Widget>[
       IndexedStack(
       children: _children,
       index: _currentIndex,
     ),
    //  StreamBuilder(
    //           stream: widget.channel.stream,
    //           builder: (context, snapshot) {
    //             if(snapshot.hasData)
    //             {
    //               print(snapshot.data);
    //             }
    //             return Padding(
    //               padding: const EdgeInsets.symmetric(vertical: 24.0),
    //               child: Text(snapshot.hasData ? '${snapshot.data}' : ''),
    //             );
    //           },
    //         ), 
            ],),
     bottomNavigationBar: BottomNavigationBar(
       //backgroundColor: Color(0xff00BCD1),
       onTap: onTabTapped, // new
       currentIndex: _currentIndex, 
       items: [
         BottomNavigationBarItem(
           backgroundColor: Color(0xff00BCD1),
           icon: new Icon(Icons.library_music),
           title: new Text('Player'),
         ),
         BottomNavigationBarItem(
           icon: new Icon(Icons.library_music),
           title: new Text('Library'),
         ),
        BottomNavigationBarItem(
           icon: new Icon(Icons.library_music),
           title: new Text('Search'),
         ),
        //  BottomNavigationBarItem(
        //    icon: new Icon(Icons.library_music),
        //    title: new Text('Socket'),
        //  ),
       ],
     ),
    //  floatingActionButton: FloatingActionButton(
    //     onPressed: _sendMessage,
    //     tooltip: 'Send message',
    //     child: Icon(Icons.send),
    //   ),
   );
 }
//  void _sendMessage(String text, String type1) async{
//     // http.Response response = await http.get(
//     //     "https://sun9-12.userapi.com/c858120/v858120946/50797/p_PJuPB3En4.jpg",
//     //   );
//     //String _base64 = base64Encode(response.bodyBytes);
//     //print(_base64);
    
//     widget.channel.sink.add(
//         json.encode(
//         {
//             "type": type1,
//             'encodings': text
//         }
//         )
//     );
    
//   }
  @override
  void dispose() {
    //widget.channel.sink.close();
    super.dispose();
  }
}



// SEARCH


class Search extends StatefulWidget{

  final VoidCallback onCountSelected;
  final String title;
  final WebSocketChannel channel;

  // Home({Key key, @required this.title, @required this.channel})
  //     : super(key: key);

  Search({Key key, this.onCountSelected, @required this.title, @required this.channel}): super(key:key);

  @override
  State<StatefulWidget> createState() {
    return _SearchState();
  }
}

class _SearchState extends State<Search>{
  Future<List<Post>> futurePosts;
  List<String>_suggestions = new List<String>();
  List<Post> songs = new List<Post>();
  List<Post_short> songs_short = new List<Post_short>();
  int numberOfSong = 0;

  void getNext(){
    numberOfSong++;
    if (numberOfSong == songs.length){
      numberOfSong = 0;
    }
    kUrl = songs[numberOfSong].url;
  }

  Widget _buildRow(String url, String author, String title, numberOfSongInList) {
  return ListTile(
    onTap: ()=>{numberOfSong = numberOfSongInList, kUrl = url,author_song= author,title_song= title,
     widget.onCountSelected()},
    title: Text(
      author + " - " + title,
    ),
     
  );
}
  Widget _buildSuggestions() {
  return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: (songs.length)*2 - 1,
      itemBuilder: /*1*/ (context, i) {
        if (i.isOdd) return Divider(); /*2*/

        final index = i ~/ 2; /*3*/
        if (index >= _suggestions.length) {
          _suggestions.add(songs[_suggestions.length].artist + " - " +songs[_suggestions.length].title);
          //_suggestions.addAll(songs.sublist(_suggestions.length,_suggestions.length+1)); /*4*/
        }
        return _buildRow( songs[index].url, 
        songs[index].artist, songs[index].title,0);
      });
}
  final myController = TextEditingController();

  void someActionBuilder(List<Post> result){
    //setState(() {
        songs.clear();// if not clear added to end of last list
        _suggestions.clear();
        for(int j =0;j<result.length;j++)
        {
          songs.add(result[j]);
          //print("wowo" + songs[j].title);
        }
      //});
  }

  void someAction(String urlSong)
  {
    _sendMessage(urlSong, "mobile");
    //print(urlSong);
    // futurePosts = fetchPost(urlSong);
    
    // futurePosts.then((result) {
    //   //kUrl2 = result.url;
    //   //setstate
    //   setState(() {
    //     songs.clear();// if not clear added to end of last list
    //     _suggestions.clear();
    //     for(int j =0;j<result.length;j++)
    //     {
    //       songs.add(result[j]);
    //     }
    //   });
    // });
    
  }
  Widget buuilds(){
  List<Widget> A = new List<Widget>();
  for(int j=0;j<songs.length;j++){
    //A.add(_buildRow(songs[j].type, songs_short[j].encodings));
    A.add(_buildRow( songs[j].url, 
        songs[j].artist, songs[j].title, j));

    //A.add(_buildRow(songs[j].artist + " - " + songs[j].title, songs[j].url));
    // A.add(Container(
    //   height: 50,
    //   color: Colors.amber[600],
    //   child:  Center(child: Text(songs[j].title)),
    // ));
  }
  return ListView(
  padding: const EdgeInsets.all(8),
  children: A,
);
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
       title: Text('Search'),
     ),
      body: 
        
        Center(
        child: new Material(
            elevation: 2.0,
            color: Colors.grey[200],
            child: new Center(
              child: new Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    new RaisedButton(
                              onPressed: () => someAction(myController.text),
                              child: new Text('search'),
                            ),
                    new TextField(
                      controller: myController,
                    ),
              Expanded(child:StreamBuilder(
              stream: widget.channel.stream,
              builder: (context, snapshot) {
                if(snapshot.hasData)
                {
                  //print(snapshot.data);
                  Map userMap = jsonDecode(snapshot.data);
                  //print(userMap);
                  List<Post> full_list = new List<Post>();
                  for(int j=0;j<userMap["encodings"].length;j++)
                  {
                    full_list.add(Post.fromJson(userMap["encodings"][j]));
                    //print(full_list[j].title);

                  }
                  //var info = Post_short.fromJson(snapshot.data);
                  //var info = Post_short();
                  //info.encodings =userMap["encodings"];
                  //info.type = userMap["type"];

                  //print(info.type);

                  someActionBuilder(full_list);
                }
                return buuilds();
              },
            )),
                  ]
              )
            )
        )
      )
      
    );
  }
  void _sendMessage(String text, String type1) async{
    // http.Response response = await http.get(
    //     "https://sun9-12.userapi.com/c858120/v858120946/50797/p_PJuPB3En4.jpg",
    //   );
    //String _base64 = base64Encode(response.bodyBytes);
    //print(_base64);
    
    widget.channel.sink.add(
        json.encode(
        {
            "type": type1,
            'encodings': text
        }
        )
    );
    
  }
  @override
  void dispose() {
    widget.channel.sink.close();
    super.dispose();
  }
}




//POSTS



Future<List<Post>> fetchPost(String name) async {
  print("gpgp");
  print(name);
  
  final response =
      await http.get('http://10.0.2.2:5000/songs/' + name);
  if (response.statusCode == 200) {
    // If the call to the server was successful, parse the JSON.
    List<Post> Posts = List<Post>();
    for (var j in json.decode(response.body)) {
      Posts.add(Post.fromJson(j));
    }
    //return Post.fromJson(json.decode(response.body)[0]);
    return Posts;
  } else {
    // If that call was not successful, throw an error.
    throw Exception('Failed to load post');
  }
}

String decodeUrl(String url)
{
  return url.split('').reversed.join('');
}

class Post {
  final bool done;
  final int id;
  final String title;
  final String artist;
  final int owner_id;
  final String url;
  final int duration;

  Post({this.done, this.id, this.title, this.url, this.duration, this.artist, this.owner_id});

 

  factory Post.fromJson(Map<String, dynamic> json) {
    //print(json['url']);
    return Post(
      artist: json['artist'],
      id: json['id'],
      title: json['title'],
      //url: decodeUrl(json['url']),
      url: json["url"],
      duration: json['duration'],
      owner_id: json['owner_id'],
    );
  }
}

class Post_short {
 
   String type;
   String encodings;


  Post_short({this.type, this.encodings});

  

 

  factory Post_short.fromJson(Map<String, dynamic> json) {
    //print(json['url']);
    return Post_short(
      type: json['type'],
      encodings: json['encodings'],
     
    );
  }
}


// LIBRARY

class Library extends StatefulWidget{
final VoidCallback onCountSelected;

Library({this.onCountSelected});

  State<StatefulWidget> createState() {
      return _LibraryState();
    }
}
class _LibraryState extends State<Library>
{
  List<String>_suggestions = new List<String>();
  Widget _buildRow(String pair) {
  return ListTile(
    onTap: ()=>{localFilePath=songsDirectoryPath+"/"+pair, widget.onCountSelected()},//_playLocal()},
    //onTap: ()=>{print("here we are")},
    title: Text(
      pair,
    ),
     
  );
}
  Widget _buildSuggestions() {
  return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: (songs.length)*2 - 1,
      itemBuilder: /*1*/ (context, i) {
        if (i.isOdd) return Divider(); /*2*/

        final index = i ~/ 2; /*3*/
        if (index >= _suggestions.length) {
          _suggestions.addAll(songs.sublist(_suggestions.length,_suggestions.length+1)); /*4*/
        }
        return _buildRow(_suggestions[index]);
      });
}
Widget buuilds(){
  List<Widget> A = new List<Widget>();
  for(int j=0;j<songs.length;j++){
    A.add(_buildRow(songs[j]));
    // A.add(Container(
    //   height: 50,
    //   color: Colors.amber[600],
    //   child:  Center(child: Text(songs[j])),
    // ));
  }
  return ListView(
  padding: const EdgeInsets.all(8),
  children: A,
);
}

  List<String> songs = [];
  List<String> SongList(String path) // path to directory with songs
  {
    var systemTempDir = new Directory(path);
    List<String> songList = new List<String>();
    List<FileSystemEntity> entitySongs = systemTempDir.listSync(recursive: true, followLinks: false).toList();
    for(int j=0;j<entitySongs.length;j++)
    {
      songList.add(entitySongs[j].path.substring(path.length+1,));
    }    
    return songList;
  }
  void presso()
  {
    
    setState(() {
      songs = SongList(songsDirectoryPath);
      print(songs);
    });
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(
        title: Text("Library"),
      
      ),
      body: Center(
        child: new Material(
            elevation: 2.0,
            color: Colors.grey[200],
            child: new Center(
              child: new Column(
                  
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    new RaisedButton(
                              onPressed: () => presso(),
                              child: new Text('update'),
                            ),
                    Expanded(child:buuilds())
                          
                  ],
              )
            )
        )
      )
    );
  }
}
