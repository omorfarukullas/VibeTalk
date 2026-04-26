import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable phone number input widget combining a country code picker
/// and a digits-only text field.
///
/// Calls [onChanged] whenever either the country code or number changes.
/// Calls [onSubmitted] when the user presses the keyboard done/go action.
class PhoneInputWidget extends StatefulWidget {
  final ValueChanged<({String countryCode, String number})> onChanged;
  final VoidCallback? onSubmitted;
  final String? initialCountryCode;

  const PhoneInputWidget({
    super.key,
    required this.onChanged,
    this.onSubmitted,
    this.initialCountryCode = 'US',
  });

  @override
  State<PhoneInputWidget> createState() => _PhoneInputWidgetState();
}

class _PhoneInputWidgetState extends State<PhoneInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _dialCode = '+1';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_notify);
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged((countryCode: _dialCode, number: _controller.text));
  }

  void _onCountryChanged(CountryCode code) {
    setState(() => _dialCode = code.dialCode ?? '+1');
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focus.hasFocus ? primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          CountryCodePicker(
            onChanged: _onCountryChanged,
            initialSelection: widget.initialCountryCode,
            favorite: const ['+1', '+44', '+880'],
            showCountryOnly: false,
            showOnlyCountryWhenClosed: false,
            alignLeft: false,
            textStyle: theme.textTheme.bodyLarge,
            padding: EdgeInsets.zero,
          ),
          Container(
            width: 1,
            height: 24,
            color: theme.colorScheme.onSurface.withOpacity(0.15),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              decoration: const InputDecoration(
                hintText: 'Phone number',
                border: InputBorder.none,
                fillColor: Colors.transparent,
                filled: false,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              onSubmitted: (_) => widget.onSubmitted?.call(),
            ),
          ),
        ],
      ),
    );
  }
}
