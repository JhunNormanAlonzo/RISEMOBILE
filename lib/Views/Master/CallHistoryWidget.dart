

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:provider/provider.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Resources/DatabaseConnection.dart';
import 'package:rise/Resources/Pallete.dart';
import 'package:rise/Resources/Provider/NavigationProvider.dart';
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
    super.initState();
    futureCallHistories = fetchCallHistories();
    print("test");
  }

  Future<List<CallHistory>> fetchCallHistories() async {

    final callHistoryMaps = await riseDatabase.selectAllCallHistories();
    return callHistoryMaps.map((map) => CallHistory.fromMap(map)).toList();
  }


  Future<void> refreshData() async {
    setState(() {
      futureCallHistories = fetchCallHistories();
    });
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
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Pallete.gradient3),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No call history found.',
                  style: TextStyle(
                    color: Pallete.white.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: refreshData,
                  child: const Text("Refresh"),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            body: ListView.builder(
              itemCount: snapshot.data?.length,
              itemBuilder: (context, index) {
                final call = snapshot.data![index];
                return Dismissible(
                  key: UniqueKey(),
                  onDismissed: (direction) async {
                    final mailboxNumber = await storageController.getData("mailboxNumber");
                    final callHistoryId = call.id;
                    debugPrint("Mailbox Number $mailboxNumber is deleting call history id : $callHistoryId");
                    await riseDatabase.deleteHistory(callHistoryId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Pallete.backgroundColor.withOpacity(0.8),
                          content: const Text(
                            "Deleted successfully.",
                            style: TextStyle(color: Pallete.white, fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    refreshData(); // Refresh the data after deletion
                  },
                  background: Container(
                    color: Pallete.gradient4.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: AlignmentDirectional.center,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Pallete.gradient4,
                      child: Icon(
                        call.direction == "outgoing" ? Icons.call_made : Icons.call_received,
                        size: 24,
                        color: Pallete.white,
                      ),
                    ),
                    title: Text(
                      call.extension,
                      style: const TextStyle(color: Pallete.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${call.direction} • ${call.dateTime}',
                          style: TextStyle(color: Pallete.white.withOpacity(0.6)),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      onPressed: () async {
                        Vibration.vibrate(duration: 100);
                        final androidHost = await storageController.getData("androidHost");
                        if (androidHost == null || androidHost.isEmpty) {
                          await api.getAndroidHost();
                        }
                        await storageController.storeData("caller", call.extension);
                        FlutterBackgroundService().invoke('makeCall', {
                          'inputNumber': call.extension,
                          'androidHost': androidHost,
                        });
                      },
                      icon: const Icon(
                        Icons.call,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                );
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                bool? shouldClear = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Are you sure?'),
                      content: const Text('The history will be deleted permanently.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false); // Don't clear history
                          },
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await riseDatabase.clearHistory();
                            debugPrint("History Cleared");
                            setState(() {
                              refreshData();
                            });
                            Navigator.of(context).pop(true); // Clear history
                          },
                          child: const Text('Yes'),
                        ),
                      ],
                    );
                  },
                );

                if (shouldClear == true) {
                  refreshData(); // Refresh the data after clearing history
                }
              },
              shape: const CircleBorder(),
              backgroundColor: Pallete.white.withOpacity(0.8),
              child: const Icon(Icons.delete, color: Pallete.gradient4),
            ),
          );
        }
      },
    );
  }
}



// class CallHistoryList extends StatefulWidget {
//   final List<CallHistory> callHistories;
//
//   const CallHistoryList({super.key, required this.callHistories});
//
//   @override
//   State<CallHistoryList> createState() => _CallHistoryListState();
// }
//
// class _CallHistoryListState extends State<CallHistoryList> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: ListView.builder(
//         itemCount: widget.callHistories.length,
//         itemBuilder: (context, index) {
//           final call = widget.callHistories[index];
//           return  Dismissible(
//               key: UniqueKey(),
//               onDismissed: (direction)async{
//                 final mailboxNumber = await storageController.getData("mailboxNumber");
//                 final callHistoryId = call.id;
//                 debugPrint("Mailbox Number $mailboxNumber is deleting call history id : $callHistoryId");
//                 await riseDatabase.deleteHistory(callHistoryId);
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       backgroundColor: Pallete.backgroundColor.withOpacity(0.8),
//                       content: const Text(
//                         "Deleted successfully.",
//                         style: TextStyle(color: Pallete.white, fontSize: 20, fontWeight: FontWeight.bold),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   );
//                 }
//               },
//               background: Container(
//                 color: Pallete.gradient4.withOpacity(0.4),
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 alignment: AlignmentDirectional.center,
//                 child: const Icon(
//                   Icons.delete,
//                   color: Colors.white,
//                 ),
//               ),
//               child: ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: Pallete.gradient4,
//                     child: Icon(call.direction == "outgoing" ? Icons.call_made : Icons.call_received,
//                       size: 24, // Sets the size of the icon
//                       color: Pallete.white, // Sets the color of the icon
//                     ),
//                   ),
//                   title: Text(call.extension, style: const TextStyle(color: Pallete.white),),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('${call.direction} • ${call.dateTime}', style: TextStyle(color: Pallete.white.withOpacity(0.6)),),
//                     ],
//                   ),
//                   trailing: IconButton(
//                     onPressed: () async{
//                       Vibration.vibrate(duration: 100);
//                       final androidHost = await storageController.getData("androidHost");
//                       if (androidHost == null && androidHost.isEmpty) {
//                         await api.getAndroidHost();
//                       }
//
//                       // janus.makeCall(inputNumber, androidHost);
//                       await storageController.storeData("caller", call.extension);
//                       FlutterBackgroundService().invoke('makeCall',{
//                         'inputNumber' : call.extension,
//                         'androidHost' : androidHost,
//                       });
//                     },
//                     icon:  const Icon(
//                       Icons.call,
//                       color: Colors.blue,
//                     ),
//                   )
//               )
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async{
//           return await showDialog(
//               context: context,
//               builder: (BuildContext context){
//                 return AlertDialog(
//                   title: const Text('Are you sure?'),
//                   content:  const Text('The history will be deleted permanently.'),
//                   actions: [
//                     TextButton(
//                       onPressed: () {
//                         Navigator.of(context).pop(false); // Don't exit app
//                       },
//                       child: const Text('No'),
//                     ),
//                     TextButton(
//                       onPressed: () async {
//                         await riseDatabase.clearHistory();
//                         debugPrint("History Cleared");
//                       },
//                       child: const Text('Yes'),
//                     ),
//                   ],
//                 );
//               }
//           );
//
//         },
//         shape: const CircleBorder(),
//         backgroundColor: Pallete.white.withOpacity(0.8),
//         child: const Icon(Icons.delete, color: Pallete.gradient4),
//       ),
//     );
//   }
// }


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
