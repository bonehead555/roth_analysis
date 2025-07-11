import 'package:flutter/material.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';
import 'package:roth_analysis/widgets/utility/widget_constants.dart';

class PercentInputField extends StatefulWidget {
  const PercentInputField({
    super.key,
    this.padding,
    this.labelText,
    this.initialValue,
    this.maxValue,
    this.minValue,
    required this.onChanged,
  });

  final EdgeInsets? padding;
  final String? labelText;
  final double? initialValue;
  final double? maxValue;
  final double? minValue;
  final Function(double?)? onChanged;

  @override
  State<PercentInputField> createState() => _PercentInputFieldState();
}

class _PercentInputFieldState extends State<PercentInputField> {
  final _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _invalidInputText;

  /// Intializes state data from widget, used in initState() and didUpdateWidget()
  void initStateFromWidget({PercentInputField? oldWidget}) {
    // if old widget matches the current widget then no intialization is required.
    if (oldWidget == widget) return;
    // if there is an oldwidget and its intialValue property matches the current widget's
    // then there is nothing to intiialize.
    if (oldWidget != null && oldWidget.initialValue == widget.initialValue) {
      return;
    }
    // check and get warning text when initalValue is invalid.
    _invalidInputText = _testForValidInputValue(widget.initialValue);
    // if we have focus then we should not update controller.text which would
    // result in a loss of the cursor position in the control.
    // Otherwise we need to update controller.text to pick up any value
    // updates passed down from the parent widget.
    if (_focusNode.context != null && _focusNode.hasFocus) return;
    _textController.text =
        widget.initialValue == null ? '' : showPercentage(widget.initialValue);
  }

  @override
  void initState() {
    super.initState();
    initStateFromWidget();
    _focusNode.addListener(
      () {
        if (_focusNode.hasFocus) {
          var currentValue = parsePercentage(_textController.text);
          if (currentValue == null) return;
          _textController.text =
              showPercentage(currentValue, showPercentSign: false);
        } else {
          var currentValue = parsePercentage(_textController.text);
          if (currentValue == null) return;
          _textController.text = showPercentage(currentValue);
          if (widget.onChanged != null) widget.onChanged!(currentValue);
        }
      },
    );
    return;
  }

  @override
  void didUpdateWidget(covariant PercentInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    initStateFromWidget(oldWidget: oldWidget);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? _testForValidInputText(String text) {
    var value = parsePercentage(text);
    return _testForValidInputValue(value);
  }

  String? _testForValidInputValue(double? value) {
    if (value == null) {
      return 'Invalid Number Format';
    } else if (widget.minValue != null && value < widget.minValue!) {
      return 'Must be greater than ${showPercentage(widget.minValue)}';
    } else if (widget.maxValue != null && value > widget.maxValue!) {
      return 'Must be less than ${showPercentage(widget.maxValue)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? WidgetConstants.defaultTextFieldPadding,
      child: TextField(
        focusNode: _focusNode,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          helperText: '',
          labelText: widget.labelText,
          errorText: _invalidInputText,
        ),
        controller: _textController,
        onChanged: (textValue) {
          setState(() {
            _invalidInputText = _testForValidInputText(textValue);
          });
        },
      ),
    );
  }
}

class PercentInputFormField extends StatefulWidget {
  const PercentInputFormField({
    super.key,
    this.padding,
    this.labelText,
    this.initialValue,
    this.maxValue,
    this.minValue,
    this.onChanged,
    this.onSaved,
  });

  final EdgeInsets? padding;
  final String? labelText;
  final double? initialValue;
  final double? maxValue;
  final double? minValue;
  final Function(double?)? onChanged;
  final Function(double?)? onSaved;

  @override
  State<PercentInputFormField> createState() => _PercentInputFormFieldState();
}

class _PercentInputFormFieldState extends State<PercentInputFormField> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Intialize TextFromField text with provided initialValue (if present).
    _textController.text =
        widget.initialValue == null ? '' : showPercentage(widget.initialValue);
    // Watch for loss of focus or gain of focus
    _focusNode.addListener(
      () {
        if (_focusNode.hasFocus) {
          // Getting focus so trailing percent sign musat be removed.
          var currentValue = parsePercentage(_textController.text);
          if (currentValue == null) return;
          _textController.text =
              showPercentage(currentValue, showPercentSign: false);
        } else {
          // Loosing focus so try to format with the trailing percent sign.
          var currentValue = parsePercentage(_textController.text);
          if (currentValue == null) return;
          _textController.text = showPercentage(currentValue);
          if (widget.onChanged != null) widget.onChanged!(currentValue);
        }
      },
    );
    return;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  String? _testForValidInputText(String? text) {
    var value = parsePercentage(text);
    return _testForValidInputValue(value);
  }

  String? _testForValidInputValue(double? value) {
    if (value == null) {
      return 'Invalid Number Format';
    } else if (widget.minValue != null && value < widget.minValue!) {
      return 'Must be greater than ${showPercentage(widget.minValue)}';
    } else if (widget.maxValue != null && value > widget.maxValue!) {
      return 'Must be less than ${showPercentage(widget.maxValue)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? WidgetConstants.defaultTextFieldPadding,
      child: TextFormField(
        focusNode: _focusNode,
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: const OutlineInputBorder(),
          labelText: widget.labelText,
          helperText: '',
        ),
        controller: _textController,
        autovalidateMode: AutovalidateMode.always,
        validator: (text) => _testForValidInputText(text),
        onSaved: (textValue) {
          if (widget.onSaved != null) {
            widget.onSaved!(parsePercentage(textValue));
          }
        },
      ),
    );
  }
}
