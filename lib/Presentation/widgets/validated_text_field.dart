import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A text field that shows a floating error "bubble" above itself
/// when the value doesn't match the given validator, similar to
/// how form validation tooltips appear near where you're typing.
class ValidatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String value) validator;
  final TextInputType keyboardType;
  final bool obscure;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  const ValidatedTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.validator,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.suffixIcon,
    this.inputFormatters,
    this.maxLength,
  });

  @override
  State<ValidatedTextField> createState() => ValidatedTextFieldState();
}

class ValidatedTextFieldState extends State<ValidatedTextField> {
  String? _error;

  /// Called on every keystroke — only shows an error once the user has
  /// typed something (so an empty field doesn't show red immediately).
  void _onChanged(String value) {
    if (value.isEmpty) {
      setState(() => _error = null);
      return;
    }
    setState(() => _error = widget.validator(value));
  }

  /// Called when the parent form is submitted — forces validation even
  /// on an empty/untouched field, and returns the error (or null if valid).
  String? validateForSubmit() {
    final err = widget.validator(widget.controller.text);
    setState(() => _error = err);
    return err;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _error != null;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Error bubble — floats above the field near the top-left,
          // roughly where the user's eyes/cursor are while typing.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            top: hasError ? -34 : -14,
            left: 12,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: hasError ? 1 : 0,
              child: IgnorePointer(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.shade200,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _error ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // The actual input field
          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: hasError
                      ? const BorderSide(color: Colors.redAccent, width: 1.5)
                      : BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: hasError ? Colors.redAccent : const Color(0xFFDBF500),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
            ),
            child: SizedBox(
              height: 60,
              child: TextField(
                controller: widget.controller,
                obscureText: widget.obscure,
                keyboardType: widget.keyboardType,
                maxLength: widget.maxLength,
                inputFormatters: widget.inputFormatters,
                onChanged: _onChanged,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: const TextStyle(color: Colors.black54, fontSize: 13),
                  prefixIcon: Icon(
                    widget.icon,
                    color: hasError ? Colors.redAccent : Colors.black54,
                  ),
                  suffixIcon: widget.suffixIcon,
                  counterText: '', // hide the built-in maxLength counter
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}