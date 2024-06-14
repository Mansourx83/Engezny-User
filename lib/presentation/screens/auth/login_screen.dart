import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradution_project2/bussines_logic/cubit/phone_auth_cubit.dart';
import 'package:gradution_project2/constant/my_color.dart';
import 'package:gradution_project2/constant/strings.dart';
import 'package:gradution_project2/presentation/widgets/constant_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late String phoneNumber;

  GlobalKey<FormState> phoneFormKey = GlobalKey();

  TextEditingController phoneController = TextEditingController();

  bool isLoading = false;

  Widget _buildFormFeild() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(
              vertical: 22,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "${generateCountryFlag()} +20",
              style: const TextStyle(fontSize: 18, letterSpacing: 1),
            ),
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: TextFormField(
              maxLength: 11,
              controller: phoneController,
              style: const TextStyle(fontSize: 18, letterSpacing: 2),
              autofocus: true,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: " رقم الهاتف",
                  labelStyle: TextStyle(color: Colors.blue),
                  focusColor: Colors.blue,
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2)),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue))),
              validator: (value) {
                if (value!.isEmpty) {
                  return "ادخل رقم هاتفك";
                } else if (value.length < 11) {
                  return "اكمل باقي الرقم";
                } else if (!isValidPhoneNumber(value)) {
                  return "الرقم غير صالح";
                }

                return null;
              },
              onSaved: (value) {
                phoneNumber = value!;
              },
              autofillHints: const [AutofillHints.telephoneNumber],
            ),
          ),
        ),
      ],
    );
  }

  String generateCountryFlag() {
    String countryCode = "eg";

    String flag = countryCode.toUpperCase().replaceAllMapped(RegExp(r"[A-Z]"),
        (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397));
    return flag;
  }

  bool isValidPhoneNumber(String value) {
    return RegExp(r'^01\d{9}$').hasMatch(value);
  }

  Future<void> _register(BuildContext context) async {
    if (!phoneFormKey.currentState!.validate()) {
      Navigator.pop(context);
    } else {
      Navigator.pop(context);
      phoneFormKey.currentState!.save();
      BlocProvider.of<PhoneAuthCubit>(context).submitPhoneNumber(phoneNumber);
    }
  }

  Widget _buildNextButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if ((phoneFormKey.currentState!.validate())) {
          checkInternetConnection();
          showProgressIndecator(context);
          _register(context);
        }
      },
      style: ElevatedButton.styleFrom(
          backgroundColor: MyColor.blue,
          minimumSize: const Size(double.infinity, 50)),
      child: const Text(
        "التالي",
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }

  void showProgressIndecator(BuildContext context) {
    AlertDialog alertDialog = AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Center(
          child: Column(
              children: [
      Lottie.asset("asset/images/splash.json"),
      const CircularProgressIndicator(
        color: Colors.blue,
      ),
              ],
            )),
    );
    showDialog(
        barrierDismissible: false,
        barrierColor: Colors.white.withOpacity(0),
        context: context,
        builder: (context) {
          return alertDialog;
        });
  }

  Widget _buildPhoneNumberSubmitedBloc() {
    return BlocListener<PhoneAuthCubit, PhoneAuthState>(
      listenWhen: (previos, curent) {
        return previos != curent;
      },
      listener: (context, stat) {
        if (stat is Loading) {
          showProgressIndecator(context);
        }
        if (stat is PhoneNumberSubmited) {
          Navigator.pop(context);
          Navigator.of(context).pushNamed(
            otpScreen,
            arguments: phoneNumber,
          );
        }
      },
      child: Container(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Form(
          key: phoneFormKey,
          child: ListView(
            children: [
              Container(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 200, child: ConstantWidget()),
                      const SizedBox(
                        height: 50,
                      ),
                      _buildFormFeild(),
                      const SizedBox(
                        height: 70,
                      ),
                      _buildNextButton(context),
                      _buildPhoneNumberSubmitedBloc()
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // في حالة عدم وجود اتصال بالإنترنت، إغلاق الـ loading
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("خطأ في الاتصال بالإنترنت"),
            content: const Text(
                "الرجاء التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى."),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("موافق"),
              ),
            ],
          );
        },
      );
    } else {
      print('Internet Connection is available');
    }
  }
}
