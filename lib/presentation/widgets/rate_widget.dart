import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingWidget extends StatefulWidget {
  const RatingWidget({super.key});

  @override
  _RatingWidgetState createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  bool _loading = false;
  double _rating = 0.0;
  String _carNumberLetters = '';
  String _carNumberDigits = '';
  final TextEditingController _firstController = TextEditingController();
  final TextEditingController _secondController = TextEditingController();
  final TextEditingController _thirdController = TextEditingController();
  final TextEditingController _digitController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late FocusNode _firstFocusNode;
  late FocusNode _secondFocusNode;
  late FocusNode _thirdFocusNode;
  late FocusNode _digitFocusNode;

  Map<String, TextEditingController> _controllers = {};
  String? userEmail;
  String? userPhoneNumber;

  @override
  void initState() {
    fetchUserData();
    super.initState();
    _controllers = {
      'اول حرف': _firstController,
      'ثاني حرف': _secondController,
      'ثالث حرف': _thirdController,
      'الأرقام': _digitController,
    };

    _firstFocusNode = FocusNode();
    _secondFocusNode = FocusNode();
    _thirdFocusNode = FocusNode();
    _digitFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _firstFocusNode.dispose();
    _secondFocusNode.dispose();
    _thirdFocusNode.dispose();
    _digitFocusNode.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        userEmail = user.email;
        userPhoneNumber = user.phoneNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemSize: 50,
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {
              setState(() {
                _rating = rating;
              });
            },
          ),
          const SizedBox(height: 10),
          const Text(
            "ادخل نمرة السيارة",
            style: TextStyle(fontSize: 25),
          ),
          const SizedBox(height: 16.0),
          buildCarNumberFields(),
          const SizedBox(height: 16.0),
          _loading
              ? const CircularProgressIndicator(
                  color: Colors.blue,
                )
              : buildElevatedButton(),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  Row buildCarNumberFields() {
    List<String> labels = ['الأرقام', 'ثالث حرف', 'ثاني حرف', 'اول حرف'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: labels.map((label) {
        TextEditingController controller = _controllers[label]!;
        bool isDigit = label == 'الأرقام';
        int maxLength = isDigit ? 4 : 1;
        FocusNode focusNode;
        FocusNode? nextFocusNode;

        switch (label) {
          case 'اول حرف':
            focusNode = _firstFocusNode;
            nextFocusNode = _secondFocusNode;
            break;
          case 'ثاني حرف':
            focusNode = _secondFocusNode;
            nextFocusNode = _thirdFocusNode;
            break;
          case 'ثالث حرف':
            focusNode = _thirdFocusNode;
            nextFocusNode = _digitFocusNode;
            break;
          case 'الأرقام':
            focusNode = _digitFocusNode;
            break;
          default:
            focusNode = FocusNode();
        }

        return Expanded(
          child: buildTextField(
            label,
            isDigit: isDigit,
            maxLength: maxLength,
            controller: controller,
            focusNode: focusNode,
            nextFocusNode: nextFocusNode,
          ),
        );
      }).toList(),
    );
  }

  TextField buildTextField(
    String labelText, {
    bool isDigit = false,
    int maxLength = 1,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
  }) {
    return TextField(
      cursorColor: Colors.blue,
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.blue, fontSize: 12),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
      textAlign: TextAlign.center,
      keyboardType: isDigit ? TextInputType.number : TextInputType.text,
      onChanged: (value) {
        if (value.length == maxLength) {
          if (nextFocusNode != null) {
            _moveToNextField(nextFocusNode);
          }
        }
      },
      maxLength: maxLength,
      focusNode: focusNode,
      onEditingComplete: () {
        if (nextFocusNode != null) {
          _moveToNextField(nextFocusNode);
        } else {
          checkCarExistenceAndAddRating();
          FocusScope.of(context).requestFocus(_firstFocusNode);
        }
      },
    );
  }

 ElevatedButton buildElevatedButton() {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      minimumSize: const Size(double.infinity, 40),
    ),
    onPressed: () async {
      setState(() {
        _loading = true; // تحديث حالة التحميل لتبدأ
      });

      // Check if any of the other fields is empty
      bool otherFieldsEmpty = _secondController.text.trim().isEmpty ||
          _thirdController.text.trim().isEmpty ||
          _digitController.text.trim().isEmpty;

      // Check if the first field is empty
      bool firstFieldEmpty = _firstController.text.trim().isEmpty;

      if (!firstFieldEmpty || !otherFieldsEmpty) {
        _carNumberLetters = '';
        for (var entry in _controllers.entries) {
          _carNumberLetters += entry.value.text;
        }

        String carNumber = '$_carNumberLetters$_carNumberDigits';
        await checkCarExistenceAndAddRating(carNumber);
        _firstController.selection =
            const TextSelection(baseOffset: 0, extentOffset: 0);

        _firstFocusNode.requestFocus();
      } else {
        showValidationDialog();
      }

      setState(() {
        _loading = false; // تحديث حالة التحميل لتنتهي
      });
    },
    child: const Text(
      'ارسل التقييم ',
      style: TextStyle(color: Colors.white),
    ),
  );
}

  void _moveToNextField(FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }

 Future<void> checkCarExistenceAndAddRating([String? carNumber]) async {
  carNumber ??= '$_carNumberLetters$_carNumberDigits';

  try {
    var querySnapshot = await _firestore
        .collection('AllCars')
        .where('numberOfCar', isEqualTo: carNumber)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      var carDocument = querySnapshot.docs.first;
      var data = carDocument.data();
      List<dynamic>? ratedUserIds = data['userIds'];

      if (ratedUserIds != null &&
          ratedUserIds.contains(FirebaseAuth.instance.currentUser?.uid)) {
        _resetFields();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(_firstFocusNode);
        });
        return;
      }

      String userId = FirebaseAuth.instance.currentUser!.uid;

      if (data['userRatings'] != null &&
          data['userRatings'][userId] != null) {
        showUpdateRatingDialog(carDocument.id);
        return;
      }

      if (data.containsKey('rating')) {
        await updateExistingRating(carDocument.id);
      } else {
        await addRatingField(carDocument.id);
      }
    } else {
      showCarNotFoundErrorDialog(carNumber);
    }
  } catch (error) {
  }
}

  Future<void> updateExistingRating(String documentId) async {
    await _firestore.runTransaction((transaction) async {
      var documentSnapshot = await transaction.get(
        _firestore.collection('AllCars').doc(documentId),
      );

      if (documentSnapshot.exists) {
        Map<String, dynamic> data = documentSnapshot.data()!;
        double currentRating = data['rating'] ?? 0.0;
        int numberOfRatings = data['numberOfRatings'] ?? 0;
        Map<String, dynamic> userRatings =
            Map<String, dynamic>.from(data['userRatings']);

        double newUserRating = _rating;

        String userId = FirebaseAuth.instance.currentUser!.uid;

        if (userRatings.containsKey(userId)) {
          double oldUserRating = userRatings[userId];
          currentRating -= oldUserRating;
        } else {
          numberOfRatings++;
        }

        userRatings[userId] = newUserRating;

        double newTotalRating = currentRating + newUserRating;

        double newAverageRating = newTotalRating / numberOfRatings;

        transaction.update(
          _firestore.collection('AllCars').doc(documentId),
          {
            'rating': newTotalRating,
            'numberOfRatings': numberOfRatings,
            'averageRating': newAverageRating.toStringAsFixed(1),
            'userRatings': userRatings,
          },
        );

        showSuccessDialog(newAverageRating);
      }
    });
  }

  Future<void> addRatingField(String documentId) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await _firestore.collection('AllCars').doc(documentId).set({
        'rating': _rating,
        'numberOfRatings': 1,
        'averageRating': _rating.toStringAsFixed(1),
        'userRatings': {
          userId: _rating,
        },
      }, SetOptions(merge: true));
    } catch (error) {}

    showSuccessDialog(_rating);
  }

  void showUpdateRatingDialog(String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'تقييم سابق',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'لقد قمت بتقييم هذه السيارة مسبقًا، هل تريد تحديث التقييم؟',
            textAlign: TextAlign.right,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                updateExistingRating(documentId);
                Navigator.of(context).pop();
              },
              child: const Text(
                'نعم',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetFields();
              },
              child: const Text(
                'لا',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void showCarNotFoundErrorDialog(String carNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('خطأ'),
          content: Text('نمرة السيارة $carNumber غير موجودة.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetFields();
              },
              child: const Text(
                'حسنا',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void showSuccessDialog(double averageRating) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'تم بنجاح',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تمت إضافة التقييم بنجاح. تقييمك: ${_rating.toStringAsFixed(1)}',
              ),
              Text(
                'تمت إضافة التقييم بنجاح. المتوسط: ${averageRating.toStringAsFixed(1)}',
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetFields();
              },
              child: const Text(
                'حسنا',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void showValidationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('خطأ'),
          content: const Text('الرجاء إدخال نمرة السيارة والتقييم'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'حسنا',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void _resetFields() {
    setState(() {
      _rating = 0.0;
      _carNumberLetters = '';
      _carNumberDigits = '';
      for (var controller in _controllers.values) {
        controller.clear();
      }
    });
  }
}
