import 'package:roth_analysis/services/tax_services/tax_filing_settings.dart';
import 'package:roth_analysis/models/enums/filing_state.dart';
import 'package:roth_analysis/models/enums/filing_status.dart';
import 'package:roth_analysis/services/tax_services/local_tax.dart';
import 'package:test/test.dart';

// define a type that can hold configuration for test cases
typedef TestCase = ({
  FilingStatus filingStatus,
  double regularIncome,
  double selfEmploymentIncome,
  double localTaxPercentage,
  double expected,
});

void runTestCases(
    TaxFilingSettings initialSettings, List<TestCase> testCases) {
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
      filingStatus: testCase.filingStatus,
      localTaxPercentage: testCase.localTaxPercentage,
      selfInventory: self,
      spouseInventory: spouse,
    );

    testNum++;
    test('($testNum) Local Tax for: $testCase', () {
      double expected = testCase.expected;
      final LocalTax localTax = LocalTax(settings);
      final double result = localTax.calcTaxes();
      expect(result, expected);
    });
  }
}

void main() {
  // define the range of test cases
  final List<TestCase> testCases = [
    (
      filingStatus: FilingStatus.single,
      regularIncome: 50000,
      selfEmploymentIncome: 50000,
      localTaxPercentage: 1.0,
      expected: 1000,
    ),    (
      filingStatus: FilingStatus.marriedFilingJointly,
      regularIncome: 50000,
      selfEmploymentIncome: 50000,
      localTaxPercentage: 2.0,
      expected: 4000,
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
    runTestCases(settings, testCases);
  });
}
