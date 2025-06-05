enum ProviderJsonLabel {
  self('self'),
  spouse('spouse'),
  planInfo('planInfo'),
  taxFilingInfo('taxFilingInfo'),
  incomeInfos('incomes'),
  accountInfos('accounts'),
  scenarioInfos('scenarios');

  final String label;

  const ProviderJsonLabel(this.label);
}
