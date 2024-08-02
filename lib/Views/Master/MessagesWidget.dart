

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Controllers/CoreController.dart';
import 'package:rise/Resources/MyHttpOverrides.dart';
import 'package:rise/Resources/Pallete.dart';

class MessagesWidget extends StatefulWidget {
  const MessagesWidget({super.key});
  @override
  State<MessagesWidget> createState() => _MessagesWidgetState();
}

class _MessagesWidgetState extends State<MessagesWidget> {

  bool isToggled = false;
  Future<Map<String, dynamic>>? messages;


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

  deleteMessage(id) async{
    await api.deleteMessage(id);
    debugPrint("deleted : $id");
  }

  downloadLink(file) async{
    final link = await api.getDownloadLink(file);
    return link;
  }

  setReadMessage(id) async{
    await api.setReadMessage(id);
    debugPrint("read : $id");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: messages,
                builder: (context, snapshot) {
                  if(snapshot.hasData){
                    final data = snapshot.data!;
                    final messages = data['data'] as List<dynamic>;
                    return ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final data = messages[index];
                        final fileName = data['message_file'];
                        final duration = formatSecondsAsHHMM(data['duration']);
                        final status = data['is_new'] == 0 ? "played" : "not yet played";
                        final createdAt = data['created_at'];
                        return Dismissible(
                          key: UniqueKey(),
                          onDismissed: (direction) {
                            // deleteMessage(data['id']);
                            ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                   backgroundColor: Pallete.backgroundColor.withOpacity(0.8),
                                   content: const Text(
                                  "Message deleted successfully.",
                                  style: TextStyle(color: Pallete.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                )
                               ),
                            );
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
                              leading: const CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Icon(Icons.record_voice_over, color: Colors.white)
                              ),
                              title: Text(
                                "Message from ${data['source_extension']}",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Duration: $duration",
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min, // Avoid excessive space
                                children: [
                                  Text(
                                    status,
                                    style:  TextStyle(color: status == "played" ? Pallete.gradient1 : Pallete.gradient3, fontSize: 15),
                                  ),
                                  Text(
                                    createdAt,
                                    style:  const TextStyle(color: Pallete.gradient1 , fontSize: 15),
                                  ),
                                  // const Icon(Icons.play_arrow, color: Colors.white),
                                ],
                              ),
                              onLongPress: () async{
                                final link = await downloadLink(data['message_file']);
                                FileDownloader.downloadFile(
                                  url: link.replaceFirst("https", "http"),
                                  onProgress: (name, progress){
                                    print("Downloading $name");
                                  },
                                  onDownloadCompleted:(value){
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(
                                        "File saved in $value",
                                        style: const TextStyle(color: Pallete.gradient1, fontSize: 18, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      )),
                                    );
                                  },
                                  onDownloadError: (value){
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(
                                        value.toString(),
                                        style: const TextStyle(color: Pallete.gradient1, fontSize: 20, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      )),
                                    );
                                  }
                                );
                                // ScaffoldMessenger.of(context).showSnackBar(
                                //    SnackBar(content: Text(
                                //       link,
                                //     style: const TextStyle(color: Pallete.gradient1, fontSize: 20, fontWeight: FontWeight.bold),
                                //     textAlign: TextAlign.center,
                                //   )),
                                // );
                              },
                              onTap: () async{
                                final link = await downloadLink(data['message_file']);
                                final audioPlayer = AudioPlayer();
                                await audioPlayer.setUrl(link.replaceFirst("https","http"));
                                await audioPlayer.play();
                                setReadMessage(data['id']);
                                // ScaffoldMessenger.of(context).showSnackBar(
                                //   const SnackBar(content: Text(
                                //     "Played",
                                //     style: TextStyle(color: Pallete.gradient1, fontSize: 20, fontWeight: FontWeight.bold),
                                //     textAlign: TextAlign.center,
                                //   )),
                                // );
                                _syncMessages();
                              },
                            ),
                          ),
                        );
                      },
                    );

                  }else{
                    return const Text("No data", style: TextStyle(color: Colors.white),);
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
            // final response = await api.getMessages();
            // print("Load messages: ${response}.");
            // final link = await downloadLink("1722532754-805-819-00000124");

            // if(status.isGranted){


              // FileDownloader.cancelDownload(1227);
            // }

            // FileDownloader.cancelDownload(1222);
            // print("link : $link.");
            _syncMessages();
            // setState(() {
            //   messages = Future.value(recordings);
            // });
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(content: Text("Messages updated...")),
            // );
          } on PlatformException catch (e) {
            print("Failed to load messages: ${e.message}.");
          }
        },
        shape: const CircleBorder(),
        // backgroundColor: Colors.transparent,
        child: const Icon(Icons.refresh, color: Pallete.gradient4,),
      ),
    );
  }
}

formatSecondsAsHHMM(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$secs';
}