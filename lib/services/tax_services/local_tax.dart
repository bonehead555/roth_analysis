import 'package:roth_analysis/models/enums/owner_type.dart';

import 'tax_base.dart';
import 'tax_filing_settings.dart';

class LocalTax extends TaxBase {
  LocalTax(super._filingSettings);

  double get taxRate => filingSettings.localTaxPercentage / 100;

  double get taxableIncome {
    return regularIncome + selfEmploymentIncome;
  }

  /// Calculates the  yearly local taxes.
  /// [ownerType] - Identifies the person (self or spouse) for which taxes are calculated, however if not specified,
  /// the result includes taxes for both self and spouse (if married). 
  double calcTaxes({OwnerType? ownerType}) {
    double taxableIncome;
    double result;

    if (filingSettings.filingStatus.isMarried && filingSettings.spouseInventory == null) {
      throw Exception('Filing Married without specifing spouse inventory.');
    }

    if (ownerType != null) {
      PersonInventory personInventory = ownerType.isSelf ? filingSettings.selfInventory : filingSettings.spouseInventory!;
      taxableIncome = personInventory.regularIncome + personInventory.selfEmploymentIncome;
      result = taxableIncome * taxRate;
    } else {
      result = calcTaxes(ownerType: OwnerType.self);
      if (filingSettings.filingStatus.isMarried) {
        result += calcTaxes(ownerType: OwnerType.spouse);
      }
    }
    return result.roundToDouble();
  }
}
