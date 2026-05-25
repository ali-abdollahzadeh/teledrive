import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_text.dart';
import '../../../../core/theme/app_colors.dart';

class PhoneField extends StatelessWidget {
  const PhoneField({
    required this.controller,
    required this.dialCode,
  });

  final TextEditingController controller;
  final String dialCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w300,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.colorScheme.surfaceContainer,
        labelText: 'Phone number',
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 18, right: 12),
          child: Center(
            widthFactor: 1,
            child: Text(
              dialCode,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 0,
          minHeight: 0,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(500),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(500),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(500),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
      validator: (value) {
        final phone = value?.trim() ?? '';

        if (phone.isEmpty) {
          return AppText.phoneNumberRequired;
        }

        if (phone.length < 6) {
          return AppText.phoneNumberInvalid;
        }

        return null;
      },
    );
  }
}
