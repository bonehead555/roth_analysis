// define a type that can hold configuration for test cases
import 'package:roth_analysis/services/analysis_services/rmd_estimator.dart';
import 'package:test/test.dart';

typedef TestCase = ({
  DateTime birthdate,
  double iraBalance,
  int targetYear,
  double expected
});

void runTestCases(
  List<TestCase> testCases,
) {
  // Execute the test cases
  int index = 1;
  for (final testCase in testCases) {
    test('($index) IRMAA Adjustement for $testCase', () {
      double rmd = rmdEstimator(
          testCase.iraBalance, testCase.birthdate, testCase.targetYear);
      expect(rmd, testCase.expected);
    });
    index++;
  }
}

main() {
  group(
    'RMD Estimator Test Cases',
    () {
      final List<TestCase> testCases = [
        (
          birthdate: DateTime(1950, 03, 04),
          iraBalance: 1000000.00,
          targetYear: 2021,
          expected: 0,
        ),
        (
          birthdate: DateTime(1950, 03, 04),
          iraBalance: 1000000.00,
          targetYear: 2022,
          expected: 36496.35,
        ),
        (
          birthdate: DateTime(1950, 03, 04),
          iraBalance: 1000000.00,
          targetYear: 2023,
          expected: 37735.85,
        ),
        (
          birthdate: DateTime(1950, 03, 04),
          iraBalance: 1000000.00,
          targetYear: 2030,
          expected: 49504.95,
        ),
        (
          birthdate: DateTime(1950, 03, 04),
          iraBalance: 1000000.00,
          targetYear: 2069,
          expected: 434782.61,
        ),
        (
          birthdate: DateTime(1950, 03, 04),
          iraBalance: 1000000.00,
          targetYear: 2070,
          expected: 500000,
        ),
        (
          birthdate: DateTime(1950, 03, 04),
          iraBalance: 1000000.00,
          targetYear: 2071,
          expected: 500000,
        ),
        (
          birthdate: DateTime(1949, 03, 04),
          iraBalance: 1000000.00,
          targetYear: 2018,
          expected: 0.0,
        ),
        (
          birthdate: DateTime(1949, 03, 04),
          iraBalance: 1000000.00,
          targetYear: 2019,
          expected: 36496.35,
        ),
        (
          birthdate: DateTime(1949, 03, 04),
          iraBalance: 1000000.00,
          targetYear: 2025,
          expected: 45454.55,
        ),
        (
          birthdate: DateTime(1951, 01, 01),
          iraBalance: 1000000.00,
          targetYear: 2023,
          expected: 0.0,
        ),
        (
          birthdate: DateTime(1951, 01, 01),
          iraBalance: 1000000.00,
          targetYear: 2024,
          expected: 37735.85,
        ),
        (
          birthdate: DateTime(1951, 01, 01),
          iraBalance: 1000000.00,
          targetYear: 2070,
          expected: 434782.61,
        ),
        (
          birthdate: DateTime(1951, 01, 01),
          iraBalance: 1000000.00,
          targetYear: 2071,
          expected: 500000,
        ),
      ];
      runTestCases(testCases);
    },
  );
}
