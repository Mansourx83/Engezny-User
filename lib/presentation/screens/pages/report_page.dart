import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gradution_project2/presentation/screens/components/drop_down.dart';
import 'package:gradution_project2/presentation/screens/pages/choselogin.dart';
import 'package:gradution_project2/presentation/widgets/constant_widget.dart';
import 'package:intl/intl.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  User? _user;
  String? userEmail;
  String? userPhoneNumber;

  final TextEditingController _firstController = TextEditingController();
  final TextEditingController _secondController = TextEditingController();
  final TextEditingController _thirdController = TextEditingController();
  final TextEditingController _digitController = TextEditingController();
  final TextEditingController _complaintController = TextEditingController();

  final FocusNode _firstFocusNode = FocusNode();
  final FocusNode _secondFocusNode = FocusNode();
  final FocusNode _thirdFocusNode = FocusNode();
  final FocusNode _digitFocusNode = FocusNode();

  List<QueryDocumentSnapshot> stationName = [];
  Map<String, List<QueryDocumentSnapshot>> lineAvailableMap = {};
  String? selectedCity;
  String? selectedLine;
  bool _isLoading = false;
  bool isViewed = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    fetchUserData();
    fetchUserData().then((_) {
      Future.delayed(Duration.zero, () {
        print(userEmail);
        print(userPhoneNumber);
      });
    });
    getStationName().then((_) {
      fetchLineDataForEachStation();
    });
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
      if (mounted) {
        setState(() {
          userEmail = user.email;
          userPhoneNumber = user.phoneNumber;
        });
      }
    }
  }

  Future<void> fetchData() async {
    await getStationName();
    await fetchLineDataForEachStation();
  }

  Future<void> getStationName() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection("المواقف").get();
    stationName = querySnapshot.docs;
  }

  Future<void> fetchLineDataForEachStation() async {
    if (stationName.isNotEmpty) {
      for (var station in stationName) {
        await fetchDataForSelectedCity(station.id);
      }
    }
  }

  Future<void> fetchDataForSelectedCity(String cityId) async {
    try {
      final lineData = await getLineAvailable(cityId);
      if (mounted) {
        lineAvailableMap[cityId] = lineData;
        setState(() {});
      }
    } catch (e) {
      _showAlertDialog(context, "هناك مشكلة");
    }
  }

  Future<List<QueryDocumentSnapshot>> getLineAvailable(String stationId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection("المواقف")
          .doc(stationId)
          .collection("line")
          .get();

      return querySnapshot.docs;
    } catch (e) {
      return [];
    }
  }

  Future<void> _sendComplaint() async {
    print(
        'Before sending: userEmail = $userEmail, userPhoneNumber = $userPhoneNumber');

    setState(() {
      _isLoading = true;
    });

    String first = _firstController.text.trim();
    String second = _secondController.text.trim();
    String third = _thirdController.text.trim();
    String digit = _digitController.text.trim();
    String carNumber = '$first$second$third$digit';
    String complaint = _complaintController.text.trim();
    if (userEmail == null && userPhoneNumber == null) {
      _showAlertDialog(context,
          'يجب توفير البريد الإلكتروني أو رقم الهاتف قبل إرسال الشكوى.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (second.isEmpty ||
        third.isEmpty ||
        digit.isEmpty ||
        complaint.isEmpty ||
        selectedCity == null ||
        selectedLine == null) {
      _showAlertDialog(
          context, 'الرجاء ادخال جميع نمرة السيارة والشكوى واختيار المواقف');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final carQuerySnapshot = await FirebaseFirestore.instance
          .collection('AllCars')
          .where('numberOfCar', isEqualTo: carNumber)
          .get();

      if (carQuerySnapshot.docs.isEmpty) {
        _clearInputFields();
        _resetDropdownValues();
        Future.delayed(Duration.zero, () {
          FocusScope.of(context).requestFocus(_firstFocusNode);
        });
        _showAlertDialog(context, "نمرة السيارة غير صحيحة");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      var selectedStationId = stationName
          .firstWhere((element) => element['name'] == selectedCity)['id'];
      var stationIds = carQuerySnapshot.docs
          .map((doc) => doc['stationId'].toString())
          .toList();
      if (!stationIds.contains(selectedStationId)) {
        _clearInputFields();
        _resetDropdownValues();
        Future.delayed(Duration.zero, () {
          FocusScope.of(context).requestFocus(_firstFocusNode);
        });
        _showAlertDialog(context, "السيارة لم تتم تسجيلها في هذا الموقف");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      CollectionReference messages =
          FirebaseFirestore.instance.collection('messages');

      DocumentReference newDocRef = await messages.add({
        'carNumber': carNumber,
        'complaint': complaint,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _user?.uid,
        'userName': (userEmail?.isEmpty ?? true) ? userPhoneNumber : userEmail,
        'startingLocation': selectedCity,
        'endingLocation': selectedLine,
        'stationId': selectedStationId,
        "isViewed": isViewed,
      });

      String documentId = newDocRef.id;
      await newDocRef.update({'documentId': documentId});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'تم إرسال الشكوى بنجاح',
              textAlign: TextAlign.end,
            )),
      );

      _clearInputFields();
      _resetDropdownValues();
      Future.delayed(Duration.zero, () {
        FocusScope.of(context).requestFocus(_firstFocusNode);
      });
    } catch (e) {
      _showAlertDialog(
          context, 'حدث خطأ أثناء إرسال الشكوى، يرجى المحاولة مرة أخرى');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetDropdownValues() {
    setState(() {
      selectedCity = null;
      selectedLine = null;
    });
  }

  void _showAlertDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Text(message, textAlign: TextAlign.end),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Center(
                  child: Text(
                'حسنا',
                style: TextStyle(color: Colors.blue),
              )),
            ),
          ],
        );
      },
    );
  }

  void _clearInputFields() {
    if (mounted) {
      setState(() {
        _firstController.clear();
        _secondController.clear();
        _thirdController.clear();
        _digitController.clear();
        _complaintController.clear();
        selectedCity = null;
        selectedLine = null;
      });
    }
  }

  DateTime? _getTimestamp(Map<String, dynamic> messageData) {
    final timestamp = messageData['timestamp'];
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null;
  }

  Widget _buildMessageCard(Map<String, dynamic> messageData) {
    DateTime? timestamp = _getTimestamp(messageData);

    if (timestamp != null) {
      String formattedTime = DateFormat('HH:mm').format(timestamp);
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildMessageText(
                  'رقم السيارة:', messageData['carNumber'].toString()),
              _buildMessageText(
                  'محتوى الشكوى:', messageData['complaint'].toString()),
              _buildMessageText(
                  "ركبت من:", messageData['startingLocation'].toString()),
              _buildMessageText(
                  'رايح الي:', messageData['endingLocation'].toString()),
              _buildMessageText('الوقت:', formattedTime),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  messageData["isViewed"]
                      ? const Row(
                          children: [Text("تمت المشاهده"), Icon(Icons.check)],
                        )
                      : const Text("لم تتم المشاهده"),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _deleteComplaint(messageData);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _buildMessageText(String label, String value) {
    return Text(
      '$label $value',
      style: const TextStyle(fontSize: 18),
    );
  }

  Widget _buildCarNumberInput() {
    return Column(children: [
      Row(
        children: [
          _buildTextField('الارقام', _digitController, _digitFocusNode, 4,
              TextInputType.number),
          const SizedBox(width: 8),
          _buildTextField('ثالث حرف', _thirdController, _thirdFocusNode, 1,
              TextInputType.text),
          const SizedBox(width: 8),
          _buildTextField('ثاني حرف', _secondController, _secondFocusNode, 1,
              TextInputType.text),
          const SizedBox(width: 8),
          _buildTextField('اول حرف', _firstController, _firstFocusNode, 1,
              TextInputType.text),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Flexible(
            child: SizedBox(
              width: 200,
              child: MyDropdownButton(
                itemPrefix: 'موقف',
                hint: 'اختر الموقف',
                stationName: stationName
                    .map<String>((doc) => doc['name'] as String)
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCity = newValue;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (var station in stationName ?? [])
            if (selectedCity == station["name"])
              Flexible(
                child: MyDropdownButton(
                  itemPrefix: 'خط',
                  hint: 'اختر الخط',
                  stationName: lineAvailableMap[station.id]
                          ?.map<String>((doc) => doc['nameLine'] as String)
                          .toList() ??
                      [],
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedLine = newValue;
                    });
                  },
                ),
              )
        ],
      )
    ]);
  }

  void _checkCarExistence() async {
    String first = _firstController.text.trim();
    String second = _secondController.text.trim();
    String third = _thirdController.text.trim();
    String digit = _digitController.text.trim();
    String carNumber = '$first$second$third$digit';

    try {
      final carQuerySnapshot = await FirebaseFirestore.instance
          .collection('AllCars')
          .where('numberOfCar', isEqualTo: carNumber)
          .get();

      if (mounted && carQuerySnapshot.docs.isNotEmpty) {
        // السيارة موجودة
        for (var doc in carQuerySnapshot.docs) {
          var stationId = doc['stationId'];
          print('stationId for car $carNumber: $stationId');
        }
      } else {
        // السيارة غير موجودة
        print('السيارة غير موجودة');
      }
    } catch (e) {
      print('حدث خطأ أثناء البحث عن السيارة: $e');
    }
  }

  Widget _buildTextField(String labelText, TextEditingController controller,
      FocusNode focusNode, int maxLength, TextInputType keyboardType) {
    return Expanded(
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        focusNode: focusNode,
        onChanged: (value) {
          _checkCarExistence(); // تنفيذ الكود عند تغيير القيمة
          if (value.length == maxLength) {
            _moveToNextField(focusNode, maxLength);
          }
        },
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.blue, fontSize: 10),
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
        keyboardType: keyboardType,
        maxLength: maxLength,
        onEditingComplete: () {
          _moveToNextField(focusNode, maxLength);
        },
      ),
    );
  }

  Future<void> printStationIdForCar(String carNumber) async {
    try {
      var carSnapshot = await FirebaseFirestore.instance
          .collection('AllCars')
          .where('numberOfCar', isEqualTo: carNumber)
          .get();

      if (carSnapshot.docs.isNotEmpty) {
        var stationId = carSnapshot.docs.first['stationId'];
        print('stationId for car $carNumber: $stationId');
      } else {
        print('السيارة غير موجودة');
      }
    } catch (e) {
      print('حدث خطأ أثناء البحث عن السيارة: $e');
    }
  }

  void _moveToNextField(FocusNode focusNode, int maxLength) {
    FocusNode? nextFocusNode;
    if (focusNode == _firstFocusNode) {
      nextFocusNode = _secondFocusNode;
    } else if (focusNode == _secondFocusNode) {
      nextFocusNode = _thirdFocusNode;
    } else if (focusNode == _thirdFocusNode) {
      nextFocusNode = _digitFocusNode;
    }

    if (nextFocusNode != null) {
      FocusScope.of(context).requestFocus(nextFocusNode);
    }
  }

  Widget _buildComplaintInput() {
    return TextField(
      maxLines: 2,
      controller: _complaintController,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        labelText: 'اضف شكوتك ',
        labelStyle: const TextStyle(color: Colors.blue),
      ),
    );
  }

  Widget _buildSendComplaintButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          onPressed: () {
            _sendComplaint();
            printStationIdForCar(_buildCarNumber());
          },
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'ارسل الشكوي',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
        ),
      ),
    );
  }

  String _buildCarNumber() {
    String first = _firstController.text.trim();
    String second = _secondController.text.trim();
    String third = _thirdController.text.trim();
    String digit = _digitController.text.trim();
    return '$first$second$third$digit';
  }

  Widget _buildSentComplaints() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const Text(
          'الشكاوي المرسلة',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('messages')
                .where('userId', isEqualTo: _user?.uid)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (BuildContext context,
                AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
              if (snapshot.hasError) {
                print("error: ${snapshot.error}");
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.blue));
              }

              final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                  documents = snapshot.data?.docs ?? [];

              return ListView.builder(
                itemCount: documents.length,
                itemBuilder: (BuildContext context, int index) {
                  final Map<String, dynamic> messageData =
                      documents[index].data();

                  return _buildMessageCard(messageData);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _deleteComplaint(Map<String, dynamic> messageData) async {
    try {
      String documentId = messageData['documentId'];

      CollectionReference messagesRef =
          FirebaseFirestore.instance.collection('messages');

      QuerySnapshot<Map<String, dynamic>> querySnapshot = await messagesRef
          .where('documentId', isEqualTo: documentId)
          .get() as QuerySnapshot<Map<String, dynamic>>;

      for (QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot
          in querySnapshot.docs) {
        await documentSnapshot.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'تم حذف الشكوى بنجاح',
              textAlign: TextAlign.end,
            )),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.red,
            content:
                Text('حدث خطأ أثناء حذف الشكوى', textAlign: TextAlign.end)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const ConstantWidget(),
            const SizedBox(
              height: 20,
            ),
            if (_user == null) // التحقق من وجود المستخدم
              Column(
                children: [
                  const Text(
                    "لا يمكنك ارسال شكوي يجب عليك تسجيل الدخول اولا لارسال شكوتك",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) {
                                  return const ChoseLogin();
                                }),
                                (route) => false,
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                Text(
                                  "تسجيل الدخول",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Text(
                      "ادخل نمرة السيارة",
                      style: TextStyle(fontSize: 25),
                    ),
                  ),
                  _buildCarNumberInput(),
                  const SizedBox(height: 16),
                  _buildComplaintInput(),
                  const SizedBox(height: 16),
                  _buildSendComplaintButton(),
                  const SizedBox(height: 32),
                  _buildSentComplaints(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
