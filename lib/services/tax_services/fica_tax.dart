import 'dart:math';

import 'package:roth_analysis/services/tax_services/tax_filing_settings.dart';
import 'package:roth_analysis/utilities/number_utilities.dart';

import 'tax_base.dart';

/// Private class containing rules used to support calculation of FICA and Medicare Taxes
/// [year] Year that tax rules apply to; taken from IRS Infomation
/// [ficaContributionLimit] Maximum about of income subject to FICA taxation
class FicaTaxRules extends TaxRulesBase {
  FicaTaxRules({
    required super.year,
    required this.ficaContributionLimit,
  });
  double ficaContributionLimit;
  // The folowing tax rates currently do not change from year to year
  static const ficaTaxRate = 6.2 / 100;
  static const medicareTaxRate = 1.45 / 100;
  static const selfEmploymentTaxableIncomeRate = 92.35 / 100;
}

/// Sparse Table of FICA rules for various years
List<FicaTaxRules> _historicalFicaTaxRules = [
  FicaTaxRules(year: 2021, ficaContributionLimit: 142800),
  FicaTaxRules(year: 2024, ficaContributionLimit: 168600),
  FicaTaxRules(year: 2025, ficaContributionLimit: 176100),
];

/// Class that leverages [FicaTaxRules] to perform FICA and Medicsare tax calculations
/// [taxRules] - FICA Tax rules for year closest but less than specified target year.
/// There may be no matching FICA tax rules for the specified target year,
/// for example, when the taarget year is in the future. In such cases, interpolation
/// of monitary values between years is performed to provide estimates.
class FicaTax extends TaxBase {
  late FicaTaxRules _taxRules;

  /// Default Constructor
  /// [filingSettings] - Tax filing setting information needed be used to caluclate FICA taxes.
  FicaTax(super._filingSettings) {
    // Gets closest matching year's FICA Tax Rules
    _taxRules = TaxBase.getClosestTaxRulesByYear(
        filingSettings.targetYear, _historicalFicaTaxRules) as FicaTaxRules;
  }

  /// Returns the configured [FicaTaxRules]
  FicaTaxRules get taxRules => _taxRules;

  /// Returns the maximum about of income subject to FICA taxation.
  double get _ficaContributionLimit => taxRules.ficaContributionLimit;

  /// Returns the applicable FICA tax rate
  double get _ficaTaxRate => FicaTaxRules.ficaTaxRate;

  /// Returns the applicable medicare tax rate
  double get _medicareTaxRate => FicaTaxRules.medicareTaxRate;

  /// Returns record with (double ficaTaxableRegularIncome, double ficaTaxableSelfEmploymentIncome)
  /// limited as approptiate by the Contribution and benefit bases. See [_ficaContributionLimit].
  (double ficaTaxableRegularIncome, double ficaTaxableSelfEmploymentIncome)
      _getFicaTaxableIncome(PersonInventory person, int targetYear) {
    // before we can apply the limit we must normalize incomes to the taxtable year in use.
    final double regularIncome = adjustForTime(
        valueToAdjust: person.regularIncome,
        toYear: taxRules.year,
        fromYear: targetYear);
    final double selfEmploymentIncome = adjustForTime(
        valueToAdjust: person.selfEmploymentIncome,
        toYear: taxRules.year,
        fromYear: targetYear);
    // now we can apply the contribution and benefit base limits
    double ficaTaxableRegularIncome =
        min(regularIncome, _ficaContributionLimit);
    double ficaTaxableSelfEmploymentIncome = min(
        selfEmploymentIncome * FicaTaxRules.selfEmploymentTaxableIncomeRate,
        _ficaContributionLimit - ficaTaxableRegularIncome);
    // finally, before we can return these values, they must be noramlized back to the tax year being analyzed
    ficaTaxableRegularIncome = adjustForTime(
        valueToAdjust: ficaTaxableRegularIncome,
        toYear: targetYear,
        fromYear: taxRules.year);
    ficaTaxableSelfEmploymentIncome = adjustForTime(
        valueToAdjust: ficaTaxableSelfEmploymentIncome,
        toYear: targetYear,
        fromYear: taxRules.year);
    return (ficaTaxableRegularIncome, ficaTaxableSelfEmploymentIncome);
  }

  /// Returns total FICA taxes for the given year
  /// [person] - Identifies the person for which FICA tax should be calculated.
  /// When [person] is not specified, the return value includes both the self and spouse FICA taxes.
  double ficaTax({PersonInventory? person}) {
    double result = 0;
    if (person != null) {
      final (ficaTaxableRegularIncome, ficaTaxableSelfEmploymentIncome) =
          _getFicaTaxableIncome(person, filingSettings.targetYear);
      result = ficaTaxableRegularIncome * _ficaTaxRate +
          ficaTaxableSelfEmploymentIncome * _ficaTaxRate * 2;
    } else {
      result = ficaTax(person: filingSettings.selfInventory);
      if (filingSettings.filingStatus.isMarried) {
        result += ficaTax(person: filingSettings.spouseInventory);
      }
    }
    return result.roundToTwoPlaces();
  }

  /// Returns total FICA tax adjustmemt / deduction for the given year
  /// [person] - Identifies the person for which the FICA tax adjustment should be calculated
  /// When [person] is not specified, the return value includes both the self and spouse adjustment.
  double ficaTaxAdjustment({PersonInventory? person}) {
    double result = 0;
    if (person != null) {
      final (ficaTaxableRegularIncome, ficaTaxableSelfEmploymentIncome) =
          _getFicaTaxableIncome(person, filingSettings.targetYear);
      // FICA taxes on regular income do not impact IRS's AGI, MAGI or taxes.
      // However FICA taxes for self-employment income allows an adjustement of 1/2 the total taxes paid.
      result = ficaTaxableSelfEmploymentIncome * _ficaTaxRate;
    } else {
      result = ficaTaxAdjustment(person: filingSettings.selfInventory);
      if (filingSettings.filingStatus.isMarried) {
        result += ficaTaxAdjustment(person: filingSettings.spouseInventory);
      }
    }
    return result.roundToTwoPlaces();
  }

  /// Returns total Medicare taxes for the given year
  /// [person] - Identifies the person for which the Medicare tax should be calculated.
  /// When [person] is not specified, the return value includes both the self and spouse Mecicare taxes.
  double medicareTax({PersonInventory? person}) {
    double result = 0;
    if (person != null) {
      result = person.regularIncome * _medicareTaxRate +
          person.selfEmploymentIncome *
              FicaTaxRules.selfEmploymentTaxableIncomeRate *
              _medicareTaxRate *
              2;
    } else {
      result = medicareTax(person: filingSettings.selfInventory);
      if (filingSettings.filingStatus.isMarried) {
        result += medicareTax(person: filingSettings.spouseInventory);
      }
    }
    return result.roundToTwoPlaces();
  }

  /// Returns total Medicare tax adjustmemt / deduction for the given year
  /// [person] - Identifies the person for which the Medicare tax adjustement should be calculated.
  /// When [person] is not specified, the return value includes both the self and spouse Mecicare tax adjustements.
  double medicareTaxAdjustment({PersonInventory? person}) {
    double result = 0;
    if (person != null) {
      // Medicare taxes on regular income do not impact IRS's AGI, MAGI or taxes.
      // However, Medicare taxes for self-employment income allows an adjustement of 1/2 the total taxes paid.
      result = person.selfEmploymentIncome *
          FicaTaxRules.selfEmploymentTaxableIncomeRate *
          _medicareTaxRate;
    } else {
      result = medicareTaxAdjustment(person: filingSettings.selfInventory);
      if (filingSettings.filingStatus.isMarried) {
        result += medicareTaxAdjustment(person: filingSettings.spouseInventory);
      }
    }
    return result.roundToTwoPlaces();
  }
}
