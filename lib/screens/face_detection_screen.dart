import 'dart:io';
import 'dart:math';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:lightman/models/ImageModel.dart';

const int MINIMAL_PERCENT = 70;

class FaceDetectionScreen extends StatefulWidget {
  static String id = '/face-detection';

  const FaceDetectionScreen({Key key}) : super(key: key);

  @override
  _FaceDetectionScreenState createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  ImageModel _image;
  bool _detectingFaces = false;
  bool _showProgressIndicator = true;
  List<Widget> _faceWidgets = [
    Text(
      'Detecting faces',
      style: TextStyle(fontSize: 20),
    ),
  ];

  void detectFaces() async {
    try {
      print('Begin of face detection');
      setState(() {
        _image = ModalRoute.of(context).settings.arguments;
      });
      final File imageFile = File(_image.path);
      final FirebaseVisionImage visionImage =
          FirebaseVisionImage.fromFile(imageFile);
      final FaceDetectorOptions faceDetectorOptions = FaceDetectorOptions(
        mode: FaceDetectorMode.accurate,
        enableClassification: true,
        enableTracking: true,
      );
      final FaceDetector faceDetector =
          FirebaseVision.instance.faceDetector(faceDetectorOptions);
      final List<Face> faces = await faceDetector.processImage(visionImage);
      faceDetector.close();
      setState(() {
        if (faces.length == 0) {
          _faceWidgets = [
            Column(
              children: <Widget>[
                Text(
                  'No faces were detected',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
          ];
          print('No faces were detected');
        } else {
          EmojiParser parser = EmojiParser();
          _faceWidgets = [];
          for (Face face in faces) {
            double rotation = pi;
            bool smiling =
                (face.smilingProbability * 100).round() > MINIMAL_PERCENT;
            bool rightEyeOpen =
                (face.rightEyeOpenProbability * 100).round() > MINIMAL_PERCENT;
            bool leftEyeOpen =
                (face.leftEyeOpenProbability * 100).round() > MINIMAL_PERCENT;
            String emoji = 'neutral_face';
            if (smiling) {
              if (rightEyeOpen && leftEyeOpen) {
                emoji = 'smiley';
              } else {
                emoji = 'smile';
              }
            } else if (rightEyeOpen && !leftEyeOpen) {
              emoji = 'wink';
              rotation = 0;
            } else if (!rightEyeOpen && leftEyeOpen) {
              emoji = 'wink';
            } else if (!rightEyeOpen && !leftEyeOpen) {
              emoji = 'expressionless';
            }
            Transform emojiWidget = Transform(
              transform: Matrix4.rotationY(rotation),
              alignment: Alignment.center,
              child: Text(
                parser.get(emoji).code,
                style: TextStyle(fontSize: 50),
              ),
            );
            _faceWidgets.add(emojiWidget);

            print('Tracking id: ${face.trackingId}');
            print('Smiling: $smiling');
            print('Left eye open: $leftEyeOpen');
            print('Right eye open: $rightEyeOpen');
          }
        }
      });
    } catch (e) {
      print(e);
    }
    setState(() {
      _showProgressIndicator = false;
    });
    print('End of face detection');
  }

  @override
  Widget build(BuildContext context) {
    if (!_detectingFaces) {
      setState(() {
        _detectingFaces = true;
      });
      detectFaces();
    }
    return Scaffold(
      appBar: AppBar(title: Text('Face Detection')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: SafeArea(
        child: (_showProgressIndicator)
            ? Center(child: CircularProgressIndicator())
            : Container(
                child: Column(
                  children: <Widget>[
                    SizedBox(height: 20),
                    Expanded(
                      child: Transform(
                        transform: Matrix4.rotationY(pi),
                        alignment: Alignment.center,
                        child: Image.file(File(_image.path)),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: TextDirection.ltr,
                      children: _faceWidgets,
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}
