import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roth_analysis/models/enums/filing_state.dart';
import 'package:roth_analysis/models/enums/filing_status.dart';

class Self extends StatefulWidget {
  const Self({super.key});

  @override
  State<Self> createState() => _SelfState();
}

class _SelfState extends State<Self> {
  bool _isBlind = false;
  FilingStatus _filingStatus = FilingStatus.single;
  FilingState _filingState = FilingState.other;
  final _birthdateController = TextEditingController();

  void birthdatePicker() async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(
            2000), //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime(2101));

    if (pickedDate != null) {
      //print(pickedDate);  //pickedDate output format => 2021-03-10 00:00:00.000
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      //print(formattedDate); //formatted date output using intl package =>  2021-03-16
      //you can implement different kind of Date Format here according to your requirement

      setState(() {
        _birthdateController.text = formattedDate ;//set output date to TextField value.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 5),
              child: Text(
                'Self',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(thickness: 2),
            Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.bottom,
              children: <TableRow>[
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Birthdate',
                          hintText: 'yyyy/mm/dd',
                        ),
                        controller: _birthdateController,
                        onTap: birthdatePicker,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CheckboxListTile(
                        title: const Text('Blind'),
                        //subtitle: const Text('Check if Filing Blind on Taxes'),
                        value: _isBlind,
                        onChanged: (bool? value) {
                          setState(() {
                            _isBlind = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownMenu<FilingStatus>(
                      label: const Text('Federal Filing Status'),
                      initialSelection: _filingStatus,
                      onSelected: (value) {
                        setState(() {
                          _filingStatus = value!;
                        });
                      },
                      dropdownMenuEntries: FilingStatus.values
                          .map<DropdownMenuEntry<FilingStatus>>(
                        (FilingStatus filingStatusDef) {
                          return DropdownMenuEntry<FilingStatus>(
                            value: filingStatusDef,
                            label: filingStatusDef.label,
                          );
                        },
                      ).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownMenu<FilingState>(
                      label: const Text('Filing State'),
                      initialSelection: _filingState,
                      onSelected: (value) {
                        setState(() {
                          _filingState = value!;
                        });
                      },
                      dropdownMenuEntries: FilingState.values
                          .map<DropdownMenuEntry<FilingState>>(
                        (FilingState filingState) {
                          return DropdownMenuEntry<FilingState>(
                            value: filingState,
                            label: filingState.label,
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ]),
                const TableRow(children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'End of Plan Date',
                        hintText: 'yyyy/mm/dd',
                      ),
                    ),
                  ),
                  SizedBox(),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
