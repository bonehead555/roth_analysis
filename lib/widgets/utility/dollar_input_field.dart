import 'package:flutter/material.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';
import 'package:roth_analysis/widgets/utility/widget_constants.dart';

class DollarInputField extends StatefulWidget {
  const DollarInputField({
    super.key,
    this.padding,
    this.labelText,
    this.initialValue,
    this.maxValue,
    this.minValue,
    this.onChanged,
  });

  final EdgeInsets? padding;
  final String? labelText;
  final double? initialValue;
  final double? maxValue;
  final double? minValue;
  final Function(double)? onChanged;

  @override
  State<DollarInputField> createState() => _DollarInputFieldState();
}

class _DollarInputFieldState extends State<DollarInputField> {
  final _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _invalidInputText;

  /// Intializes state data from widget, used in initState() and didUpdateWidget
  void initStateFromWidget({DollarInputField? oldWidget}) {
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
    _textController.text = widget.initialValue == null
        ? ''
        : showDollarString(widget.initialValue, showDollarSign: false);
  }

  @override
  void initState() {
    super.initState();
    initStateFromWidget();
    _focusNode.addListener(
      () {
        //
        if (!_focusNode.hasFocus) {
          var currentValue = parseDollarString(_textController.text);
          if (currentValue == null) return;
          _textController.text =
              showDollarString(currentValue, showDollarSign: false);
          if (widget.onChanged != null) widget.onChanged!(currentValue);
        }
      },
    );
    return;
  }

  /// Performs certian intializations when the widget is reloaded.
  @override
  void didUpdateWidget(covariant DollarInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    initStateFromWidget(oldWidget: oldWidget);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
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
      return 'Must be greater than ${showDollarString(widget.minValue)}';
    } else if (widget.maxValue != null && value > widget.maxValue!) {
      return 'Must be less than ${showDollarString(widget.maxValue)}';
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
          labelText: widget.labelText,
          helperText: '',
          prefixText: '\$',
          errorText: _invalidInputText,
        ),
        controller: _textController,
        onChanged: (textValue) {
          var newInvlaidInputText = _testForValidInputText(textValue);
          if (_invalidInputText != newInvlaidInputText) {
            setState(() {
              _invalidInputText = newInvlaidInputText;
            });
          }
        },
      ),
    );
  }
}

class DollarInputFormField extends StatefulWidget {
  const DollarInputFormField({
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
  State<DollarInputFormField> createState() => _DollarInputFormFieldState();
}

class _DollarInputFormFieldState extends State<DollarInputFormField> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Intializes state data from widget, used in initState() and didUpdateWidget()
  void initStateFromWidget({DollarInputFormField? oldWidget}) {
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
    _textController.text = widget.initialValue == null
        ? ''
        : showDollarString(widget.initialValue, showDollarSign: false);
  }

  @override
  void initState() {
    super.initState();
    initStateFromWidget();
    _focusNode.addListener(
      () {
        if (!_focusNode.hasFocus) {
          var currentValue = parseDollarString(_textController.text);
          if (currentValue == null) return;
          _textController.text =
              showDollarString(currentValue, showDollarSign: false);
          if (widget.onChanged != null) widget.onChanged!(currentValue);
        }
      },
    );
    return;
  }

  /// Performs needed intializations when the widget is reloaded.
  @override
  void didUpdateWidget(covariant DollarInputFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    initStateFromWidget(oldWidget: oldWidget);
  }

  @override
  void dispose() {
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
      return 'Must be greater than ${showDollarString(widget.minValue)}';
    } else if (widget.maxValue != null && value > widget.maxValue!) {
      return 'Must be less than ${showDollarString(widget.maxValue)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    _focusNode.addListener(() {
      var currentValue = parseDollarString(_textController.text);
      if (currentValue == null) return;
      _textController.text =
          showDollarString(currentValue, showDollarSign: false);
    });

    return Padding(
      padding: widget.padding ?? WidgetConstants.defaultTextFieldPadding,
      child: TextFormField(
        focusNode: _focusNode,
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: const OutlineInputBorder(),
          labelText: widget.labelText,
          helperText: '',
          prefixText: '\$',
        ),
        controller: _textController,
        autovalidateMode: AutovalidateMode.always,
        validator: (textValue) => _testForValidInputText(textValue),
        onSaved: (textValue) {
          if (widget.onSaved != null) {
            widget.onSaved!(parseDollarString(textValue));
          }
        },
      ),
    );
  }
}
