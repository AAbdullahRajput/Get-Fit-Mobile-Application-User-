import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class ReuseableButton extends StatelessWidget {
  final String title;
  final void Function()? onPressed;
  const ReuseableButton({super.key, required this.title, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(MediaQuery.sizeOf(context).width * 0.7, 40),
            backgroundColor: themeColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
        onPressed: onPressed,
        child: Text(title, style: TextStyle(color: Colors.black, fontSize: 16)),
      ),
    );
  }
}
