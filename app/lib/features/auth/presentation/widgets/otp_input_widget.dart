import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single OTP digit input box.
///
/// Used in a row of [count] boxes to build the full OTP entry widget.
/// Auto-advances focus to the next box on digit entry.
/// Handles backspace to move focus and clear the previous box.
class OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const OtpBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return SizedBox(
      width: 48,
      height: 60,
      child: Focus(
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspace();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: focusNode.hasFocus
                ? primary.withOpacity(0.1)
                : theme.inputDecorationTheme.fillColor,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: controller.text.isNotEmpty
                    ? primary.withOpacity(0.5)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
          onChanged: (value) {
            if (value.length > 1) {
              controller.text = value[value.length - 1];
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            }
            onChanged(controller.text);
          },
        ),
      ),
    );
  }
}

/// A row of [count] OTP boxes. Manages its own controllers and focus chain.
class OtpInputWidget extends StatefulWidget {
  final int count;
  final ValueChanged<String> onCompleted;
  final bool isError;

  const OtpInputWidget({
    super.key,
    this.count = 6,
    required this.onCompleted,
    this.isError = false,
  });

  @override
  State<OtpInputWidget> createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<OtpInputWidget> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.count, (_) => TextEditingController());
    _nodes = List.generate(widget.count, (_) => FocusNode());
    for (final n in _nodes) {
      n.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length == 1 && index < widget.count - 1) {
      _nodes[index + 1].requestFocus();
    }
    final code = _controllers.map((c) => c.text).join();
    if (code.length == widget.count) {
      widget.onCompleted(code);
    }
  }

  void _onBackspace(int index) {
    if (index > 0) {
      _controllers[index - 1].clear();
      _nodes[index - 1].requestFocus();
    }
  }

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _nodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.count, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i < widget.count - 1 ? 10 : 0),
          child: OtpBox(
            controller: _controllers[i],
            focusNode: _nodes[i],
            onChanged: (v) => _onChanged(i, v),
            onBackspace: () => _onBackspace(i),
          ),
        );
      }),
    );
  }
}
