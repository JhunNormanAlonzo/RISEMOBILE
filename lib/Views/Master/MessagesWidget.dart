

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Resources/MyHttpOverrides.dart';
import 'package:rise/Resources/Pallete.dart';

class MessagesWidget extends StatefulWidget {
  const MessagesWidget({super.key});

  @override
  State<MessagesWidget> createState() => _MessagesWidgetState();
}

class _MessagesWidgetState extends State<MessagesWidget> {

  bool isToggled = false;
  Future<List<dynamic>>? messages;
  late AudioPlayer audioPlayer;

  @override
  void initState() {
    super.initState();
    _syncMessages();
  }

  _syncMessages() async {
    try {
      final fetchedMessages = await api.getMessages();
      setState(() {
        messages = Future.value(fetchedMessages);
      });
    } catch (e) {
      setState(() {
        messages = Future.error("Failed to load messages");
      });
    }
  }

  deleteMessage(fileName){
    debugPrint("deleted : $fileName");
  }


  //
  //
  // void _playVm(String playVm){
  //   audioPlayer = AudioPlayer().setSourceUrl(playVm) as AudioPlayer;
  //   showDialog(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(surfaceTintColor: Colors.blueAccent,
  //             content: SizedBox(
  //               width: MediaQuery.of(context).size.width/1.2,
  //               height: MediaQuery.of(context).size.height/6.0,
  //               child: Column(mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   StreamBuilder(
  //                     stream: _positionDataStream,
  //                     builder: (context,snapshot){
  //                       final positionData = snapshot.data;
  //                       return ProgressBar(
  //                         barHeight: 8,
  //                         baseBarColor: Colors.grey[800],
  //                         bufferedBarColor: Colors.grey,
  //                         progressBarColor: Colors.blue,
  //                         thumbColor: Colors.red,
  //                         timeLabelTextStyle: const TextStyle(
  //                             color: Colors.black,
  //                             fontWeight: FontWeight.w600
  //                         ),
  //                         progress: positionData?.position ?? Duration.zero,
  //                         buffered: positionData?.bufferedPosition ?? Duration.zero,
  //                         total: positionData?.duration ?? Duration.zero,
  //                         onSeek: audioPlayer.seek,
  //                       );
  //                     },
  //                   ),
  //                   const SizedBox(height: 20,),
  //                   Controls(audioPlayer: audioPlayer),
  //                 ],
  //               ),
  //             )
  //         );
  //       }
  //   );
  //
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: FutureBuilder<dynamic>(
                future: messages,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else if (snapshot.hasData && snapshot.data.isNotEmpty) {
                    return ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (context, index) {

                        String fileName = snapshot.data[index];
                        return Dismissible(
                          key: UniqueKey(),
                          onDismissed: (direction) {
                            deleteMessage(fileName);
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   SnackBar(content: Text("$fileName deleted")),
                            // );
                          },
                          background: Container(
                            color: Pallete.gradient4,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: AlignmentDirectional.center,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          secondaryBackground: Container(
                            color: Pallete.gradient4,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: AlignmentDirectional.center,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.white24, // Adjust the tile background color
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  (index + 1).toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                fileName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              // subtitle: Text(
                              //   'Duration: 04:30', // Placeholder for actual metadata
                              //   style: TextStyle(color: Colors.grey[400]),
                              // ),
                              trailing: IconButton(
                                icon: const Icon(Icons.play_arrow, color: Colors.white),
                                onPressed: () async{
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Not yet playable lasse.")),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: Text('No audio files available', style: TextStyle(color: Colors.white)),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            final recordings = await api.getMessages();
            setState(() {
              messages = Future.value(recordings);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Messages updated...")),
            );
          } on PlatformException catch (e) {
            print("Failed to load messages: ${e.message}.");
          }
        },
        backgroundColor: Pallete.gradient4,
        child: const Icon(Icons.refresh, color: Pallete.white,),
      ),
    );
  }
}
