
import 'state_tax.dart';

/// Class/Object to be used for states where we haven;t yet implemented state income taxe estimation
class TodoStateTax extends StateTax {
  TodoStateTax(super.filingSettings);

  @override
  double getDeductable() {
    return 0;
  }

  @override
  double calcTaxes() {
    throw Exception(
        'No tax calculation support exists for the state of ${filingSettings.filingState.label}');
  }
} // End TodoStateTax Class