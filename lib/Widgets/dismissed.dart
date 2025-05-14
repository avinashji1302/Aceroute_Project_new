import 'package:flutter/material.dart';

Widget dismissedRight() {
  return Container(
    color: Colors.green, // Color for start-to-end swipe
    alignment: Alignment.centerLeft,
    padding: EdgeInsets.symmetric(horizontal: 20),
    child: Icon(Icons.edit, color: Colors.white), // Edit icon
  );
}

Widget dismissedLeft() {
  return Container(
    color: Colors.red, // Color for start-to-end swipe
    alignment: Alignment.centerLeft,
    padding: EdgeInsets.symmetric(horizontal: 20),
    child: Icon(Icons.delete, color: Colors.white), // Edit icon
  );
}

