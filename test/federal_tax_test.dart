import 'package:roth_analysis/services/tax_services/federal_tax.dart';
import 'package:roth_analysis/models/enums/filing_state.dart';
import 'package:roth_analysis/services/tax_services/tax_filing_settings.dart';
import 'package:roth_analysis/models/enums/filing_status.dart';
import 'package:test/test.dart';

// define a type that can hold configuration for test cases
typedef TestCase = ({
  double ssIncome,
  double rmdIncome,
  double capGains,
  double interestIncome,
  double regularIncome,
  double selfEmployment,
  double expected,
});

void runTestCases(
  TaxFilingSettings initialSettings,
  List<TestCase> testCases,
) {
  int testNum = 0;
  for (final testCase in testCases) {
    var settings = initialSettings.copyWith(
      selfInventory: initialSettings.selfInventory.copyWith(
        ssIncome: testCase.ssIncome,
        iraDistributions: testCase.rmdIncome,
        regularIncome: testCase.regularIncome,
        selfEmploymentIncome: testCase.selfEmployment,
        interestIncome: testCase.interestIncome,
        capitalGainsIncome: testCase.capGains,
      ),
    );
    var expected = testCase.expected;
    testNum += 1;
    test('($testNum) Federal Tax for: $testCase', () {
      FederalTaxByFilingStatus federalTBFS = FederalTaxByFilingStatus(settings);
      final double tax = federalTBFS.calcIncomeTax();
      expect(tax, expected);
    });
  }
}

void main() {
  group(
      'Federal Tax Test Cases for filingStatus: marriedFilingJointly, year: 2021',
      () {
    // define the range of test cases
    final List<TestCase> testCases = [
      (
        ssIncome: 0,
        rmdIncome: 19900,
        capGains: 0,
        interestIncome: 26450,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 1990
      ),
      (
        ssIncome: 0,
        rmdIncome: 19900,
        capGains: 0,
        interestIncome: 0,
        regularIncome: 26450,
        selfEmployment: 0,
        expected: 1990.0
      ),
      (
        ssIncome: 0,
        rmdIncome: 19900,
        capGains: 0,
        interestIncome: 0,
        regularIncome: 0,
        selfEmployment: 26450,
        expected: 1803
      ),
      (
        ssIncome: 0,
        rmdIncome: 81050,
        capGains: 0,
        interestIncome: 26450,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 9328
      ),
      (
        ssIncome: 0,
        rmdIncome: 172750,
        capGains: 0,
        interestIncome: 26450,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 29502
      ),
      (
        ssIncome: 0,
        rmdIncome: 329850,
        capGains: 0,
        interestIncome: 26450,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 68211
      ),
      (
        ssIncome: 0,
        rmdIncome: 418850,
        capGains: 0,
        interestIncome: 26450,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 96691.0
      ),
      (
        ssIncome: 0,
        rmdIncome: 628300,
        capGains: 0,
        interestIncome: 26450,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 169999.0
      ),
      (
        ssIncome: 0,
        rmdIncome: 1000000,
        capGains: 0,
        interestIncome: 26450,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 307528.0
      ),
      (
        ssIncome: 0,
        rmdIncome: 38282,
        capGains: 42518,
        interestIncome: 26450,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 4196
      ),
    ];
    final settings = TaxFilingSettings(
      targetYear: 2021,
      filingStatus: FilingStatus.marriedFilingJointly,
      filingState: FilingState.other,
      selfInventory: PersonInventory(age: 66, isBlind: false),
      spouseInventory: PersonInventory(age: 64, isBlind: false),
    );
    runTestCases(settings, testCases);
  });

  group('Some of the same Federal Tax Test Cases again, but with spouse blind',
      () {
    // define the range of test cases
    final List<TestCase> testCases = [
      (
        ssIncome: 0,
        rmdIncome: 19900,
        capGains: 0,
        interestIncome: 26450,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 1855
      ),
      (
        ssIncome: 0,
        rmdIncome: 81050,
        capGains: 0,
        interestIncome: 26450,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 9166
      ),
      (
        ssIncome: 0,
        rmdIncome: 172750,
        capGains: 0,
        interestIncome: 26450,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 29205
      ),
    ];
    // define the federal filing status settings
    final settings = TaxFilingSettings(
      targetYear: 2021,
      filingStatus: FilingStatus.marriedFilingJointly,
      filingState: FilingState.other,
      selfInventory: PersonInventory(age: 66, isBlind: false),
      spouseInventory: PersonInventory(age: 64, isBlind: true),
    );
    // Execute the test cases
    runTestCases(settings, testCases);
  });

  group("Federal Tax Test Cases for filingStatus: headOfHousehold, year: 2021",
      () {
    // define the federal filing status settings
    final settings = TaxFilingSettings(
      targetYear: 2021,
      filingStatus: FilingStatus.headOfHousehold,
      filingState: FilingState.other,
      selfInventory: PersonInventory(age: 64, isBlind: false),
    );
    // define the range of test cases
    final List<TestCase> testCases = [
      (
        ssIncome: 0,
        rmdIncome: 14200,
        capGains: 0,
        interestIncome: 18800,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 1420
      ),
      (
        ssIncome: 0,
        rmdIncome: 54200,
        capGains: 0,
        interestIncome: 18800,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 6220
      ),
      (
        ssIncome: 0,
        rmdIncome: 86350,
        capGains: 0,
        interestIncome: 18800,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 13293
      ),
    ];
    // Execute the test cases
    runTestCases(settings, testCases);
  });

  group("Federal Tax Test Cases for filingStatus: headOfHousehold, year: 2024",
      () {
    // define the federal filing status settings
    final settings = TaxFilingSettings(
      targetYear: 2024,
      filingStatus: FilingStatus.headOfHousehold,
      filingState: FilingState.other,
      selfInventory: PersonInventory(age: 64, isBlind: false),
    );
    // define the range of test cases
    final List<TestCase> testCases = [
      (
        ssIncome: 0,
        rmdIncome: 14200,
        capGains: 0,
        interestIncome: 18800,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 1110
      ),
      (
        ssIncome: 0,
        rmdIncome: 54200,
        capGains: 0,
        interestIncome: 18800,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 5801
      ),
      (
        ssIncome: 0,
        rmdIncome: 86350,
        capGains: 0,
        interestIncome: 18800,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 11674
      ),
    ];
    // Execute the test cases
    runTestCases(settings, testCases);
  });
  group("Federal Tax Test Cases for filingStatus: headOfHousehold, year: 2023",
      () {
    // define the federal filing status settings
    final settings = TaxFilingSettings(
      targetYear: 2023,
      filingStatus: FilingStatus.headOfHousehold,
      filingState: FilingState.other,
      selfInventory: PersonInventory(age: 64, isBlind: false),
    );
    // define the range of test cases
    final List<TestCase> testCases = [
      (
        ssIncome: 0,
        rmdIncome: 14200,
        capGains: 0,
        interestIncome: 18800,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 1323
      ),
      (
        ssIncome: 0,
        rmdIncome: 54200,
        capGains: 0,
        interestIncome: 18800,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 6089
      ),
      (
        ssIncome: 0,
        rmdIncome: 86350,
        capGains: 0,
        interestIncome: 18800,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 12784
      ),
    ];
    // Execute the test cases
    runTestCases(settings, testCases);
  });
  group(
      'Federal Tax Test Cases for filingStatus: marriedFilingJointly, year: 2025',
      () {
    // define the range of test cases
    final List<TestCase> testCases = [
      (
        ssIncome: 0,
        rmdIncome: 19900,
        capGains: 0,
        interestIncome: 26450,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 0.0
      ),
      (
        ssIncome: 0,
        rmdIncome: 125000,
        capGains: 0,
        interestIncome: 25000,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 12554.0
      ),
      (
        ssIncome: 0,
        rmdIncome: 172750,
        capGains: 0,
        interestIncome: 26450,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 24677
      ),
      (
        ssIncome: 0,
        rmdIncome: 329850,
        capGains: 0,
        interestIncome: 26450,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 63883.0
      ),
      (
        ssIncome: 0,
        rmdIncome: 418850,
        capGains: 0,
        interestIncome: 26450,
        regularIncome: 0,
        selfEmployment: 0,
        expected: 86523.0
      ),
    ];
    final settings = TaxFilingSettings(
      targetYear: 2025,
      filingStatus: FilingStatus.marriedFilingJointly,
      filingState: FilingState.other,
      selfInventory: PersonInventory(age: 66, isBlind: false),
      spouseInventory: PersonInventory(age: 65, isBlind: false),
    );
    runTestCases(settings, testCases);
  });
}
