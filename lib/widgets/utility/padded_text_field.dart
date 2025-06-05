import 'package:flutter/material.dart';
import 'package:roth_analysis/widgets/utility/widget_constants.dart';

class PaddedTextField extends StatefulWidget {
  const PaddedTextField({
    super.key,
    this.padding,
    this.label,
    this.initialValue,
    this.getErrorText,
    this.onChanged,
  });

  final EdgeInsets? padding;
  final String? label;
  final String? initialValue;
  final String? Function(String?)? getErrorText;
  final void Function(String)? onChanged;

  @override
  State<PaddedTextField> createState() => _PaddedTextFieldState();
}

class _PaddedTextFieldState extends State<PaddedTextField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _invalidInputText;

  /// Intializes state data from widget, used in initState() and didUpdateWidget
  void initStateFromWidget({PaddedTextField? oldWidget}) {
    // if old widget matches the current widget then no intialization is required.
    if (oldWidget == widget) return;
    // if there is an oldwidget and its intialValue property matches the current widget's
    // then there is nothing to intiialize.
    if (oldWidget != null && oldWidget.initialValue == widget.initialValue) {
      return;
    }
    // if we have focus then we should not update controller.text which would
    // result in a loss of the cursor position in the control.
    // Otherwise we need to update controller.text to pick up any value
    // updates passed down from the parent widget.
    if (_focusNode.context != null && _focusNode.hasFocus) return;
    _controller.text = widget.initialValue ?? '';
  }

  @override
  void initState() {
    super.initState();
    initStateFromWidget();
    _focusNode.addListener(
      () {
        if (!_focusNode.hasFocus) {
          if (widget.onChanged != null) widget.onChanged!(_controller.text);
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant PaddedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    initStateFromWidget(oldWidget: oldWidget);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? WidgetConstants.defaultTextFieldPadding,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelText: widget.label,
          helperText: '',
          errorText: _invalidInputText,
        ),
        onChanged: (text) {
          setState(() {
            _invalidInputText =
                widget.getErrorText != null ? widget.getErrorText!(text) : null;
          });
        },
      ),
    );
  }
}

class PaddedTextFormField extends StatefulWidget {
  const PaddedTextFormField({
    super.key,
    this.padding,
    this.label,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onSaved,
  });

  final EdgeInsets? padding;
  final String? label;
  final String? initialValue;
  final String? Function(String?)? validator;
  final void Function(String?)? onChanged;
  final void Function(String?)? onSaved;

  @override
  State<PaddedTextFormField> createState() => _PaddedTextFormFieldState();
}

class _PaddedTextFormFieldState extends State<PaddedTextFormField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Intializes state data from widget, used in initState() and didUpdateWidget()
  void initStateFromWidget({PaddedTextFormField? oldWidget}) {
    // if old widget matches the current widget then no intialization is required.
    if (oldWidget == widget) return;
    // if there is an oldwidget and its intialValue property matches the current widget's
    // then there is nothing to intiialize.
    if (oldWidget != null && oldWidget.initialValue == widget.initialValue) {
      return;
    }
    // if we have focus then we should not update controller.text which would
    // result in a loss of the cursor position in the control.
    // Otherwise we need to update controller.text to pick up any value
    // updates passed down from the parent widget.
    if (_focusNode.context != null && _focusNode.hasFocus) return;
    _controller.text = widget.initialValue ?? '';
  }

  @override
  void initState() {
    super.initState();
    initStateFromWidget();
    _focusNode.addListener(
      () {
        if (!_focusNode.hasFocus) {
          if (widget.onChanged != null) widget.onChanged!(_controller.text);
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant PaddedTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    initStateFromWidget(oldWidget: oldWidget);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? WidgetConstants.defaultTextFieldPadding,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          helperText: '',
          labelText: widget.label,
        ),
        autovalidateMode: AutovalidateMode.always,
        validator: (newValue) {
          return widget.validator != null ? widget.validator!(newValue) : null;
        },
        onSaved: (text) {
          if (widget.onSaved != null) {
            widget.onSaved!(text);
          }
        },
      ),
    );
  }
}
