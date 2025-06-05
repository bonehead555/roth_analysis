// Traditionally, required minimum distributions (RMDs) have started at age 70 and 1/2 (born before July 1949) 
// or age 72 (born between July 1949 and December 1950). 
// But the Secure 2.0 Act increased the starting age to 73 for individuals born in 1951 or later. 

// Usable for your IRA and and spouseal inherited IRA when there in no more than
// ten yers between self and spouse.
import 'package:roth_analysis/utilities/number_utilities.dart';

Map<int, double> _uniformLifetimeTablePost121950 = {
73:	26.5,
74:	25.5,
75:	24.6,
76:	23.7,
77: 22.9,
78:	22.0,
79:	21.1,
80:	20.2,
81:	19.4,
82: 18.5,
83: 17.7,
84:	16.8,
85:	16.0,
86:	15.2,
87:	14.4,
88:	13.7,
89:	12.9,
90:	12.2,
91:	11.5,
92:	10.8,
93:	10.1,
94:	9.5,
95:	8.9,
96:	8.4,
97:	7.8,
98:	7.3,
99:	6.8,
100: 6.4,
101: 6.0,
102: 5.6,
103: 5.2,
104: 4.9,
105: 4.6,
106: 4.3,
107: 4.1,
108: 3.9,
109: 3.7,
110: 3.5,
111: 3.4,
112: 3.3,
113: 3.1,
114: 3.0 , 
115: 2.9,
116: 2.8,
117: 2.7,
118: 2.5,
119: 2.3,
120: 2.0,
};

Map<int, double> _uniformLifetimeTablePre121950 = {
  72: 27.4,
  73: 26.5,
  74: 25.5,
  75: 24.6,
  76: 23.7,
  77: 22.9,
  78: 22.0,
  79: 21.1,
  80: 20.2,
  81: 19.4,
  82: 18.5,
  83: 17.7,
  84: 16.8,
  85: 16.0,
  86: 15.2,
  87: 14.4,
  88: 13.7,
  89: 12.9,
  90: 12.2,
  91: 11.5,
  92: 10.8,
  93: 10.1,
  94: 9.5,
  95: 8.9,
  96: 8.4,
  97: 7.8,
  98: 7.3,
  99: 6.8,
  100: 6.4,
  101: 6.0,
  102: 5.6,
  103: 5.2,
  104: 4.9,
  105: 4.6,
  106: 4.3,
  107: 4.1,
  108: 3.9,
  109: 3.7,
  110: 3.5,
  111: 3.4,
  112: 3.3,
  113: 3.1,
  114: 3.0,
  115: 2.9,
  116: 2.8,
  117: 2.7,
  118: 2.5,
  119: 2.3,
  120: 2.0,
};

Map<int, double> _uniformLifetimeTablePre071949 = {
  70: 27.4,
  71: 26.5,
  72: 25.6,
  73: 24.7,
  74: 23.8,
  75: 22.9,
  76: 22.0,
  77: 21.2,
  78: 20.4,
  79: 19.5,
  80: 18.7,
  81: 17.9,
  82: 17.1,
  83: 16.3,
  84: 15.5,
  85: 14.8,
  86: 14.1,
  87: 13.4,
  88: 12.7,
  89: 12.0,
  90: 11.4,
  91: 10.8,
  92: 10.2,
  93: 9.6,
  94: 9.1,
  95: 8.6,
  96: 8.1,
  97: 7.6,
  98: 7.1,
  99: 6.7,
  100: 6.3,
  101: 5.9,
  102: 5.5,
  103: 5.2,
  104: 4.9,
  105: 4.5,
  106: 4.2,
  107: 3.9,
  108: 3.7,
  109: 3.4,
  110: 3.1,
  111: 2.9,
  112: 2.6,
  113: 2.4,
  114: 2.1,
  115: 1.9,
};

/// Returns the appropiate lifetime table for the sepcified [birthDate].
Map<int, double> getLifeTimeTable(DateTime birthDate) {
  Map<int, double> lifetimeTable;
  if (birthDate.isBefore(DateTime(1949, 7, 1))) {
    lifetimeTable = _uniformLifetimeTablePre071949;
  } else if (birthDate.isBefore(DateTime(1950, 12, 31))) {
    lifetimeTable = _uniformLifetimeTablePre121950;
  }
  else {
    lifetimeTable = _uniformLifetimeTablePost121950;
  }
  return lifetimeTable;
}

/// Returns the year that RMDs must start for someone born on specified [birthDate]
int rmdStartYear(DateTime birthDate) {
  Map<int, double> lifetimeTable = getLifeTimeTable(birthDate);
  final int rmdAge = lifetimeTable.keys.first;
  return birthDate.year + rmdAge;
}

/// Returns an estimate of the required minimim distribution for an IRA account where:
/// [iraBalance] - the balance in the account on December 31 of year previous to [targetYear]
/// [birthDate] - the birthdate of the account owner.
/// [targetYear] - the year the RMD would be taken
double rmdEstimator(double iraBalance, DateTime birthDate, int targetYear) {
  double result;
  Map<int, double> lifetimeTable = getLifeTimeTable(birthDate);

  int age = targetYear - birthDate.year;
  MapEntry<int, double> firstEntry = lifetimeTable.entries.first;
  MapEntry<int, double> lastEntry = lifetimeTable.entries.last;
  if (age < firstEntry.key) {
    result = 0.0;
  } else if (age > lastEntry.key) {
    result = iraBalance/lastEntry.value;
  } else {
    result = iraBalance / lifetimeTable[age]!;
  }
  return result.roundToTwoPlaces();
}