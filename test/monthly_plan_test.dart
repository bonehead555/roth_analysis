import 'package:roth_analysis/services/analysis_services/monthly_plan.dart';
import 'package:test/test.dart';

main() {
  group('Full Year Monthly Plan Test Cases; with even results', () {
    MonthlyPlan monthlyPlan = MonthlyPlan();
    monthlyPlan.initialize(120.00);
    test('Month 1 Result = ${monthlyPlan.getMonthlyAmount(1)}', () {
      expect(monthlyPlan.getMonthlyAmount(1), 10.00);
    });
    test('Month 6 Result = ${monthlyPlan.getMonthlyAmount(6)}', () {
      expect(monthlyPlan.getMonthlyAmount(6), 10.00);
    });
    test('Month 12 Result = ${monthlyPlan.getMonthlyAmount(12)}', () {
      expect(monthlyPlan.getMonthlyAmount(12), 10.00);
    });
    test('Remaining Amount for Month 1 = ${monthlyPlan.remainingBalance(1)}',
        () {
      expect(monthlyPlan.remainingBalance(1), 120.00);
    });
    test('Remaining Amount for Month 7 = ${monthlyPlan.remainingBalance(7)}',
        () {
      expect(monthlyPlan.remainingBalance(7), 60.00);
    });
  });

  group('Full Year Monthly Plan Test Cases; with uneven results', () {
    MonthlyPlan monthlyPlan = MonthlyPlan();
    monthlyPlan.initialize(130.00);
    test('Month 1 Result = ${monthlyPlan.getMonthlyAmount(1)}', () {
      expect(monthlyPlan.getMonthlyAmount(1), 10.83);
    });
    test('Month 6 Result = ${monthlyPlan.getMonthlyAmount(6)}', () {
      expect(monthlyPlan.getMonthlyAmount(6), 10.83);
    });
    test('Month 12 Result = ${monthlyPlan.getMonthlyAmount(12)}', () {
      expect(monthlyPlan.getMonthlyAmount(12), 10.87);
    });
  });

  group(
      'Full Year Monthly Plan Test Cases; with yearly update in month 7 update.',
      () {
    MonthlyPlan monthlyPlan = MonthlyPlan();
    monthlyPlan.initialize(120.00);
    monthlyPlan.updateYearlyAmount(180.00, month: 7);
    test('Month 1 Result = ${monthlyPlan.getMonthlyAmount(1)}', () {
      expect(monthlyPlan.getMonthlyAmount(1), 10.00);
    });
    test('Month 6 Result = ${monthlyPlan.getMonthlyAmount(6)}', () {
      expect(monthlyPlan.getMonthlyAmount(6), 10.00);
    });
    test('Month 7 Result = ${monthlyPlan.getMonthlyAmount(7)}', () {
      expect(monthlyPlan.getMonthlyAmount(7), 20.00);
    });
    test('Month 12 Result = ${monthlyPlan.getMonthlyAmount(12)}', () {
      expect(monthlyPlan.getMonthlyAmount(12), 20.00);
    });
  });

  group('Full Year Monthly Plan Test Cases; with monthly update in month 7.',
      () {
    MonthlyPlan monthlyPlan = MonthlyPlan();
    monthlyPlan.initialize(120.00);
    monthlyPlan.updateMonthlyAmount(7, 20.0);
    test('Month 1 Result = ${monthlyPlan.getMonthlyAmount(1)}', () {
      expect(monthlyPlan.getMonthlyAmount(1), 10.00);
    });
    test('Month 6 Result = ${monthlyPlan.getMonthlyAmount(6)}', () {
      expect(monthlyPlan.getMonthlyAmount(6), 10.00);
    });
    test('Month 7 Result = ${monthlyPlan.getMonthlyAmount(7)}', () {
      expect(monthlyPlan.getMonthlyAmount(7), 20.00);
    });
    test('Month 8 Result = ${monthlyPlan.getMonthlyAmount(8)}', () {
      expect(monthlyPlan.getMonthlyAmount(8), 8.00);
    });
    test('Month 12 Result = ${monthlyPlan.getMonthlyAmount(12)}', () {
      expect(monthlyPlan.getMonthlyAmount(12), 8.00);
    });
    test('New YearlyAmount Result = ${monthlyPlan.yearlyAmount}', () {
      expect(monthlyPlan.yearlyAmount, 120.00);
    });
  });

  group('Six Monthly Plan Test Cases; with even results', () {
    MonthlyPlan monthlyPlan = MonthlyPlan();
    monthlyPlan.initialize(240.00, beginMonth: 4, finalMonth: 9);
    test('Month 1 Result = ${monthlyPlan.getMonthlyAmount(1)}', () {
      expect(monthlyPlan.getMonthlyAmount(1), 0.00);
    });
    test('Month 3 Result = ${monthlyPlan.getMonthlyAmount(1)}', () {
      expect(monthlyPlan.getMonthlyAmount(3), 0.00);
    });
    test('Month 4 Result = ${monthlyPlan.getMonthlyAmount(4)}', () {
      expect(monthlyPlan.getMonthlyAmount(6), 20.00);
    });
    test('Month 9 Result = ${monthlyPlan.getMonthlyAmount(9)}', () {
      expect(monthlyPlan.getMonthlyAmount(9), 20.00);
    });
    test('Month 10 Result = ${monthlyPlan.getMonthlyAmount(10)}', () {
      expect(monthlyPlan.getMonthlyAmount(10), 0.00);
    });
    test('Month 12 Result = ${monthlyPlan.getMonthlyAmount(12)}', () {
      expect(monthlyPlan.getMonthlyAmount(12), 0.00);
    });
  });

  group('Six Monthly Plan Test Cases; with update to yearly amount', () {
    MonthlyPlan monthlyPlan = MonthlyPlan();
    monthlyPlan.initialize(240.00, beginMonth: 4, finalMonth: 9);
    monthlyPlan.updateYearlyAmount(180.00, month: 7);
    test('Month 1 Result = ${monthlyPlan.getMonthlyAmount(1)}', () {
      expect(monthlyPlan.getMonthlyAmount(1), 0.00);
    });
    test('Month 3 Result = ${monthlyPlan.getMonthlyAmount(1)}', () {
      expect(monthlyPlan.getMonthlyAmount(3), 0.00);
    });
    test('Month 4 Result = ${monthlyPlan.getMonthlyAmount(4)}', () {
      expect(monthlyPlan.getMonthlyAmount(6), 20.00);
    });
    test('Month 7 Result = ${monthlyPlan.getMonthlyAmount(4)}', () {
      expect(monthlyPlan.getMonthlyAmount(7), 40.00);
    });
    test('Month 9 Result = ${monthlyPlan.getMonthlyAmount(9)}', () {
      expect(monthlyPlan.getMonthlyAmount(9), 40.00);
    });
    test('Month 10 Result = ${monthlyPlan.getMonthlyAmount(10)}', () {
      expect(monthlyPlan.getMonthlyAmount(10), 0.00);
    });
    test('Month 12 Result = ${monthlyPlan.getMonthlyAmount(12)}', () {
      expect(monthlyPlan.getMonthlyAmount(12), 0.00);
    });
  });

  group('Six Monthly Plan Test Cases; with update to yearly amount', () {
    MonthlyPlan monthlyPlan = MonthlyPlan();
    monthlyPlan.initialize(120.00);
    monthlyPlan.updateYearlyAmount(0.00, month: 7);
    test('Month 1 Result = ${monthlyPlan.getMonthlyAmount(1)}', () {
      expect(monthlyPlan.getMonthlyAmount(1), 10.00);
    });
    test('Month 3 Result = ${monthlyPlan.getMonthlyAmount(3)}', () {
      expect(monthlyPlan.getMonthlyAmount(3), 10.00);
    });
    test('Month 4 Result = ${monthlyPlan.getMonthlyAmount(6)}', () {
      expect(monthlyPlan.getMonthlyAmount(6), 10.00);
    });
    test('Month 7 Result = ${monthlyPlan.getMonthlyAmount(7)}', () {
      expect(monthlyPlan.getMonthlyAmount(7), 0.00);
    });
    test('Month 9 Result = ${monthlyPlan.getMonthlyAmount(9)}', () {
      expect(monthlyPlan.getMonthlyAmount(9), 0.00);
    });
    test('Month 10 Result = ${monthlyPlan.getMonthlyAmount(10)}', () {
      expect(monthlyPlan.getMonthlyAmount(10), 0.00);
    });
    test('Month 12 Result = ${monthlyPlan.getMonthlyAmount(12)}', () {
      expect(monthlyPlan.getMonthlyAmount(12), 0.00);
    });
    test('New YearlyAmount Result = ${monthlyPlan.yearlyAmount}', () {
      expect(monthlyPlan.yearlyAmount, 60.00);
    });
  });

  group('Six  Monthly Plan Test Cases; with monthly update in month 8.', () {
    MonthlyPlan monthlyPlan = MonthlyPlan();
    monthlyPlan.initialize(240.00, beginMonth: 4, finalMonth: 9);
    monthlyPlan.updateMonthlyAmount(8, 0.0);
    monthlyPlan.updateMonthlyAmount(9, 0.0);
    test('Month 1 Result = ${monthlyPlan.getMonthlyAmount(1)}', () {
      expect(monthlyPlan.getMonthlyAmount(1), 0.00);
    });
    test('Month 3 Result = ${monthlyPlan.getMonthlyAmount(1)}', () {
      expect(monthlyPlan.getMonthlyAmount(3), 0.00);
    });
    test('Month 4 Result = ${monthlyPlan.getMonthlyAmount(4)}', () {
      expect(monthlyPlan.getMonthlyAmount(6), 20.00);
    });
    test('Month 7 Result = ${monthlyPlan.getMonthlyAmount(7)}', () {
      expect(monthlyPlan.getMonthlyAmount(7), 20.00);
    });
    test('Month 8 Result = ${monthlyPlan.getMonthlyAmount(8)}', () {
      expect(monthlyPlan.getMonthlyAmount(8), 0.00);
    });
    test('Month 9 Result = ${monthlyPlan.getMonthlyAmount(9)}', () {
      expect(monthlyPlan.getMonthlyAmount(9), 40.00);
    });
    test('Month 10 Result = ${monthlyPlan.getMonthlyAmount(10)}', () {
      expect(monthlyPlan.getMonthlyAmount(10), 0.00);
    });
    test('Month 12 Result = ${monthlyPlan.getMonthlyAmount(12)}', () {
      expect(monthlyPlan.getMonthlyAmount(12), 0.00);
    });
    test('New YearlyAmount Result = ${monthlyPlan.yearlyAmount}', () {
      expect(monthlyPlan.yearlyAmount, 120.00);
    });
  });
}
