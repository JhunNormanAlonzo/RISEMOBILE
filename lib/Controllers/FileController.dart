import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/MyToast.dart';

class FileController {
  download(vmAudio, context) async{
    final base = await storageController.getData("base");
    FileDownloader.downloadFile(url:'$base/voicemail/messages/$vmAudio.wav',
        onProgress:(name,progress){

        },
        onDownloadCompleted:(value){
          toast.success(context, "Downloaded file stored in $value");


        },
        onDownloadError:(value){


    });
  }
}

final fileController = FileController();