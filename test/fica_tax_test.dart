import 'package:roth_analysis/services/tax_services/tax_filing_settings.dart';
import 'package:roth_analysis/models/enums/filing_state.dart';
import 'package:roth_analysis/models/enums/filing_status.dart';
import 'package:roth_analysis/services/tax_services/fica_tax.dart';
import 'package:test/test.dart';

enum TestType {
  ficaTax('FICA Tax'),
  medicareTax('Medicare Tax'),
  ficaTaxExemption('FICA Tax Exemption'),
  medicareTaxExemption('Medicare Tax Exemption');

  final String label;
  const TestType(this.label);
}

// define a type that can hold configuration for test cases
typedef TestCase = ({
  int targetYear,
  FilingStatus filingStatus,
  double regularIncome,
  double selfEmploymentIncome,
  double expectedFicaTax,
  double expectedMedicareTax,
  double expectedFicaTaxExemption,
  double expectedMedicareTaxExemption,
});

void runTestCases(TaxFilingSettings initialSettings,
    List<TestCase> testCases, TestType testType) {
  int testNum = 0;
  for (final testCase in testCases) {
    PersonInventory self = initialSettings.selfInventory.copyWith(
      regularIncome: testCase.regularIncome,
      selfEmploymentIncome: testCase.selfEmploymentIncome,
    );

    PersonInventory? spouse = testCase.filingStatus.isMarried
        ? initialSettings.spouseInventory!.copyWith(
            regularIncome: testCase.regularIncome,
            selfEmploymentIncome: testCase.selfEmploymentIncome,
          )
        : null;

    var settings = initialSettings.copyWith(
      targetYear: testCase.targetYear,
      filingStatus: testCase.filingStatus,
      selfInventory: self,
      spouseInventory: spouse,
    );

    testNum++;
    double expected;
    switch (testType) {
      case TestType.ficaTax:
        expected = testCase.expectedFicaTax;
        break;
      case TestType.medicareTax:
        expected = testCase.expectedMedicareTax;
        break;
      case TestType.ficaTaxExemption:
        expected = testCase.expectedFicaTaxExemption;
        break;
      case TestType.medicareTaxExemption:
        expected = testCase.expectedMedicareTaxExemption;
        break;
    }
    final FicaTax ficaTax = FicaTax(settings);

    test('($testNum) ${testType.label} for: $testCase', () {
      double result;
      switch (testType) {
        case TestType.ficaTax:
          result = ficaTax.ficaTax();
          break;
        case TestType.medicareTax:
          result = ficaTax.medicareTax();
          break;
        case TestType.ficaTaxExemption:
          result = ficaTax.ficaTaxAdjustment();
          break;
        case TestType.medicareTaxExemption:
          result = ficaTax.medicareTaxAdjustment();
          break;
      }
      expect(result.roundToDouble(), expected);
    });
  }
}

void main() {
  // define the range of test cases
  final List<TestCase> ficaTestCases = [
    (
      targetYear: 2021,
      filingStatus: FilingStatus.single,
      regularIncome: 50000,
      selfEmploymentIncome: 50000,
      expectedFicaTax: 8826,
      expectedMedicareTax: 2064,
      expectedFicaTaxExemption: 2863,
      expectedMedicareTaxExemption: 670.0,
    ),
    (
      targetYear: 2021,
      filingStatus: FilingStatus.single,
      regularIncome: 100000,
      selfEmploymentIncome: 100000,
      expectedFicaTax: 11507,
      expectedMedicareTax: 4128,
      expectedFicaTaxExemption: 2654,
      expectedMedicareTaxExemption: 1339.0,
    ),
    (
      targetYear: 2021,
      filingStatus: FilingStatus.marriedFilingJointly,
      regularIncome: 50000,
      selfEmploymentIncome: 50000,
      expectedFicaTax: 17651,
      expectedMedicareTax: 4128,
      expectedFicaTaxExemption: 5726.0,
      expectedMedicareTaxExemption: 1339.0,
    ),
    (
      targetYear: 2021,
      filingStatus: FilingStatus.marriedFilingJointly,
      regularIncome: 100000,
      selfEmploymentIncome: 100000,
      expectedFicaTax: 23014,
      expectedMedicareTax: 8256.0,
      expectedFicaTaxExemption: 5307.0,
      expectedMedicareTaxExemption: 2678.0,
    ),
    (
      targetYear: 2025,
      filingStatus: FilingStatus.single,
      regularIncome: 50000,
      selfEmploymentIncome: 50000,
      expectedFicaTax: 8826,
      expectedMedicareTax: 2064,
      expectedFicaTaxExemption: 2863.0,
      expectedMedicareTaxExemption: 670.0,
    ),
    (
      targetYear: 2025,
      filingStatus: FilingStatus.single,
      regularIncome: 100000,
      selfEmploymentIncome: 100000,
      expectedFicaTax: 15636,
      expectedMedicareTax: 4128,
      expectedFicaTaxExemption: 4718.0,
      expectedMedicareTaxExemption: 1339.0,
    ),
    (
      targetYear: 2030,
      filingStatus: FilingStatus.single,
      regularIncome: 150000,
      selfEmploymentIncome: 150000,
      expectedFicaTax: 15469,
      expectedMedicareTax: 6192,
      expectedFicaTaxExemption: 3085.0,
      expectedMedicareTaxExemption: 2009.0,
    ),
  ];

  group('FICA Tax Test Cases', () {
    final settings = TaxFilingSettings(
      targetYear: 0,
      filingStatus: FilingStatus.single,
      filingState: FilingState.other,
      selfInventory: PersonInventory(age: 66, isBlind: false),
      spouseInventory: PersonInventory(age: 62, isBlind: false),
    );
    runTestCases(settings, ficaTestCases, TestType.ficaTax);
  });

  group('Medicare Tax Test Cases', () {
    final settings = TaxFilingSettings(
      targetYear: 0,
      filingStatus: FilingStatus.single,
      filingState: FilingState.other,
      selfInventory: PersonInventory(age: 66, isBlind: false),
      spouseInventory: PersonInventory(age: 62, isBlind: false),
    );
    runTestCases(settings, ficaTestCases, TestType.medicareTax);
  });

  group('FICA Tax Exemption Test Cases', () {
    final settings = TaxFilingSettings(
      targetYear: 0,
      filingStatus: FilingStatus.single,
      filingState: FilingState.other,
      selfInventory: PersonInventory(age: 66, isBlind: false),
      spouseInventory: PersonInventory(age: 62, isBlind: false),
    );
    runTestCases(settings, ficaTestCases, TestType.ficaTaxExemption);
  });

  group('Medicare Tax Exemption Test Cases', () {
    final settings = TaxFilingSettings(
      targetYear: 0,
      filingStatus: FilingStatus.single,
      filingState: FilingState.other,
      selfInventory: PersonInventory(age: 66, isBlind: false),
      spouseInventory: PersonInventory(age: 62, isBlind: false),
    );
    runTestCases(settings, ficaTestCases, TestType.medicareTaxExemption);
  });
}
