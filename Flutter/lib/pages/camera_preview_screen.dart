import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:volume_watcher/volume_watcher.dart';

class CameraPreviewScreen extends StatefulWidget {
  final CameraController controller;

  const CameraPreviewScreen({Key? key, required this.controller}) : super(key: key);

  @override
  _CameraPreviewScreenState createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  bool _isVolumeButtonPressed = false;

  @override
  void initState() {
    super.initState();
    VolumeWatcher.addListener(_onVolumeButtonPressed);
    widget.controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    VolumeWatcher.removeListener(_onVolumeButtonPressed);
    widget.controller.dispose();
    super.dispose();
  }

  void _onVolumeButtonPressed(int? volume) async {
    if (volume != null && volume > 0 && !_isVolumeButtonPressed) {
      setState(() {
        _isVolumeButtonPressed = true;
      });
      await _captureImage();
      setState(() {
        _isVolumeButtonPressed = false;
      });
    }
  }

  Future<void> _captureImage() async {
    try {
      final image = await widget.controller.takePicture();
      Navigator.pop(context, image);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(widget.controller),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: FloatingActionButton(
                child: Icon(Icons.camera),
                onPressed: _captureImage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:volume_watcher/volume_watcher.dart';

// class CameraPreviewScreen extends StatefulWidget {
//   final CameraController controller;

//   const CameraPreviewScreen({Key? key, required this.controller}) : super(key: key);

//   @override
//   _CameraPreviewScreenState createState() => _CameraPreviewScreenState();
// }

// class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
//   bool _isVolumeButtonPressed = false;

//   @override
//   void initState() {
//     super.initState();
//     VolumeWatcher.addListener(_onVolumeButtonPressed);
//     widget.controller.initialize().then((_) {
//       if (!mounted) {
//         return;
//       }
//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     VolumeWatcher.removeListener(_onVolumeButtonPressed);
//     widget.controller.dispose();
//     super.dispose();
//   }

//   void _onVolumeButtonPressed(double volume) async {
//     if (volume > 0 && !_isVolumeButtonPressed) {
//       setState(() {
//         _isVolumeButtonPressed = true;
//       });
//       await _captureImage();
//       setState(() {
//         _isVolumeButtonPressed = false;
//       });
//     }
//   }

//   Future<void> _captureImage() async {
//     try {
//       final image = await widget.controller.takePicture();
//       Navigator.pop(context, image);
//     } catch (e) {
//       print(e);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!widget.controller.value.isInitialized) {
//       return Container();
//     }
//     return Scaffold(
//       body: Stack(
//         children: [
//           CameraPreview(widget.controller),
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: FloatingActionButton(
//                 child: Icon(Icons.camera),
//                 onPressed: _captureImage,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }







// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'dart:developer' as developer;
// import 'package:volume_watcher/volume_watcher.dart';
// class CameraPreviewScreen extends StatefulWidget {
//   final CameraController controller;

//   const CameraPreviewScreen({Key? key, required this.controller})
//       : super(key: key);
//   @override
//   CameraPreviewScreenState createState() => CameraPreviewScreenState();
// }

// class CameraPreviewScreenState extends State<CameraPreviewScreen> {
//   late CameraController _controller;
//   late Future<void> _initializeControllerFuture;
//   bool _isVolumeButtonPressed = false;

//   @override
//    void initState() {
//     super.initState();
//     VolumeWatcher.addListener(_onVolumeButtonPressed);
//     widget.controller.initialize().then((_) {
//       if (!mounted) {
//         return;
//       }
//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     VolumeWatcher.removeListener(_onVolumeButtonPressed);
//     widget.controller.dispose();
//     super.dispose();
//   }

//     void _onVolumeButtonPressed(VolumeWatcherEvent event) async {
//     if (event.isVolumeUp && !_isVolumeButtonPressed) {
//       setState(() {
//         _isVolumeButtonPressed = true;
//       });
//       await _captureImage();
//       setState(() {
//         _isVolumeButtonPressed = false;
//       });
//     }
//   }

//     Future<void> _captureImage() async {
//     try {
//       final image = await widget.controller.takePicture();
//       Navigator.pop(context, image);
//     } catch (e) {
//       print(e);
//     }
//   }

//   // Future<void> _takePicture() async {
//   //   try {
//   //     await _initializeControllerFuture;

//   //     XFile picture = await _controller.takePicture();

//   //     Navigator.pop(context, picture);
//   //   } catch (e) {
//   //     developer.log(e.toString());
//   //   }
//   // }

//  @override
//   Widget build(BuildContext context) {
//     if (!widget.controller.value.isInitialized) {
//       return Container();
//     }
//     return Scaffold(
//       body: Stack(
//         children: [
//           CameraPreview(widget.controller),
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: FloatingActionButton(
//                 child: Icon(Icons.camera),
//                 onPressed: _captureImage,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
