

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Resources/DatabaseConnection.dart';
import 'package:rise/Resources/Pallete.dart';
import 'package:vibration/vibration.dart';

import '../../Controllers/StorageController.dart';



class CallHistoryWidget extends StatefulWidget {
  const CallHistoryWidget({super.key});

  @override
  State<CallHistoryWidget> createState() => _CallHistoryWidgetState();
}

class _CallHistoryWidgetState extends State<CallHistoryWidget> {
  late Future<List<CallHistory>> futureCallHistories;

  @override
  void initState() {
    // TODO: implement initState
    futureCallHistories = fetchCallHistories();
    super.initState();
  }

  Future<List<CallHistory>> fetchCallHistories() async {

    final callHistoryMaps = await riseDatabase.selectAllCallHistories();
    return callHistoryMaps.map((map) => CallHistory.fromMap(map)).toList();
  }

  @override
  void dispose(){
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CallHistory>>(
      future: futureCallHistories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No call history found.'));
        } else {
          return CallHistoryList(callHistories: snapshot.data!);
        }
      },
    );
  }
}



class CallHistoryList extends StatelessWidget {
  final List<CallHistory> callHistories;

  CallHistoryList({required this.callHistories});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: callHistories.length,
      itemBuilder: (context, index) {
        final call = callHistories[index];
        return  ListTile(
          leading: const CircleAvatar(
            backgroundColor: Pallete.gradient4,
            child: Icon(
              Icons.cabin,
              size: 24, // Sets the size of the icon
              color: Pallete.white, // Sets the color of the icon
            ),
          ),
          title: Text(call.extension, style: const TextStyle(color: Pallete.white),),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${call.direction} • ${call.dateTime}'),
            ],
          ),
          trailing: IconButton(
              onPressed: () async{
                Vibration.vibrate(duration: 100);
                final androidHost = await storageController.getData("androidHost");
                if (androidHost == null && androidHost.isEmpty) {
                  await api.getAndroidHost();
                }

                // janus.makeCall(inputNumber, androidHost);
                await storageController.storeData("caller", call.extension);
                FlutterBackgroundService().invoke('makeCall',{
                  'inputNumber' : call.extension,
                  'androidHost' : androidHost,
                });
              },
              icon:  const Icon(
                Icons.call,
                color: Colors.blue,
              ),
          )

        );
      },
    );
  }
}


class CallHistory {
  final int id;
  final String extension;
  final String direction;
  final String dateTime;

  CallHistory({
    required this.id,
    required this.extension,
    required this.direction,
    required this.dateTime,
  });

  factory CallHistory.fromMap(Map<String, dynamic> map) {
    return CallHistory(
      id: map['id'],
      extension: map['extension'],
      direction: map['direction'],
      dateTime: map['date_time'],
    );
  }
}
