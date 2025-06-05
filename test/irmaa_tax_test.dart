import 'package:roth_analysis/services/tax_services/irmaa_tax.dart';
import 'package:roth_analysis/models/enums/filing_state.dart';
import 'package:roth_analysis/services/tax_services/tax_filing_settings.dart';
import 'package:roth_analysis/models/enums/filing_status.dart';
import 'package:test/test.dart';

// define a type that can hold configuration for test cases
typedef TestCase = ({
  FilingStatus filingStatus,
  int targetYear,
  int selfAge,
  int spouseAge,
  double selfIrmaaMAGI,
  double spouseIrmaaMAGI,
  double expected,
});

void runTestCases(
  String testName,
  TaxFilingSettings initialFilingSettings,
  List<TestCase> testCases,
  double Function(IrmaaTaxByFilingStatus irmaaBFS, TaxFilingSettings filingSettings) testFunction,
) {
  // Execute the test cases
  int index = 1;
  for (final testCase in testCases) {
    var filingSettings = initialFilingSettings.copyWith(
      targetYear: testCase.targetYear,
      filingStatus: testCase.filingStatus,
      selfInventory: initialFilingSettings.selfInventory.copyWith(age: testCase.selfAge, prevPrevYearsMAGI: testCase.selfIrmaaMAGI),
      spouseInventory: initialFilingSettings.spouseInventory!.copyWith(age: testCase.spouseAge, prevPrevYearsMAGI: testCase.spouseIrmaaMAGI),
      );
    test('($index) $testName for $testCase', () {
      final irmaaBFS = IrmaaTaxByFilingStatus(filingSettings);
      final irmaaAdjustment = testFunction(irmaaBFS, filingSettings);
      expect(irmaaAdjustment, testCase.expected);
    });
    index++;
  }
}

main() {
  group(
    'IRMAA Test Cases',
    () {
      final List<TestCase> testCases = [
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 176000,
          spouseIrmaaMAGI: 0,
          expected: 0
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 176001,
          spouseIrmaaMAGI: 0,
          expected: 1720
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 222000,
          spouseIrmaaMAGI: 0,
          expected: 1720
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 222001,
          spouseIrmaaMAGI: 0,
          expected: 4328
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 276000,
          spouseIrmaaMAGI: 0,
          expected: 4328
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 276001,
          spouseIrmaaMAGI: 0,
          expected: 6932
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 330000,
          spouseIrmaaMAGI: 0,
          expected: 6932
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 330001,
          spouseIrmaaMAGI: 0,
          expected: 9538
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 750000,
          spouseIrmaaMAGI: 0,
          expected: 9538
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 750001,
          spouseIrmaaMAGI: 0,
          expected: 10404
        ),
        (
          filingStatus: FilingStatus.marriedFilingSeparately,
          targetYear: 2021,
          selfAge: 64,
          spouseAge: 66,
          selfIrmaaMAGI: 750001,
          spouseIrmaaMAGI: 0,
          expected: 0.0
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 64,
          spouseAge: 66,
          selfIrmaaMAGI: 750001,
          spouseIrmaaMAGI: 0,
          expected: 5202.0
        ),
        (
          filingStatus: FilingStatus.single,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 176000,
          spouseIrmaaMAGI: 0,
          expected: 4769
        ),
        (
          filingStatus: FilingStatus.marriedFilingSeparately,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 176000,
          spouseIrmaaMAGI: 0,
          expected: 4769
        ),
        (
          filingStatus: FilingStatus.headOfHousehold,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 176000,
          spouseIrmaaMAGI: 0,
          expected: 4769
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2031,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 226336,
          spouseIrmaaMAGI: 0,
          expected: 0
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2031,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 285492,
          spouseIrmaaMAGI: 0,
          expected: 2410.0
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2031,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 354936,
          spouseIrmaaMAGI: 0,
          expected: 6052.0
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2031,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 424380,
          spouseIrmaaMAGI: 0,
          expected: 9690.0
        ),
       (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2031,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 192900,
          spouseIrmaaMAGI: 192900,
          expected: 6052.0
        ),
      ];
      final filingSettings = TaxFilingSettings(
        targetYear: 2021,
        filingStatus: FilingStatus.headOfHousehold,
        filingState: FilingState.other,
        selfInventory: PersonInventory(age: 65, isBlind: false),
        spouseInventory: PersonInventory(age: 65, isBlind: false),
      );
      runTestCases('IRMAA Adjustement', filingSettings, testCases,
          (IrmaaTaxByFilingStatus irmaaBFS,  TaxFilingSettings filingSettings) {
        return irmaaBFS.calcTaxes();
      });
    },
  );

  group(
    'Medicare Cost Test Cases',
    () {
      final List<TestCase> testCases = [
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 176000,
          spouseIrmaaMAGI: 0,
          expected: 3564
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 222000,
          spouseIrmaaMAGI: 0,
          expected: 5284.8
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 276000,
          spouseIrmaaMAGI: 0,
          expected: 7891.2
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 330000,
          spouseIrmaaMAGI: 0,
          expected: 10495.2
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 750000,
          spouseIrmaaMAGI: 0,
          expected: 13101.6
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 65,
          spouseAge: 66,
          selfIrmaaMAGI: 750001,
          spouseIrmaaMAGI: 0,
          expected: 13968
        ),
        (
          filingStatus: FilingStatus.marriedFilingSeparately,
          targetYear: 2021,
          selfAge: 64,
          spouseAge: 65,
          selfIrmaaMAGI: 750001,
          spouseIrmaaMAGI: 0,
          expected: 1782.0
        ),
        (
          filingStatus: FilingStatus.marriedFilingJointly,
          targetYear: 2021,
          selfAge: 64,
          spouseAge: 65,
          selfIrmaaMAGI: 750001,
          spouseIrmaaMAGI: 0,
          expected: 6984.0
        ),
      ];
      final filingSettings = TaxFilingSettings(
        targetYear: 2021,
        filingStatus: FilingStatus.headOfHousehold,
        filingState: FilingState.other,
        selfInventory: PersonInventory(age: 65, isBlind: false),
        spouseInventory: PersonInventory(age: 65, isBlind: false),
      );
      runTestCases('Medicare Cost', filingSettings, testCases,
          (IrmaaTaxByFilingStatus irmaaBFS, TaxFilingSettings filingSettings) {
        return irmaaBFS.calcMedicareCost();
      });
    },
  );
}
