import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:io';

import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DemoHome(),
    );
  }
}

class ThumbnailRequest {
  final String video;
  final String? thumbnailPath;
  final ImageFormat imageFormat;
  final int maxHeight;
  final int maxWidth;
  final int timeMs;
  final int quality;

  const ThumbnailRequest({
    required this.video,
    this.thumbnailPath,
    required this.imageFormat,
    required this.maxHeight,
    required this.maxWidth,
    required this.timeMs,
    required this.quality,
  });
}

class ThumbnailResult {
  final Image image;
  final int dataSize;
  final int height;
  final int width;
  const ThumbnailResult({
    required this.image,
    required this.dataSize,
    required this.height,
    required this.width,
  });
}

Future<ThumbnailResult> genThumbnail(ThumbnailRequest r) async {
  Uint8List bytes;
  final Completer<ThumbnailResult> completer = Completer();

  if (r.thumbnailPath != null) {
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: r.video,
      headers: {
        "USERHEADER1": "user defined header1",
        "USERHEADER2": "user defined header2",
      },
      thumbnailPath: r.thumbnailPath,
      imageFormat: r.imageFormat,
      maxHeight: r.maxHeight,
      maxWidth: r.maxWidth,
      timeMs: r.timeMs,
      quality: r.quality,
    );

    print("thumbnail file is located: $thumbnailPath");

    final file = File(thumbnailPath!);
    bytes = file.readAsBytesSync();
  } else {
    bytes = (await VideoThumbnail.thumbnailData(
      video: r.video,
      headers: {
        "USERHEADER1": "user defined header1",
        "USERHEADER2": "user defined header2",
      },
      imageFormat: r.imageFormat,
      maxHeight: r.maxHeight,
      maxWidth: r.maxWidth,
      timeMs: r.timeMs,
      quality: r.quality,
    ))!;
  }

  int imageDataSize = bytes.length;
  print("image size: $imageDataSize");

  final image = Image.memory(bytes);
  image.image
      .resolve(ImageConfiguration())
      .addListener(ImageStreamListener((ImageInfo info, bool _) {
    completer.complete(ThumbnailResult(
      image: image,
      dataSize: imageDataSize,
      height: info.image.height,
      width: info.image.width,
    ));
  }));
  return completer.future;
}

class GenThumbnailImage extends StatefulWidget {
  final ThumbnailRequest thumbnailRequest;

  const GenThumbnailImage({Key? key, required this.thumbnailRequest}) : super(key: key);

  @override
  _GenThumbnailImageState createState() => _GenThumbnailImageState();
}

class _GenThumbnailImageState extends State<GenThumbnailImage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThumbnailResult>(
      future: genThumbnail(widget.thumbnailRequest),
      builder: (BuildContext context, AsyncSnapshot<ThumbnailResult> snapshot) {
        if (snapshot.hasData) {
          final image = snapshot.data!.image;
          final width = snapshot.data!.width;
          final height = snapshot.data!.height;
          final dataSize = snapshot.data!.dataSize;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Center(
                child: Text(
                    "Image ${widget.thumbnailRequest.thumbnailPath == null ? 'data size' : 'file size'}: $dataSize, width:$width, height:$height"),
              ),
              Container(
                color: Colors.grey,
                height: 1.0,
              ),
              image,
            ],
          );
        } else if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(8.0),
            color: Colors.red,
            child: Text(
              "Error:\n${snapshot.error.toString()}",
            ),
          );
        } else {
          return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                    "Generating the thumbnail for: ${widget.thumbnailRequest.video}..."),
                SizedBox(
                  height: 10.0,
                ),
                CircularProgressIndicator(),
              ]);
        }
      },
    );
  }
}

class DemoHome extends StatefulWidget {
  @override
  _DemoHomeState createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  final _editNode = FocusNode();
  final _video = TextEditingController(
      text: "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4");
  ImageFormat _format = ImageFormat.JPEG;
  int _quality = 50;
  int _sizeH = 0;
  int _sizeW = 0;
  int _timeMs = 0;

  GenThumbnailImage? _futureImage;

  String? _tempDir;

  @override
  void initState() {
    super.initState();
    getTemporaryDirectory().then((d) => _tempDir = d.path);
  }

  @override
  Widget build(BuildContext context) {
    final _settings = <Widget>[
      // Additional settings widgets go here
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thumbnail Plugin example'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // UI components
          Expanded(
            child: Container(
              color: Colors.grey[300],
              child: Scrollbar(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    (_futureImage != null) ? _futureImage! : SizedBox(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () async {
              final video = await ImagePicker().pickVideo(source: ImageSource.camera);
              setState(() {
                _video.text = video?.path ?? '';
              });
            },
            child: Icon(Icons.videocam),
            tooltip: "Capture a video",
          ),
          FloatingActionButton(
            onPressed: () async {
              final video = await ImagePicker().pickVideo(source: ImageSource.gallery);
              setState(() {
                _video.text = video?.path ?? '';
              });
            },
            child: Icon(Icons.local_movies),
            tooltip: "Pick a video",
          ),
          FloatingActionButton(
            tooltip: "Generate a thumbnail",
            onPressed: () async {
              setState(() {
                _futureImage = GenThumbnailImage(
                  thumbnailRequest: ThumbnailRequest(
                    video: _video.text,
                    thumbnailPath: _tempDir,
                    imageFormat: _format,
                    maxHeight: _sizeH,
                    maxWidth: _sizeW,
                    timeMs: _timeMs,
                    quality: _quality,
                  ),
                );
              });
            },
            child: const Text("File"),
          ),
        ],
      ),
    );
  }
}
