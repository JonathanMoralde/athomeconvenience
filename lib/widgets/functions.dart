/*
FUNCTIONS:
1. User Type Checker
2. Time Picker
3. Image Picker
*/

import 'package:athomeconvenience/widgets/buttons.dart';
import 'package:athomeconvenience/widgets/star_rating.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

// ================ Fetch Service Provider Data ================
Map<String, dynamic> shopData = {};

Future<void> fetchShopData(BuildContext context, var shopUid) async {
  try {
    var querySnapshot = await FirebaseFirestore.instance
        .collection("service_provider")
        .where("uid", isEqualTo: shopUid)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      shopData = querySnapshot.docs.first.data();
    }
  } catch (e) {
    print(e);
  }
}

// ====================== User Type Checker ======================
Future<bool> isServiceProvider() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final CollectionReference serviceProviders =
      FirebaseFirestore.instance.collection('service_provider');

  try {
    var documentSnapshot = await serviceProviders.doc(uid).get();
    return documentSnapshot.exists;
  } catch (e) {
    print("Error checking UID existence: $e");
    return false;
  }
}

// =========================== Time Picker ===========================
TimeOfDay? selectedTimeST; //*
TimeOfDay? selectedTimeET; //*
TimePickerEntryMode entryMode = TimePickerEntryMode.dialOnly;
TextDirection textDirection = TextDirection.ltr;
MaterialTapTargetSize tapTargetSize = MaterialTapTargetSize.padded;
Orientation orientation = Orientation.portrait;
bool use24HourTime = false;
String startTime = '';
String buttonTextST = 'Start Time';
String buttonTextET = 'End Time';

Future<TimeOfDay?> showTimePickerFunction(
  BuildContext context,
  TimeOfDay? initialTime,
) async {
  return await showTimePicker(
    context: context,
    initialTime: initialTime ?? TimeOfDay.now(),
    initialEntryMode: entryMode,
    orientation: orientation,
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: Theme.of(context).copyWith(
          materialTapTargetSize: tapTargetSize,
        ),
        child: Directionality(
          textDirection: textDirection,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: use24HourTime,
            ),
            child: child!,
          ),
        ),
      );
    },
  );
}

// ======================= Image Picker =======================
class ImageHandler {
  static XFile? _image; //*
  static final ImagePicker picker = ImagePicker();

  static XFile? get currentImage => _image;

  static Future getImage(ImageSource media) async {
    var img = await picker.pickImage(source: media);

    if (img != null) {
      _image = img;
    }
  }

  static void uploadImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: const Text('Upload'),
          content: SizedBox(
            height: MediaQuery.of(context).size.height / 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    side: const BorderSide(
                      color: Colors.blueAccent,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    getImage(ImageSource.gallery);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.image,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      const Text('From Gallery'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    side: const BorderSide(
                      color: Colors.blueAccent,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    getImage(ImageSource.camera);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.camera,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      const Text('From Camera'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

void showToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.CENTER,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.grey,
    textColor: Colors.white,
    fontSize: 12.0,
  );
}

// ============================= Calculate Rating =============================
ratingCalculation(String spUid, double rating) async {
  DocumentReference<Map<String, dynamic>> documentReference =
      FirebaseFirestore.instance.collection('service_provider').doc(spUid);

  final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
      await documentReference.get();

  // Check if the 'rating' field already exists
  if (!documentSnapshot.data()!.containsKey('rating')) {
    // Update the document with the new field
    await documentReference.update({rating: 0.0});
  } else {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot documentSnapshot =
          await transaction.get(documentReference);

      final lastRatingForTheUser = documentSnapshot.data() as Map;
      String? newRating;
      double? ratingOfUser = double.tryParse(lastRatingForTheUser['rating']);

      rating = rating.ceilToDouble();

      if (ratingOfUser == 0.0) {
        newRating = rating.toString();
      } else {
        double calculateRating = (ratingOfUser! + rating) / 2;
        newRating = calculateRating.toString();
      }

      transaction.update(documentReference, {'rating': newRating});
    });
  }
}

// ======================== Rating Dialog ========================
class RateHandler {
  static void ratingHandler(BuildContext context, String shopUid) {
    double? selectedRating;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: const Text('Rate'),
          contentPadding: const EdgeInsets.all(8.0),
          content: SizedBox(
            height: 50,
            child: Center(
              child: StarRating(
                onRatingChange: (rating) {
                  selectedRating = rating;
                },
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.all(4.0),
          actions: [
            SizedBox(
              width: MediaQuery.of(context).size.width / 3,
              child: DialogButton(
                onPress: () {
                  Navigator.pop(context);
                },
                buttonText: 'Cancel',
                textColor: Colors.black,
              ),
            ),
            Container(
              height: 24, //adjust nalang height
              width: 1.0,
              color: Colors.black87,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 3,
              child: DialogButton(
                onPress: () {
                  if (selectedRating != null) {
                    ratingCalculation(shopUid, selectedRating!);
                    Navigator.pop(context);
                  } else {
                    showToast('Please input your rating.');
                  }
                },
                buttonText: 'Rate',
              ),
            ),
          ],
        );
      },
    );
  }
}

// ======================= trial: interaction dialog =======================
class InteractionHandler {
  static void showInteractionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: const Text('Share Location?'),
          content: const Text(
            'By sharing your location, the agreed-upon services will start.',
            softWrap: true,
          ),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.all(4.0),
          actions: [
            SizedBox(
              width: MediaQuery.of(context).size.width / 3,
              child: DialogButton(
                onPress: () {
                  Navigator.pop(context);
                },
                buttonText: 'Cancel',
                textColor: Colors.black,
              ),
            ),
            Container(
              height: 24, //adjust nalang height
              width: 1.0,
              color: Colors.black87,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 3,
              child: DialogButton(
                onPress: () {},
                buttonText: 'Share',
              ),
            ),
          ],
        );
      },
    );
  }
}
