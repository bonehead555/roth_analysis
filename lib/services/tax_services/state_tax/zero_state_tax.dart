
import 'state_tax.dart';

/// Class/Object to be used for states that do not have state income taxes
class ZeroStateTax extends StateTax {
  ZeroStateTax(super.filingSettings);

  @override
  double getDeductable() {
    return 0;
  }

  @override
  double calcTaxes() {
    return 0;
  }
}