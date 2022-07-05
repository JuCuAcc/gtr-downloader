import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Gallery Storage',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool loading = false;
  double progress = 0.0;
  TextEditingController textEditingController = TextEditingController();

  final Dio dio = Dio();

  Future<bool> saveFile(String url, String filename) async {
    Directory? directory;

    try {
      if (Platform.isAndroid) {
        if (await _requestPermission(Permission.storage)) {
          print("in");
          directory = await getExternalStorageDirectory();

          String newPath = "";

          /// Path
          List<String> folders = directory!.path.split("/");

          for (int x = 1; x < folders.length; x++) {
            String folder = folders[x];
            if (folder != "Android") {
              newPath += "/" + folder;
            } else {
              break;
            }
          }
          newPath = newPath + "/GTRApp";
          directory = Directory(newPath);
          print(directory.path);
        } else {
          print("out");
          return false;
        }
      } else {
        if (await _requestPermission(Permission.photos)) {
          directory = await getTemporaryDirectory();
        } else {
          return false;
        }
      }
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      if (await directory.exists()) {
        File saveFile = File(directory.path + "/$filename");
        await dio.download(
          url,
          saveFile.path,
          options: Options(
            responseType: ResponseType.bytes,
              headers: {HttpHeaders.acceptEncodingHeader: "*"}),
          lengthHeader: Headers.contentEncodingHeader,
          onReceiveProgress: (downloaded, totalSize) {
            setState(() {
              /*    progress = downloaded / totalSize;*/
              progress = ((downloaded / totalSize) * 100);
              print("p" + progress.toString());
              print("d $downloaded");
              print("t $totalSize");
            });
          },
          deleteOnError: true,
        );
        dynamic value= dio.options.headers["content-length"];
        print("t $value");
        if (Platform.isIOS) {
          await ImageGallerySaver.saveFile(saveFile.path,
              isReturnPathOfIOS: true);
        }
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else if (!await permission.isGranted) {
      await permission.request();
      if (await permission.isGranted) {
        return true;
      } else {
        return false;
      }
    }
    return false;
  }

  downloadFile() async {
    setState(() {
      loading = true;
    });

    /// bool downloaded = await saveFile("https://youtu.be/8aW5gdRRn_U","video.mp4");
/*    bool downloaded = await saveFile(
        "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4", "video.mp4");*/

    var userUrl = textEditingController.text;

    List<String> fileExtension = userUrl.split(".");
    String singleExtension = "mp4";
    int len = fileExtension.length;

    for (int x = 0; x < len; x++) {
      int y = len - 1;
      singleExtension = fileExtension[y];
    }

    /* if (singleExtension != "") {

      }
      else
      {
        print("No File Extension Found!!!");
      }*/

    /// bool downloaded = await saveFile(userUrl, "Gtr_Downloader"+DateTime.now().toString()+".mp4");
    bool downloaded = await saveFile(userUrl,
        DateTime.now().toString() + "_Gtr_Downloader." + singleExtension);

    if (downloaded) {
      print("File Downloaded");
      textEditingController.text = "";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("File Downloaded Successfully",
              style: TextStyle(fontSize: 20, color: Colors.green))));
    } else {
      print("Problem Downloading File");
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /* appBar: AppBar(

        title: Text(widget.title),
      ),*/
      body: Padding(
        padding:
            const EdgeInsets.only(right: 30, left: 20, bottom: 30, top: 100),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: TextField(
                    controller: textEditingController,
                    decoration:
                        InputDecoration(labelText: 'Please, Enter the Url')),
              ),
              Center(
                child: loading
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: progress,
                        ),
                      )
                    : FlatButton.icon(
                        icon: Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                        ),
                        color: Colors.blue,
                        onPressed: downloadFile,
                        padding: const EdgeInsets.all(10),
                        label: Text(
                          "Download File",
                          style: TextStyle(color: Colors.white, fontSize: 25),
                        )),
              )
            ],
          ),
        ),
      ),
    );
  }
}
