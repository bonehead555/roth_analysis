// define a type that can hold configuration for state test cases
import 'package:roth_analysis/models/enums/filing_state.dart';
import 'package:roth_analysis/services/tax_services/tax_filing_settings.dart';
import 'package:roth_analysis/models/enums/filing_status.dart';
import 'package:roth_analysis/services/tax_services/state_tax/state_tax.dart';
import 'package:test/test.dart';

typedef TestCase = ({
  FilingState filingState,
  FilingStatus filingStatus,
  int targetYear,
  double ssIncome,
  double interest,
  double dividends,
  double rmdIncome,
  double capGains,
  double regularIncome,
  double selfEmploymentIncome,
  double pensionIncome,
  double expected,
});

void runTestCases(List<TestCase> testCases) {
  for (final testCase in testCases) {
    double selfRatio = 1;
    double spouseRatio = 0;
    if (testCase.filingStatus.isMarried) {
      selfRatio = 0.6;
      spouseRatio = 1 - selfRatio;
    }
    var settings = TaxFilingSettings(
        filingStatus: testCase.filingStatus,
        filingState: testCase.filingState,
        targetYear: testCase.targetYear,
        stateTaxPercentage: 4.0,
        selfInventory: PersonInventory(
          age: 64,
          isBlind: false,
          ssIncome: testCase.ssIncome * selfRatio,
          interestIncome: testCase.interest * selfRatio,
          dividendIncome: testCase.dividends * selfRatio,
          iraDistributions: testCase.rmdIncome * selfRatio,
          capitalGainsIncome: testCase.capGains * selfRatio,
          regularIncome: testCase.regularIncome * selfRatio,
        ),
        spouseInventory: PersonInventory(
          age: 64,
          isBlind: false,
          ssIncome: testCase.ssIncome * spouseRatio,
          interestIncome: testCase.interest * spouseRatio,
          dividendIncome: testCase.dividends * spouseRatio,
          iraDistributions: testCase.rmdIncome * spouseRatio,
          capitalGainsIncome: testCase.capGains * spouseRatio,
          regularIncome: testCase.regularIncome * spouseRatio,
        ));
    var expected = testCase.expected;
    test('${settings.filingState.label} Tax for: $testCase', () {
      double tax = calcStateTax(settings);
      expect(tax, expected);
    });
  }
}

void main() {
  group('State Tax Test Cases for filingStatus: single', () {
    // define the range of test cases
    final List<TestCase> testCases = [
      (
        filingState: FilingState.tx,
        filingStatus: FilingStatus.single,
        targetYear: 2024,
        ssIncome: 0.0,
        interest: 0.0,
        dividends: 0.0,
        rmdIncome: 0.0,
        capGains: 0.0,
        regularIncome: 50000.0,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 0.0
      ),
      (
        filingState: FilingState.tx,
        filingStatus: FilingStatus.marriedFilingSeparately,
        targetYear: 2024,
        ssIncome: 0,
        interest: 0,
        dividends: 0,
        rmdIncome: 0,
        capGains: 0,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 0
      ),
      (
        filingState: FilingState.co,
        filingStatus: FilingStatus.single,
        targetYear: 2024,
        ssIncome: 0,
        interest: 0,
        dividends: 0,
        rmdIncome: 0,
        capGains: 0,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 2125
      ),
      (
        filingState: FilingState.co,
        filingStatus: FilingStatus.marriedFilingSeparately,
        targetYear: 2024,
        ssIncome: 0,
        interest: 0,
        dividends: 0,
        rmdIncome: 0,
        capGains: 0,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 2125
      ),
      (
        filingState: FilingState.nh,
        filingStatus: FilingStatus.single,
        targetYear: 2024,
        ssIncome: 0,
        interest: 25000,
        dividends: 25000,
        rmdIncome: 0,
        capGains: 0,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 1428
      ),
      (
        filingState: FilingState.nh,
        filingStatus: FilingStatus.marriedFilingSeparately,
        targetYear: 2024,
        ssIncome: 0,
        interest: 25000,
        dividends: 25000,
        rmdIncome: 0,
        capGains: 0,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 1356
      ),
      (
        filingState: FilingState.nh,
        filingStatus: FilingStatus.single,
        targetYear: 2023,
        ssIncome: 0,
        interest: 25000,
        dividends: 25000,
        rmdIncome: 0,
        capGains: 0,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 1904
      ),
      (
        filingState: FilingState.wa,
        filingStatus: FilingStatus.single,
        targetYear: 2024,
        ssIncome: 0,
        interest: 0,
        dividends: 0,
        rmdIncome: 0,
        capGains: 300000,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 2100
      ),
      (
        filingState: FilingState.wa,
        filingStatus: FilingStatus.marriedFilingJointly,
        targetYear: 2024,
        ssIncome: 0,
        interest: 0,
        dividends: 0,
        rmdIncome: 0,
        capGains: 300000,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 2100
      ),
      (
        filingState: FilingState.wa,
        filingStatus: FilingStatus.single,
        targetYear: 2023,
        ssIncome: 0,
        interest: 0,
        dividends: 0,
        rmdIncome: 0,
        capGains: 300000,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 2660
      ),
      (
        filingState: FilingState.wa,
        filingStatus: FilingStatus.single,
        targetYear: 2021,
        ssIncome: 0,
        interest: 0,
        dividends: 0,
        rmdIncome: 0,
        capGains: 300000,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 0
      ),
      (
        filingState: FilingState.wa,
        filingStatus: FilingStatus.single,
        targetYear: 2030,
        ssIncome: 0,
        interest: 0,
        dividends: 0,
        rmdIncome: 0,
        capGains: 360000,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 1391
      ),
      (
        filingState: FilingState.oh,
        filingStatus: FilingStatus.single,
        targetYear: 2024,
        ssIncome: 0,
        interest: 0,
        dividends: 0,
        rmdIncome: 0,
        capGains: 0,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 1019
      ),
      (
        filingState: FilingState.oh,
        filingStatus: FilingStatus.single,
        targetYear: 2030,
        ssIncome: 0,
        interest: 0,
        dividends: 0,
        rmdIncome: 0,
        capGains: 0,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 961
      ),
      (
        filingState: FilingState.oh,
        filingStatus: FilingStatus.marriedFilingSeparately,
        targetYear: 2024,
        ssIncome: 0,
        interest: 0,
        dividends: 0,
        rmdIncome: 0,
        capGains: 0,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 469
      ),
      (
        filingState: FilingState.oh,
        filingStatus: FilingStatus.single,
        targetYear: 2023,
        ssIncome: 0,
        interest: 0,
        dividends: 0,
        rmdIncome: 0,
        capGains: 0,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 1036
      ),
      (
        filingState: FilingState.other,
        filingStatus: FilingStatus.single,
        targetYear: 2023,
        ssIncome: 0,
        interest: 0,
        dividends: 0,
        rmdIncome: 0,
        capGains: 0,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 2000
      ),
      (
        filingState: FilingState.other,
        filingStatus: FilingStatus.marriedFilingJointly,
        targetYear: 2023,
        ssIncome: 0,
        interest: 0,
        dividends: 0,
        rmdIncome: 0,
        capGains: 0,
        regularIncome: 50000,
        selfEmploymentIncome: 0.0,
        pensionIncome: 0.0,
        expected: 2000
      ),
    ];
    runTestCases(testCases);
  });
    group('State Tax Test Cases for filingStatus: single', () {

    });

}
