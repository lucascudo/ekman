import 'package:flutter/material.dart';

class RoundedButtonIcon extends StatelessWidget {
  final IconData icon;
  final double width;
  final double height;
  final Function onTap;

  RoundedButtonIcon(
      {@required this.icon,
      @required this.width,
      @required this.height,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: Colors.blue, // button color
        child: InkWell(
          splashColor: Colors.red, // inkwell color
          child: SizedBox(
            width: width,
            height: height,
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
