import 'package:flutter/material.dart';

class MyDropdownButton extends StatefulWidget {
  final List<String> stationName;
  final void Function(String?)? onChanged;
  final String hint;
  final String itemPrefix;

  const MyDropdownButton({
    super.key,
    required this.stationName,
    required this.onChanged,
    required this.hint,
    required this.itemPrefix, String? selectedValue,
  });

  @override
  _MyDropdownButtonState createState() => _MyDropdownButtonState();
}

class _MyDropdownButtonState extends State<MyDropdownButton> {
  String? selectedCity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        hint: Text(widget.hint),
        isExpanded: true,
        value: selectedCity,
        onChanged: widget.onChanged,
        decoration: const InputDecoration(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
        items: widget.stationName.map<DropdownMenuItem<String>>((value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              '${widget.itemPrefix} $value',
              textDirection: TextDirection.rtl,
            ),
          );
        }).toList(),
      ),
    );
  }
}
