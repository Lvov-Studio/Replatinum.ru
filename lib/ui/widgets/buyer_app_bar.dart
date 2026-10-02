import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

AppBar buyerAppBar(BuildContext context, String title) => AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.mainText,
      iconTheme: const IconThemeData(color: AppColors.mainText),
      titleTextStyle: const TextStyle(
          color: AppColors.mainText, fontSize: 18, fontWeight: FontWeight.w600),
      centerTitle: true,
      toolbarHeight: 56 +
          (MediaQuery.textScalerOf(context).scale(18) - 18).clamp(0, 36) * 2,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: Text(title,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis),
    );
