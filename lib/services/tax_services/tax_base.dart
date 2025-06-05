import 'package:roth_analysis/services/tax_services/tax_filing_settings.dart';
import 'package:roth_analysis/models/enums/filing_status.dart';

class TaxRulesBase {
  const TaxRulesBase({required this.year});
  final int year;
}

/// Base class of all Tax Calculation classes.
class TaxBase {
  TaxFilingSettings _filingSettings;
  TaxBase(this._filingSettings) {
    validateFilingSettings(filingSettings);
  }

  static void validateFilingSettings(TaxFilingSettings filingSettings) {
    if (filingSettings.filingStatus.isMarried &&
        filingSettings.spouseInventory == null) {
      throw Exception('Filing Married but spouse information was not provided');
    }
  }

  /// Returns the configured [TaxFilingSettings]
  TaxFilingSettings get filingSettings => _filingSettings;

  /// Sets new [TaxFilingSettings]. 
  set filingSettings(TaxFilingSettings newFilingSettings) {
    validateFilingSettings(newFilingSettings);
    _filingSettings = newFilingSettings;
  }

  /// Returns the [FilingStatus] as configured in [filingSettings]
  FilingStatus get filingStatus => filingSettings.filingStatus;

  /// Returns the configured [TaxFilingSettings.targetYear]
  int get targetYear => filingSettings.targetYear;


    /// Returns the social security income appropriate for the filing status
  /// That is, combined if marriedFilingJointly
  double get ssIncome {
    double result = filingSettings.selfInventory.ssIncome;
    if (filingStatus == FilingStatus.marriedFilingJointly) {
      result += filingSettings.spouseInventory!.ssIncome;
    }
    return result;
  }

  /// Returns the IRA distributions appropriate for the filing status
  /// That is, combined if marriedFilingJointly
  double get iraDistributions {
    double result = filingSettings.selfInventory.iraDistributions;
    if (filingStatus == FilingStatus.marriedFilingJointly) {
      result += filingSettings.spouseInventory!.iraDistributions;
    }
    return result;
  }

  /// Returns the interest income appropriate for the filing status
  /// That is, combined if marriedFilingJointly
  double get interestIncome {
    double result = filingSettings.selfInventory.interestIncome;
    if (filingStatus == FilingStatus.marriedFilingJointly) {
      result += filingSettings.spouseInventory!.interestIncome;
    }
    return result;
  }
 /// Returns the dividend income appropriate for the filing status
  /// That is, combined if marriedFilingJointly
  double get dividendIncome {
    double result = filingSettings.selfInventory.dividendIncome;
    if (filingStatus == FilingStatus.marriedFilingJointly) {
      result += filingSettings.spouseInventory!.dividendIncome;
    }
    return result;
  }
  
  /// Returns the capital gains income appropriate for the filing status
  /// That is, combined if marriedFilingJointly
  double get capitalGainsIncome {
    double result = filingSettings.selfInventory.capitalGainsIncome;
    if (filingStatus == FilingStatus.marriedFilingJointly) {
      result += filingSettings.spouseInventory!.capitalGainsIncome;
    }
    return result;
  }

  /// Returns the regular income appropriate for the filing status
  /// That is, combined if marriedFilingJointly
  double get regularIncome {
    double result = filingSettings.selfInventory.regularIncome;
    if (filingStatus == FilingStatus.marriedFilingJointly) {
      result += filingSettings.spouseInventory!.regularIncome;
    }
    return result;
  }

  /// Returns the self emoloyment income appropriate for the filing status
  /// That is, combined if marriedFilingJointly
  double get selfEmploymentIncome {
    double result = filingSettings.selfInventory.selfEmploymentIncome;
    if (filingStatus == FilingStatus.marriedFilingJointly) {
      result += filingSettings.spouseInventory!.selfEmploymentIncome;
    }
    return result;
  }

  /// Returns the pension income appropriate for the filing status
  /// That is, combined if marriedFilingJointly
  double get pensionIncome {
    double result = filingSettings.selfInventory.pensionIncome;
    if (filingStatus == FilingStatus.marriedFilingJointly) {
      result += filingSettings.spouseInventory!.pensionIncome;
    }
    return result;
  }

  /// Returns the taxRules that are
  /// (a) Closest to the targetYear and
  /// (b) No greater than the targetYear and
  /// (c) If no rules exist <= to the targetYear, return closest rules.
  /// TaxRulesByFilingStatus adjusted for yearly adjustments
  static TaxRulesBase getClosestTaxRulesByYear(
      int targetYear, List<TaxRulesBase> taxRulesList) {
    TaxRulesBase? earlierMatch;
    TaxRulesBase? laterMatch;
    int initialDistance = double.maxFinite.round();
    int earlierDistance = initialDistance;
    int laterDistance = initialDistance;

    if (taxRulesList.isEmpty) {
      throw Exception('No Tax Rules Specified');
    }

    for (final TaxRulesBase taxRules in taxRulesList) {
      int currentDistance = targetYear - taxRules.year;

      if (currentDistance == 0) {
        earlierDistance = 0;
        earlierMatch = taxRules;
        laterDistance = 0;
        laterMatch = taxRules;
        break;
      }

      if (currentDistance > 0 &&
          currentDistance.abs() < earlierDistance.abs()) {
        earlierDistance = currentDistance;
        earlierMatch = taxRules;
      } else if (currentDistance < 0 &&
          currentDistance.abs() < laterDistance.abs()) {
        laterDistance = currentDistance;
        laterMatch = taxRules;
      }
    }
    return earlierMatch ?? laterMatch!;
  }
} // End TaxBase Class
