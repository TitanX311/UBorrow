import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uborrow/theme/app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.blue,
    scaffoldBackgroundColor: AppColors.lightGray,
    textTheme: GoogleFonts.dmSerifTextTextTheme(),
  );
}
