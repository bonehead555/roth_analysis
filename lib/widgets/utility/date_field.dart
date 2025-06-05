import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roth_analysis/utilities/date_utilities.dart';
import 'package:roth_analysis/widgets/utility/widget_constants.dart';

class DateField extends StatefulWidget {
  /// Returns a widget to display and edit dates.
  /// * [labelText] - Label to be applied to the widget.
  /// * [currentDate] - Cuurent date value.
  /// * [firstDate] - Start date for the range of valid dates.
  /// * [lastDate] - End date for the range of valid dates.
  /// * [onChanged] - Callback when the date is changed providing the changed date as a parameter.
  const DateField(
      {super.key,
      this.labelText,
      this.currentDate,
      this.firstDate,
      this.lastDate,
      this.onChanged});
  final String? labelText;
  final DateTime? currentDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTime)? onChanged;

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _invalidInputText;

  void _datePicker() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      currentDate: dateFromString(_controller.text) ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(2000),
      lastDate: widget.lastDate ?? DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _controller.text = dateToString(pickedDate);
        _invalidInputText = _testForValidInputValue(pickedDate);
      });
    }
  }

  /// Intializes state data from widget, used in initState() and didUpdateWidget()
  void initStateFromWidget({DateField? oldWidget}) {
    // if old widget matches the current widget then no intialization is required.
    if (oldWidget == widget) return;
    // check and get warning text should currentDate be invalid.
    _invalidInputText = _testForValidInputValue(widget.currentDate);
    // if we have focus then we should not update controller.text which would
    // result in a loss of the cursor position in the control.
    // Otherwise we need to update controller.text to pick up any value
    // updates passed down from the parent widget.
    if (_focusNode.context != null && _focusNode.hasFocus) return;
    _controller.text =
        widget.currentDate == null ? '' : dateToString(widget.currentDate!);
  }

  @override
  void initState() {
    super.initState();
    initStateFromWidget();
    _focusNode.addListener(
      () {
        // actions on loss of focus
        if (!_focusNode.hasFocus) {
          // if the current date text is invalid, take no action
          if (_invalidInputText != null) return;
          // otherwise, decode the text to a date and use it to:
          // (a) reformat / pretty up the date string
          // (b) invoke the pn Changed call back if one was provided
          var currentValue = dateFromString(_controller.text);
          _controller.text = dateToString(currentValue);
          if (widget.onChanged != null) widget.onChanged!(currentValue!);
        }
      },
    );
  }

  /// Performs needed intializations when the widget is reloaded.
  @override
  void didUpdateWidget(covariant DateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget == oldWidget) return;
    initStateFromWidget(oldWidget: oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? _testForValidInputText(String? text) {
    var value = dateFromString(text);
    return _testForValidInputValue(value);
  }

  String? _testForValidInputValue(DateTime? value) {
    if (value == null) {
      return 'Must be yyyy-mm-dd';
    } else if (widget.firstDate != null && value.isBefore(widget.firstDate!)) {
      return 'Must be later than ${dateToString(widget.firstDate)}';
    } else if (widget.lastDate != null && value.isAfter(widget.lastDate!)) {
      return 'Must be earlier than ${dateToString(widget.lastDate)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: WidgetConstants.defaultTextFieldPadding,
      child: TextField(
        focusNode: _focusNode,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelText: widget.labelText,
          helperText: '',
          errorText: _invalidInputText,
          suffixIcon: const Icon(Icons.calendar_month),
        ),
        controller: _controller,
        onTap: _datePicker,
        onChanged: (text) {
          var newInvalidInputText = _testForValidInputText(text);
          if (_invalidInputText != newInvalidInputText) {
            setState(() {
              _invalidInputText = newInvalidInputText;
            });
          }
        },
      ),
    );
  }
}

class DateFormField extends StatefulWidget {
  /// Returns a form widget to display and edit dates.
  /// * [labelText] - Label to be applied to the widget.
  /// * [currentDate] - Cuurent date value.
  /// * [firstDate] - Start date for the range of valid dates.
  /// * [lastDate] - End date for the range of valid dates.
  /// * [onChanged] - Callback when the date is changed providing the changed date as a parameter.
  /// * [onSaved] - Callback when the form is saving providing the changed date as a parameter.
  const DateFormField({
    super.key,
    this.labelText,
    this.currentDate,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.onSaved,
  });

  final String? labelText;
  final DateTime? currentDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final void Function(DateTime)? onChanged;
  final void Function(DateTime)? onSaved;

  @override
  State<DateFormField> createState() => _DateFormFieldState();
}

class _DateFormFieldState extends State<DateFormField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _datePicker() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      currentDate: DateTime.tryParse(_controller.text) ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(2000),
      lastDate: widget.lastDate ?? DateTime(2100),
    );

    if (pickedDate != null) {
      String formattedDate = dateToString(pickedDate);
      _controller.text = formattedDate;
    }
  }

  /// Intializes state data from widget, used in initState() and didUpdateWidget()
  void initStateFromWidget({DateFormField? oldWidget}) {
    // if old widget matches the current widget then no intialization is required.
    if (oldWidget == widget) return;
    // if we have focus then we should not update controller.text which would
    // result in a loss of the cursor position in the control.
    // Otherwise we need to update controller.text to pick up any value
    // updates passed down from the parent widget.
    if (_focusNode.context != null && _focusNode.hasFocus) return;
    _controller.text =
        widget.currentDate == null ? '' : dateToString(widget.currentDate!);
  }

  @override
  void initState() {
    super.initState();
    initStateFromWidget();
    _focusNode.addListener(
      () {
        // actions on loss of focus
        if (!_focusNode.hasFocus) {
          // if the current date text is invalid, take no action
          var currentValue = dateFromString(_controller.text);
          if (currentValue == null) return;
          // otherwise, decode the text to a date and use it to:
          // (a) reformat / pretty up the date string
          // (b) invoke the onChanged callback, if one was provided
          _controller.text = dateToString(currentValue);
          if (widget.onChanged != null) widget.onChanged!(currentValue);
        }
      },
    );
  }

  /// Performs needed intializations when the widget is reloaded.
  @override
  void didUpdateWidget(covariant DateFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    initStateFromWidget(oldWidget: oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? _testForValidInputText(String? text) {
    var value = dateFromString(text);
    return _testForValidInputValue(value);
  }

  String? _testForValidInputValue(DateTime? value) {
    if (value == null) {
      return 'Must be yyyy-mm-dd';
    } else if (widget.firstDate != null && value.isBefore(widget.firstDate!)) {
      return 'Must be later than ${dateToString(widget.firstDate)}';
    } else if (widget.lastDate != null && value.isAfter(widget.lastDate!)) {
      return 'Must be earlier than ${dateToString(widget.lastDate)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    _controller.text = widget.currentDate == null
        ? ''
        : DateFormat('yyyy-MM-dd').format(widget.currentDate!);

    return Padding(
      padding: WidgetConstants.defaultTextFieldPadding,
      child: TextFormField(
        focusNode: _focusNode,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelText: widget.labelText,
          helperText: '',
          suffixIcon: const Icon(Icons.calendar_month),
        ),
        controller: _controller,
        onTap: _datePicker,
        autovalidateMode: AutovalidateMode.always,
        validator: (textValue) => _testForValidInputText(textValue),
        onSaved: (textValue) {
          var dateTime = dateFromString(textValue);
          if (dateTime != null && widget.onSaved != null) {
            widget.onSaved!(dateTime);
          }
        },
      ),
    );
  }
}
