import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lightman/components/rounded_button_icon.dart';
import 'package:lightman/models/ImageModel.dart';
import 'package:lightman/screens/face_detection_screen.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

class PhotoPickerScreen extends StatefulWidget {
  static String id = '/';

  final List<CameraDescription> cameras;

  const PhotoPickerScreen({
    Key key,
    @required this.cameras,
  }) : super(key: key);

  @override
  PhotoPickerScreenState createState() => PhotoPickerScreenState();
}

class PhotoPickerScreenState extends State<PhotoPickerScreen> {
  int _cameraIndex = 0;
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _cameraIndex = widget.cameras.length - 1;
    setCamera();
  }

  void setCamera() {
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.cameras[_cameraIndex],
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: NativeDeviceOrientationReader(builder: (context) {
        NativeDeviceOrientation orientation =
            NativeDeviceOrientationReader.orientation(context);

        int turns;
        switch (orientation) {
          case NativeDeviceOrientation.landscapeLeft:
            turns = -1;
            break;
          case NativeDeviceOrientation.landscapeRight:
            turns = 1;
            break;
          case NativeDeviceOrientation.portraitDown:
            turns = 2;
            break;
          default:
            turns = 0;
            break;
        }

        return SafeArea(
          child: FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the Future is complete, display the preview.
                return Stack(
                  alignment: AlignmentDirectional.bottomStart,
                  children: <Widget>[
                    Container(
                      child: RotatedBox(
                        quarterTurns: turns,
                        child: CameraPreview(_controller),
                      ),
                    ),
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          RoundedButtonIcon(
                            icon: Icons.switch_camera,
                            width: 48,
                            height: 48,
                            onTap: () {
                              setState(() {
                                if (_cameraIndex < widget.cameras.length - 1) {
                                  _cameraIndex++;
                                } else {
                                  _cameraIndex = 0;
                                }
                                setCamera();
                              });
                            },
                          ),
                          SizedBox(
                            width: 20,
                            height: 64,
                          ),
                          RoundedButtonIcon(
                            icon: Icons.camera_alt,
                            width: 56,
                            height: 56,
                            onTap: () async {
                              // Take the Picture in a try / catch block. If anything goes wrong,
                              // catch the error.
                              try {
                                // Ensure that the camera is initialized.
                                await _initializeControllerFuture;

                                // Construct the path where the image should be saved using the
                                // pattern package.
                                final path = join(
                                  // Store the picture in the temp directory.
                                  // Find the temp directory using the `path_provider` plugin.
                                  (await getTemporaryDirectory()).path,
                                  '${DateTime.now()}.png',
                                );

                                // Attempt to take a picture and log where it's been saved.
                                await _controller.takePicture(path);

                                // If the picture was taken, display it on a new screen.
                                Navigator.pushNamed(
                                  context,
                                  FaceDetectionScreen.id,
                                  arguments: ImageModel(path),
                                );
                              } catch (e) {
                                // If an error occurs, log the error to the console.
                                print(e);
                              }
                            },
                          )
                        ],
                      ),
                    )
                  ],
                );
              } else {
                // Otherwise, display a loading indicator.
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
        );
      }),
    );
  }
}
