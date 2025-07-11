import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import 'package:roth_analysis/models/data/account_info.dart';
import 'package:roth_analysis/models/data/income_info.dart';
import 'package:roth_analysis/models/data/person_info.dart';
import 'package:roth_analysis/models/data/plan_info.dart';
import 'package:roth_analysis/models/data/scenario_info.dart';
import 'package:roth_analysis/models/data/tax_filing_info.dart';
import 'package:roth_analysis/models/enums/account_type.dart';
import 'package:roth_analysis/models/enums/filing_state.dart';
import 'package:roth_analysis/models/enums/filing_status.dart';
import 'package:roth_analysis/models/enums/income_type.dart';
import 'package:roth_analysis/models/enums/owner_type.dart';
import 'package:roth_analysis/models/enums/scenario_enums.dart';
import 'package:roth_analysis/services/analysis_services/analysis_config.dart';
import 'package:roth_analysis/services/analysis_services/plan_analysis.dart';
import 'package:roth_analysis/services/analysis_services/plan_results.dart';
import 'package:roth_analysis/services/analysis_services/transaction_log.dart';
import 'package:roth_analysis/services/message_service.dart';

main() {
  group('Invalid Configuration Tests;', () {
    test('EmptyAnalysis', () {
      expect(EmptyAnalysis().runTest(), '');
    });
    test('InvalidAnalysis', () {
      expect(InvalidAnalysis().runTest(), '');
    });
  });

  group('Single Property Tests', () {
    test('JustInvestmentGains', () {
      expect(JustInvestmentGains().runTest(), '');
    });
    test('JustIncome', () {
      expect(JustIncome().runTest(), '');
    });
   test('JustCola', () {
      expect(JustCola().runTest(), '');
    });
    test('JustFixedConversionSufficientTaxableAssets', () {
      expect(JustFixedConversionSufficientTaxableAssets().runTest(), '');
    });
    test('JustFixedConversionInsufficientTaxableAssets', () {
      expect(JustFixedConversionInsufficientTaxableAssets().runTest(), '');
    });
    test('JustFixedConversionAllowIraForTaxes', () {
      expect(JustFixedConversionAllowIraForTaxes().runTest(), '');
    });
    test('JustMagiLimitSufficientTaxableAssets', () {
      expect(JustMagiLimitSufficientTaxableAssets().runTest(), '');
    });
    test('JustMagiLimitInsufficientTaxableAssets', () {
      expect(JustMagiLimitInsufficientTaxableAssets().runTest(), '');
    });
    test('JustMagiLimitAllowIraForTaxes', () {
      expect(JustMagiLimitAllowIraForTaxes().runTest(), '');
    });
  });

  group('Single Tests', () {
    test('SingleMultipleAccountsFixedConversionSufficientTaxableAsssets', () {
      expect(SingleMultipleAccountsFixedConversionSufficientTaxableAsssets().runTest(), '');
    });
  });

  group('MarriedFilingJointly Tests', () {
    test('JustMarried', () {
      expect(JustMarried().runTest(), '');
    });
    test('MarriedFixedConversionSufficientTaxableAsssets', () {
      expect(MarriedFixedConversionSufficientTaxableAsssets().runTest(), '');
    });
  });


  group('Full Year Monthly Plan Test Cases; with even results', () {
    test('SimpleAnalysis', () {
      expect(SimpleAnalysis().runTest(), '');
    });
    test('SimpleWithSS', () {
      expect(SimpleWithSS().runTest(), '');
    });
    test('SimpleWithEmployment', () {
      expect(SimpleWithEmployment().runTest(), '');
    });
  });
}

abstract class AnalysisTest {
  final String testName;
  final AnalysisConfig analysisConfig;
  AnalysisTest({required this.testName, required this.analysisConfig});

  String runTest() {
    // Build path to the file to be used to write test results.
    final String resultFilePath = p.setExtension(
        p.join(Directory.current.path, 'test', 'results', testName), '.csv');
    // Build path to the file to be used to verify test results.
    final String verifiedResultsFilePath = p.setExtension(
        p.join(Directory.current.path, 'test', 'results', 'verified', testName),
        '.csv');
    final String differenceFilePath = p.setExtension(
        p.join(
            Directory.current.path, 'test', 'results', 'differences', testName),
        '.diff');

    // Create the AnalysisCconfig and check for errors.
    final MessageService messageService = analysisConfig.messageService;

    // If the AnalysisCconfig has errors the analysis cannot be run so
    // just dump the errors to the associated results file.
    if (messageService.counts > 0) {
      messageService.dumpToFile(resultFilePath);
    } else {
      // Otherwise, we run the analysis
      // and dump the analysis transaction log to the associated results file.
      final PlanAnalysis planAnalysis =
          PlanAnalysis(analysisConfig: analysisConfig);
      final PlanResult planResults = planAnalysis.planResults;
      // Dump the Plans TReasactionLog to a file.
      TransactionLog transactionLog =
          planResults.scenarioResults[0].transactionLog;
      transactionLog.dumpToFile(resultFilePath);
    }

    // Compare the resultFile.
    final String fileDifferences =
        compareFilesLineByLine(verifiedResultsFilePath, resultFilePath);
    // If differecnes exost, write them to a file.
    if (fileDifferences.isNotEmpty) {
      final diffFile = File(differenceFilePath);
      diffFile.writeAsStringSync(fileDifferences);
    }
    // return the result.
    return fileDifferences;
  }

  String compareFilesLineByLine(
    String resultPath,
    String verifiedResultPath,
  ) {
    final StringBuffer resultBuffer = StringBuffer();
    String filePath = '';
    try {
      // Open the files
      final File file1 = File(resultPath);
      final List<String> lines1 = file1.readAsLinesSync();
      final File file2 = File(verifiedResultPath);
      final List<String> lines2 = file2.readAsLinesSync();
      int i = 0, j = 0;

      while (i < lines1.length || j < lines2.length) {
        final line1 = i < lines1.length ? lines1[i] : null;
        final line2 = j < lines2.length ? lines2[j] : null;

        if (line1 == line2) {
          // Lines match — move forward
          i++;
          j++;
        } else if (line1 != null && line2 == null) {
          resultBuffer.writeln('ADDED: $line1');
          i++;
        } else if (line1 != null && lines2.sublist(j).contains(line1)) {
          // line 1 is exists later in file2, so, line2 was deleted
          resultBuffer.writeln('DELETED: $line2');
          j++;
        } else if (line2 != null && line1 == null) {
          // line 2 in file 2 does not exist in file1, so line 2 was deleted.
          resultBuffer.writeln('DELETED: $line2');
          j++;
        } else if (line2 != null && lines1.sublist(i).contains(line2)) {
          // line 2 is exists later in file1, so, line1 was added
          resultBuffer.writeln('ADDED: $line1');
          i++;
        } else {
          // Both lines are different, show both and move on
          resultBuffer.writeln(
              'MODIFIED\nResult  (${i + 1}): "$line1"\nVerified(${j + 1}): "$line2"');
          i++;
          j++;
        }
      }
    } catch (e) {
      return ('Error reading file: $filePath');
    }
    return resultBuffer.toString();
  }
}

class EmptyAnalysis extends AnalysisTest {
  EmptyAnalysis()
      : super(
          testName: 'EmptyAnalysis',
          analysisConfig: AnalysisConfig(
            planInfo: const PlanInfo(),
            taxFilingInfo: const TaxFilingInfo(),
            self: const PersonInfo(),
            spouse: null,
            accountInfos: [],
            incomeInfos: [],
            scenarioInfos: [],
          ),
        );
}

class InvalidAnalysis extends AnalysisTest {
  InvalidAnalysis()
      : super(
          testName: 'InvalidAnalysis',
          analysisConfig: AnalysisConfig(
            planInfo: PlanInfo(
              planStartDate: DateTime(2025, 01, 01),
              planEndDate: DateTime(2024, 12, 31),
              yearlyExpenses: -50000.00,
            ),
            taxFilingInfo: const TaxFilingInfo(
              filingStatus: FilingStatus.single,
              filingState: FilingState.other,
              stateTaxPercentage: -1.0,
              localTaxPercentage: -1.0,
            ),
            self: PersonInfo(birthDate: DateTime(1952, 12, 12)),
            spouse: const PersonInfo(),
            accountInfos: [
              AccountInfo(type: AccountType.taxableSavings, balance: -1.0),
              AccountInfo(
                  type: AccountType.taxableBrokerage,
                  name: 'Fred',
                  roiIncome: -1.0,
                  costBasis: -1.0),
              AccountInfo(
                  type: AccountType.rothIRA, name: 'Barney', roiGain: -1.0),
              AccountInfo(
                  type: AccountType.traditionalIRA, name: 'nameIsTooLongNow')
            ],
            incomeInfos: [
              IncomeInfo(type: IncomeType.socialSecurity),
              IncomeInfo(
                  type: IncomeType.socialSecurity,
                  startDate: DateTime(2020),
                  yearlyIncome: -1.0),
              IncomeInfo(type: IncomeType.employment),
              IncomeInfo(
                  type: IncomeType.employment,
                  startDate: DateTime(2020),
                  endDate: DateTime(2030)),
              IncomeInfo(
                  type: IncomeType.selfEmployment, owner: OwnerType.spouse),
            ],
            scenarioInfos: [
              ScenarioInfo(
                amountConstraint: const AmountConstraint(fixedAmount: -1.0),
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2020),
                endDateConstraint: ConversionEndDateConstraint.onFixedDate,
                specificEndDate: DateTime(2030),
              ),
              ScenarioInfo(
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2025),
                endDateConstraint: ConversionEndDateConstraint.onFixedDate,
                specificEndDate: DateTime(2024),
              ),
            ],
          ),
        );
}

class SimpleAnalysis extends AnalysisTest {
  SimpleAnalysis()
      : super(
          testName: 'SimpleAnalysis',
          analysisConfig: AnalysisConfig(
            planInfo: PlanInfo(
              planStartDate: DateTime(2025, 01, 01),
              planEndDate: DateTime(2035, 12, 31),
              yearlyExpenses: 50000.00,
              cola: 0.0,
            ),
            taxFilingInfo: const TaxFilingInfo(
              filingStatus: FilingStatus.single,
              filingState: FilingState.other,
              stateTaxPercentage: 0.04,
              localTaxPercentage: 0.01,
            ),
            self: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            spouse: const PersonInfo(),
            accountInfos: [
              AccountInfo(
                name: 'Savings',
                type: AccountType.taxableSavings,
                balance: 10000.00,
                roiIncome: 0.00,
              ),
              AccountInfo(
                name: 'Brokerage',
                type: AccountType.taxableBrokerage,
                balance: 100000.00,
                costBasis: 25000.00,
                roiGain: 0.00,
                roiIncome: 0.00,
              ),
              AccountInfo(
                name: 'IRA',
                type: AccountType.traditionalIRA,
                balance: 1000000.00,
                roiIncome: 0.00,
              ),
              AccountInfo(
                name: 'Roth',
                type: AccountType.rothIRA,
                balance: 20000.00,
                roiIncome: 0.00,
              )
            ],
            incomeInfos: [],
            scenarioInfos: [
              ScenarioInfo(
                amountConstraint: const AmountConstraint(
                    type: AmountConstraintType.amount, fixedAmount: 0.00),
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2025, 1),
                endDateConstraint: ConversionEndDateConstraint.onFixedDate,
                specificEndDate: DateTime(2025, 1),
              ),
            ],
          ),
        );
}

class SimpleWithSS extends AnalysisTest {
  SimpleWithSS()
      : super(
          testName: 'SimpleWithSS',
          analysisConfig: AnalysisConfig(
            planInfo: PlanInfo(
              planStartDate: DateTime(2025, 01, 01),
              planEndDate: DateTime(2035, 12, 31),
              yearlyExpenses: 50000.00,
            ),
            taxFilingInfo: const TaxFilingInfo(
              filingStatus: FilingStatus.single,
              filingState: FilingState.other,
              stateTaxPercentage: 0.04,
              localTaxPercentage: 0.01,
            ),
            self: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            spouse: const PersonInfo(),
            accountInfos: [
              AccountInfo(
                name: 'Savings',
                type: AccountType.taxableSavings,
                balance: 10000.00,
                roiIncome: 0.00,
              ),
              AccountInfo(
                name: 'Brokerage',
                type: AccountType.taxableBrokerage,
                balance: 100000.00,
                costBasis: 25000.00,
                roiGain: 0.00,
                roiIncome: 0.00,
              ),
              AccountInfo(
                name: 'IRA',
                type: AccountType.traditionalIRA,
                balance: 1000000.00,
                roiIncome: 0.00,
              ),
              AccountInfo(
                name: 'Roth',
                type: AccountType.rothIRA,
                balance: 20000.00,
                roiIncome: 0.00,
              )
            ],
            incomeInfos: [
              IncomeInfo(
                  type: IncomeType.socialSecurity,
                  startDate: DateTime(2025, 3),
                  yearlyIncome: 36000.00),
            ],
            scenarioInfos: [
              ScenarioInfo(
                amountConstraint: const AmountConstraint(
                    type: AmountConstraintType.amount, fixedAmount: 0.00),
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2025, 1),
                endDateConstraint: ConversionEndDateConstraint.onFixedDate,
                specificEndDate: DateTime(2025, 1),
              ),
            ],
          ),
        );
}

class SimpleWithEmployment extends AnalysisTest {
  SimpleWithEmployment()
      : super(
          testName: 'SimpleWithEmployment',
          analysisConfig: AnalysisConfig(
            planInfo: PlanInfo(
              planStartDate: DateTime(2025, 01, 01),
              planEndDate: DateTime(2035, 12, 31),
              yearlyExpenses: 50000.00,
            ),
            taxFilingInfo: const TaxFilingInfo(
              filingStatus: FilingStatus.single,
              filingState: FilingState.other,
              stateTaxPercentage: 0.04,
              localTaxPercentage: 0.01,
            ),
            self: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            spouse: const PersonInfo(),
            accountInfos: [
              AccountInfo(
                name: 'Savings',
                type: AccountType.taxableSavings,
                balance: 10000.00,
                roiIncome: 0.00,
              ),
              AccountInfo(
                name: 'Brokerage',
                type: AccountType.taxableBrokerage,
                balance: 100000.00,
                costBasis: 25000.00,
                roiGain: 0.00,
                roiIncome: 0.00,
              ),
              AccountInfo(
                name: 'IRA',
                type: AccountType.traditionalIRA,
                balance: 1000000.00,
                roiIncome: 0.00,
              ),
              AccountInfo(
                name: 'Roth',
                type: AccountType.rothIRA,
                balance: 20000.00,
                roiIncome: 0.00,
              )
            ],
            incomeInfos: [
              IncomeInfo(
                  type: IncomeType.employment,
                  startDate: DateTime(2025, 3),
                  endDate: DateTime(2026, 02),
                  yearlyIncome: 60000.00),
            ],
            scenarioInfos: [
              ScenarioInfo(
                amountConstraint: const AmountConstraint(
                    type: AmountConstraintType.amount, fixedAmount: 0.00),
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2025, 1),
                endDateConstraint: ConversionEndDateConstraint.onFixedDate,
                specificEndDate: DateTime(2025, 1),
              ),
            ],
          ),
        );
}

class JustInvestmentGains extends AnalysisTest {
  JustInvestmentGains()
      : super(
          testName: 'JustInvestmentGains',
          analysisConfig: AnalysisConfig(
            planInfo: PlanInfo(
              planStartDate: DateTime(2025, 01, 01),
              planEndDate: DateTime(2035, 12, 31),
              yearlyExpenses: 0.00,
              cola: 0.0,
            ),
            taxFilingInfo: const TaxFilingInfo(
              filingStatus: FilingStatus.single,
              filingState: FilingState.other,
              stateTaxPercentage: 0.04,
              localTaxPercentage: 0.01,
            ),
            self: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            spouse: const PersonInfo(),
            accountInfos: [
              AccountInfo(
                name: 'Savings',
                type: AccountType.taxableSavings,
                balance: 10000.00,
                roiGain: 0.01,
              ),
              AccountInfo(
                name: 'Brokerage',
                type: AccountType.taxableBrokerage,
                balance: 100000.00,
                costBasis: 25000.00,
                roiGain: 0.05,
                roiIncome: 0.05,
              ),
              AccountInfo(
                name: 'IRA',
                type: AccountType.traditionalIRA,
                balance: 1000000.00,
                roiGain: 0.10,
              ),
              AccountInfo(
                name: 'Roth',
                type: AccountType.rothIRA,
                balance: 20000.00,
                roiGain: 0.2,
              )
            ],
            incomeInfos: [],
            scenarioInfos: [
              ScenarioInfo(
                amountConstraint: const AmountConstraint(
                    type: AmountConstraintType.amount, fixedAmount: 0.00),
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2025, 1),
                endDateConstraint: ConversionEndDateConstraint.onFixedDate,
                specificEndDate: DateTime(2025, 1),
              ),
            ],
          ),
        );
}

class JustIncome extends AnalysisTest {
  JustIncome()
      : super(
          testName: 'JustIncome',
          analysisConfig: AnalysisConfig(
            planInfo: PlanInfo(
              planStartDate: DateTime(2025, 01, 01),
              planEndDate: DateTime(2035, 12, 31),
              yearlyExpenses: 0.00,
              cola: 0.0,
            ),
            taxFilingInfo: const TaxFilingInfo(
              filingStatus: FilingStatus.single,
              filingState: FilingState.other,
              stateTaxPercentage: 0.04,
              localTaxPercentage: 0.01,
            ),
            self: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            spouse: const PersonInfo(),
            accountInfos: [
              AccountInfo(
                name: 'Savings',
                type: AccountType.taxableSavings,
                balance: 10000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Brokerage',
                type: AccountType.taxableBrokerage,
                balance: 100000.00,
                costBasis: 25000.00,
                roiGain: 0.0,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'IRA',
                type: AccountType.traditionalIRA,
                balance: 1000000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Roth',
                type: AccountType.rothIRA,
                balance: 20000.00,
                roiIncome: 0.0,
              )
            ],
            incomeInfos: [
              IncomeInfo(
                  type: IncomeType.employment,
                  startDate: DateTime(2025, 1),
                  endDate: DateTime(2025, 12),
                  yearlyIncome: 30000.00),
              IncomeInfo(
                  type: IncomeType.selfEmployment,
                  startDate: DateTime(2026, 1),
                  endDate: DateTime(2026, 12),
                  yearlyIncome: 60000.00),
              IncomeInfo(
                  type: IncomeType.pension,
                  startDate: DateTime(2027, 1),
                  endDate: DateTime(2027, 12),
                  yearlyIncome: 90000.00),
              IncomeInfo(
                  type: IncomeType.socialSecurity,
                  startDate: DateTime(2028, 1),
                  endDate: DateTime(2028, 12),
                  yearlyIncome: 30000.00),
            ],
            scenarioInfos: [
              ScenarioInfo(
                amountConstraint: const AmountConstraint(
                    type: AmountConstraintType.amount, fixedAmount: 0.00),
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2025, 1),
                endDateConstraint: ConversionEndDateConstraint.onFixedDate,
                specificEndDate: DateTime(2025, 1),
              ),
            ],
          ),
        );
}

class JustCola extends AnalysisTest {
  JustCola()
      : super(
          testName: 'JustCola',
          analysisConfig: AnalysisConfig(
            planInfo: PlanInfo(
              planStartDate: DateTime(2025, 01, 01),
              planEndDate: DateTime(2035, 12, 31),
              yearlyExpenses: 12000.00,
              cola: 0.1,
            ),
            taxFilingInfo: const TaxFilingInfo(
              filingStatus: FilingStatus.single,
              filingState: FilingState.other,
              stateTaxPercentage: 0.0,
              localTaxPercentage: 0.0,
            ),
            self: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            spouse: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            accountInfos: [
              AccountInfo(
                name: 'Savings',
                type: AccountType.taxableSavings,
                balance: 10000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Brokerage',
                type: AccountType.taxableBrokerage,
                balance: 100000.00,
                costBasis: 25000.00,
                roiGain: 0.0,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'IRA',
                type: AccountType.traditionalIRA,
                balance: 1000000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Roth',
                type: AccountType.rothIRA,
                balance: 20000.00,
                roiIncome: 0.0,
              )
            ],
            incomeInfos: [
              IncomeInfo(
                  type: IncomeType.employment,
                  startDate: DateTime(2025, 1),
                  endDate: DateTime(2027, 12),
                  yearlyIncome: 12000.00),
              IncomeInfo(
                  type: IncomeType.pension,
                  startDate: DateTime(2025, 1),
                  endDate: DateTime(2027, 12),
                  yearlyIncome: 24000.00),
              IncomeInfo(
                  type: IncomeType.socialSecurity,
                  startDate: DateTime(2026, 1),
                  endDate: DateTime(2027, 12),
                  yearlyIncome: 36000.00),
            ],
            scenarioInfos: [
              ScenarioInfo(
                amountConstraint: const AmountConstraint(
                    type: AmountConstraintType.amount, fixedAmount: 0.00),
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2025, 1),
                endDateConstraint: ConversionEndDateConstraint.onFixedDate,
                specificEndDate: DateTime(2025, 1),
              ),
            ],
          ),
        );
}

class JustFixedConversionSufficientTaxableAssets extends AnalysisTest {
  JustFixedConversionSufficientTaxableAssets()
      : super(
          testName: 'JustFixedConversionSufficientTaxableAssets',
          analysisConfig: AnalysisConfig(
            planInfo: PlanInfo(
              planStartDate: DateTime(2025, 01, 01),
              planEndDate: DateTime(2035, 12, 31),
              yearlyExpenses: 0.00,
              cola: 0.0,
            ),
            taxFilingInfo: const TaxFilingInfo(
              filingStatus: FilingStatus.single,
              filingState: FilingState.other,
              stateTaxPercentage: 0.0,
              localTaxPercentage: 0.0,
            ),
            self: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            spouse: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            accountInfos: [
              AccountInfo(
                name: 'Savings',
                type: AccountType.taxableSavings,
                balance: 250000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Brokerage',
                type: AccountType.taxableBrokerage,
                balance: 100000.00,
                costBasis: 25000.00,
                roiGain: 0.0,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'IRA',
                type: AccountType.traditionalIRA,
                balance: 1100000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Roth',
                type: AccountType.rothIRA,
                balance: 20000.00,
                roiIncome: 0.0,
              )
            ],
            incomeInfos: [],
            scenarioInfos: [
              ScenarioInfo(
                amountConstraint: const AmountConstraint(
                    type: AmountConstraintType.amount, fixedAmount: 120000.00),
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2025, 1),
                endDateConstraint: ConversionEndDateConstraint.onEndOfPlan,
                //specificEndDate: DateTime(2025, 1),
              ),
            ],
          ),
        );
}

class JustFixedConversionInsufficientTaxableAssets extends AnalysisTest {
  JustFixedConversionInsufficientTaxableAssets()
      : super(
          testName: 'JustFixedConversionInsufficientTaxableAssets',
          analysisConfig: AnalysisConfig(
            planInfo: PlanInfo(
              planStartDate: DateTime(2025, 01, 01),
              planEndDate: DateTime(2035, 12, 31),
              yearlyExpenses: 0.00,
              cola: 0.0,
            ),
            taxFilingInfo: const TaxFilingInfo(
              filingStatus: FilingStatus.single,
              filingState: FilingState.other,
              stateTaxPercentage: 0.0,
              localTaxPercentage: 0.0,
            ),
            self: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            spouse: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            accountInfos: [
              AccountInfo(
                name: 'Savings',
                type: AccountType.taxableSavings,
                balance: 50000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'IRA',
                type: AccountType.traditionalIRA,
                balance: 1100000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Roth',
                type: AccountType.rothIRA,
                balance: 20000.00,
                roiIncome: 0.0,
              )
            ],
            incomeInfos: [],
            scenarioInfos: [
              ScenarioInfo(
                amountConstraint: const AmountConstraint(
                    type: AmountConstraintType.amount, fixedAmount: 120000.00),
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2025, 1),
                endDateConstraint: ConversionEndDateConstraint.onEndOfPlan,
                //specificEndDate: DateTime(2025, 1),
              ),
            ],
          ),
        );
}

class JustFixedConversionAllowIraForTaxes extends AnalysisTest {
  JustFixedConversionAllowIraForTaxes()
      : super(
          testName: 'JustFixedConversionAllowIraForTaxes',
          analysisConfig: AnalysisConfig(
            planInfo: PlanInfo(
              planStartDate: DateTime(2025, 01, 01),
              planEndDate: DateTime(2035, 12, 31),
              yearlyExpenses: 0.00,
              cola: 0.0,
            ),
            taxFilingInfo: const TaxFilingInfo(
              filingStatus: FilingStatus.single,
              filingState: FilingState.other,
              stateTaxPercentage: 0.0,
              localTaxPercentage: 0.0,
            ),
            self: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            spouse: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            accountInfos: [
              AccountInfo(
                name: 'Savings',
                type: AccountType.taxableSavings,
                balance: 50000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'IRA',
                type: AccountType.traditionalIRA,
                balance: 1100000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Roth',
                type: AccountType.rothIRA,
                balance: 20000.00,
                roiIncome: 0.0,
              )
            ],
            incomeInfos: [],
            scenarioInfos: [
              ScenarioInfo(
                amountConstraint: const AmountConstraint(
                    type: AmountConstraintType.amount, fixedAmount: 120000.00),
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2025, 1),
                endDateConstraint: ConversionEndDateConstraint.onEndOfPlan,
                stopWhenTaxableIncomeUnavailible: false,
                //specificEndDate: DateTime(2025, 1),
              ),
            ],
          ),
        );
}

class JustMagiLimitSufficientTaxableAssets extends AnalysisTest {
  JustMagiLimitSufficientTaxableAssets()
      : super(
          testName: 'JustMagiLimitSufficientTaxableAssets',
          analysisConfig: AnalysisConfig(
            planInfo: PlanInfo(
              planStartDate: DateTime(2025, 01, 01),
              planEndDate: DateTime(2035, 12, 31),
              yearlyExpenses: 0.00,
              cola: 0.0,
            ),
            taxFilingInfo: const TaxFilingInfo(
              filingStatus: FilingStatus.single,
              filingState: FilingState.other,
              stateTaxPercentage: 0.0,
              localTaxPercentage: 0.0,
            ),
            self: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            spouse: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            accountInfos: [
              AccountInfo(
                name: 'Savings',
                type: AccountType.taxableSavings,
                balance: 250000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Brokerage',
                type: AccountType.taxableBrokerage,
                balance: 100000.00,
                costBasis: 25000.00,
                roiGain: 0.0,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'IRA',
                type: AccountType.traditionalIRA,
                balance: 1100000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Roth',
                type: AccountType.rothIRA,
                balance: 20000.00,
                roiIncome: 0.0,
              )
            ],
            incomeInfos: [],
            scenarioInfos: [
              ScenarioInfo(
                amountConstraint: const AmountConstraint(
                    type: AmountConstraintType.magiLimit,
                    fixedAmount: 100000.00),
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2025, 1),
                endDateConstraint: ConversionEndDateConstraint.onEndOfPlan,
                //specificEndDate: DateTime(2025, 1),
              ),
            ],
          ),
        );
}

class JustMagiLimitInsufficientTaxableAssets extends AnalysisTest {
  JustMagiLimitInsufficientTaxableAssets()
      : super(
          testName: 'JustMagiLimitInsufficientTaxableAssets',
          analysisConfig: AnalysisConfig(
            planInfo: PlanInfo(
              planStartDate: DateTime(2025, 01, 01),
              planEndDate: DateTime(2035, 12, 31),
              yearlyExpenses: 0.00,
              cola: 0.0,
            ),
            taxFilingInfo: const TaxFilingInfo(
              filingStatus: FilingStatus.single,
              filingState: FilingState.other,
              stateTaxPercentage: 0.0,
              localTaxPercentage: 0.0,
            ),
            self: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            spouse: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            accountInfos: [
              AccountInfo(
                name: 'Savings',
                type: AccountType.taxableSavings,
                balance: 50000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'IRA',
                type: AccountType.traditionalIRA,
                balance: 1100000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Roth',
                type: AccountType.rothIRA,
                balance: 20000.00,
                roiIncome: 0.0,
              )
            ],
            incomeInfos: [],
            scenarioInfos: [
              ScenarioInfo(
                amountConstraint: const AmountConstraint(
                    type: AmountConstraintType.magiLimit,
                    fixedAmount: 150000.00),
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2025, 1),
                endDateConstraint: ConversionEndDateConstraint.onEndOfPlan,
                //specificEndDate: DateTime(2025, 1),
              ),
            ],
          ),
        );
}

class JustMagiLimitAllowIraForTaxes extends AnalysisTest {
  JustMagiLimitAllowIraForTaxes()
      : super(
          testName: 'JustMagiLimitAllowIraForTaxes',
          analysisConfig: AnalysisConfig(
            planInfo: PlanInfo(
              planStartDate: DateTime(2025, 01, 01),
              planEndDate: DateTime(2035, 12, 31),
              yearlyExpenses: 0.00,
              cola: 0.0,
            ),
            taxFilingInfo: const TaxFilingInfo(
              filingStatus: FilingStatus.single,
              filingState: FilingState.other,
              stateTaxPercentage: 0.0,
              localTaxPercentage: 0.0,
            ),
            self: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            spouse: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            accountInfos: [
              AccountInfo(
                name: 'Savings',
                type: AccountType.taxableSavings,
                balance: 50000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'IRA',
                type: AccountType.traditionalIRA,
                balance: 1100000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Roth',
                type: AccountType.rothIRA,
                balance: 20000.00,
                roiIncome: 0.0,
              )
            ],
            incomeInfos: [],
            scenarioInfos: [
              ScenarioInfo(
                amountConstraint: const AmountConstraint(
                    type: AmountConstraintType.magiLimit,
                    fixedAmount: 150000.00),
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2025, 1),
                endDateConstraint: ConversionEndDateConstraint.onEndOfPlan,
                stopWhenTaxableIncomeUnavailible: false,
                //specificEndDate: DateTime(2025, 1),
              ),
            ],
          ),
        );
}

class JustMarried extends AnalysisTest {
  JustMarried()
      : super(
          testName: 'JustMarried',
          analysisConfig: AnalysisConfig(
            planInfo: PlanInfo(
              planStartDate: DateTime(2025, 01, 01),
              planEndDate: DateTime(2035, 12, 31),
              yearlyExpenses: 120000.00,
              cola: 0.0,
            ),
            taxFilingInfo: const TaxFilingInfo(
              filingStatus: FilingStatus.marriedFilingJointly,
              filingState: FilingState.other,
              stateTaxPercentage: 0.0,
              localTaxPercentage: 0.0,
            ),
            self: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            spouse: PersonInfo(birthDate: DateTime(1961, 01, 01)),
            accountInfos: [
              AccountInfo(
                name: 'Savings',
                type: AccountType.taxableSavings,
                balance: 120000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Savings2',
                type: AccountType.taxableSavings,
                owner: OwnerType.spouse,
                balance: 120000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Brokerage',
                type: AccountType.taxableBrokerage,
                balance: 120000.00,
                costBasis: 60000.00,
                roiGain: 0.0,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Brokerage2',
                type: AccountType.taxableBrokerage,
                owner: OwnerType.spouse,
                balance: 120000.00,
                costBasis: 60000.00,
                roiGain: 0.0,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'IRA',
                type: AccountType.traditionalIRA,
                balance: 240000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'IRA2',
                owner: OwnerType.spouse,
                type: AccountType.traditionalIRA,
                balance: 240000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Roth',
                type: AccountType.rothIRA,
                balance: 240000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Roth2',
                type: AccountType.rothIRA,
                owner: OwnerType.spouse,
                balance: 240000.00,
                roiIncome: 0.0,
              ),
            ],
            incomeInfos: [
              IncomeInfo(
                  type: IncomeType.employment,
                  startDate: DateTime(2025, 1),
                  endDate: DateTime(2025, 12),
                  yearlyIncome: 60000.00),
              IncomeInfo(
                  type: IncomeType.employment,
                  owner: OwnerType.spouse,
                  startDate: DateTime(2027, 1),
                  endDate: DateTime(2027, 12),
                  yearlyIncome: 60000.00),
            ],
            scenarioInfos: [
              ScenarioInfo(
                amountConstraint: const AmountConstraint(
                    type: AmountConstraintType.amount, fixedAmount: 0.00),
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2025, 1),
                endDateConstraint: ConversionEndDateConstraint.onFixedDate,
                specificEndDate: DateTime(2025, 1),
              ),
            ],
          ),
        );
}

class MarriedFixedConversionSufficientTaxableAsssets extends AnalysisTest {
  MarriedFixedConversionSufficientTaxableAsssets()
      : super(
          testName: 'MarriedFixedConversionSufficientTaxableAsssets',
          analysisConfig: AnalysisConfig(
            planInfo: PlanInfo(
              planStartDate: DateTime(2025, 01, 01),
              planEndDate: DateTime(2035, 12, 31),
              yearlyExpenses: 0.00,
              cola: 0.0,
            ),
            taxFilingInfo: const TaxFilingInfo(
              filingStatus: FilingStatus.marriedFilingJointly,
              filingState: FilingState.other,
              stateTaxPercentage: 0.0,
              localTaxPercentage: 0.0,
            ),
            self: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            spouse: PersonInfo(birthDate: DateTime(1961, 01, 01)),
            accountInfos: [
              AccountInfo(
                name: 'Savings',
                type: AccountType.taxableSavings,
                balance: 120000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Savings2',
                type: AccountType.taxableSavings,
                owner: OwnerType.spouse,
                balance: 120000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Brokerage',
                type: AccountType.taxableBrokerage,
                balance: 120000.00,
                costBasis: 60000.00,
                roiGain: 0.0,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Brokerage2',
                type: AccountType.taxableBrokerage,
                owner: OwnerType.spouse,
                balance: 120000.00,
                costBasis: 60000.00,
                roiGain: 0.0,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'IRA',
                type: AccountType.traditionalIRA,
                balance: 120000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'IRA2',
                owner: OwnerType.spouse,
                type: AccountType.traditionalIRA,
                balance: 120000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Roth',
                type: AccountType.rothIRA,
                balance: 10000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Roth2',
                type: AccountType.rothIRA,
                owner: OwnerType.spouse,
                balance: 10000.00,
                roiIncome: 0.0,
              ),
            ],
            incomeInfos: [],
            scenarioInfos: [
              ScenarioInfo(
                amountConstraint: const AmountConstraint(
                    type: AmountConstraintType.amount, fixedAmount: 24000.00),
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2025, 1),
                endDateConstraint: ConversionEndDateConstraint.onEndOfPlan,
                specificEndDate: DateTime(2025, 1),
              ),
            ],
          ),
        );
}

class SingleMultipleAccountsFixedConversionSufficientTaxableAsssets extends AnalysisTest {
  SingleMultipleAccountsFixedConversionSufficientTaxableAsssets()
      : super(
          testName: 'SingleMultipleAccountsFixedConversionSufficientTaxableAsssets',
          analysisConfig: AnalysisConfig(
            planInfo: PlanInfo(
              planStartDate: DateTime(2025, 01, 01),
              planEndDate: DateTime(2035, 12, 31),
              yearlyExpenses: 0.00,
              cola: 0.0,
            ),
            taxFilingInfo: const TaxFilingInfo(
              filingStatus: FilingStatus.single,
              filingState: FilingState.other,
              stateTaxPercentage: 0.0,
              localTaxPercentage: 0.0,
            ),
            self: PersonInfo(birthDate: DateTime(1960, 01, 01)),
            spouse: PersonInfo(birthDate: DateTime(1961, 01, 01)),
            accountInfos: [
              AccountInfo(
                name: 'Savings',
                type: AccountType.taxableSavings,
                balance: 120000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Savings2',
                type: AccountType.taxableSavings,
                owner: OwnerType.self,
                balance: 120000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Brokerage',
                type: AccountType.taxableBrokerage,
                balance: 120000.00,
                costBasis: 60000.00,
                roiGain: 0.0,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Brokerage2',
                type: AccountType.taxableBrokerage,
                owner: OwnerType.self,
                balance: 120000.00,
                costBasis: 60000.00,
                roiGain: 0.0,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'IRA',
                type: AccountType.traditionalIRA,
                balance: 120000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'IRA2',
                owner: OwnerType.self,
                type: AccountType.traditionalIRA,
                balance: 120000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Roth',
                type: AccountType.rothIRA,
                balance: 10000.00,
                roiIncome: 0.0,
              ),
              AccountInfo(
                name: 'Roth2',
                type: AccountType.rothIRA,
                owner: OwnerType.self,
                balance: 10000.00,
                roiIncome: 0.0,
              ),
            ],
            incomeInfos: [],
            scenarioInfos: [
              ScenarioInfo(
                amountConstraint: const AmountConstraint(
                    type: AmountConstraintType.amount, fixedAmount: 24000.00),
                startDateConstraint: ConversionStartDateConstraint.onFixedDate,
                specificStartDate: DateTime(2025, 1),
                endDateConstraint: ConversionEndDateConstraint.onEndOfPlan,
                specificEndDate: DateTime(2025, 1),
              ),
            ],
          ),
        );
}
