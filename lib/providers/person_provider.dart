import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/models/data/person_info.dart';

/// Riverpod provider class for [PersonInfo].
class PersonProvider extends StateNotifier<PersonInfo> {
  PersonProvider() : super(const PersonInfo());

  /// Updates the specified information by creating a new copy of [PersonInfo].
  /// * [birthDate] - Birthdate.
  /// * [isBlind] - True of person is blind.
  /// * [isMarried] - True if person is married.
  void update({DateTime? birthDate, bool? isBlind, bool? isMarried}) {
    state = state.copyWith(
      birthDate: birthDate,
      isBlind: isBlind,
      isMarried: isMarried,
    );
  }

  /// Updates the entire [PersonInfo] with [newInfo].  Used for example when new data is read from a file.
  void updateAll(PersonInfo newInfo) {
    state = newInfo;
  }
}

typedef PersonNotifierProvider
    = StateNotifierProvider<PersonProvider, PersonInfo>;

/// [PersonProvider] for [PersonInfo] represnting the role of self.
final selfProvider = PersonNotifierProvider((ref) {
  return PersonProvider();
});

/// [PersonProvider] for [PersonInfo] represnting the role of spouse.
final spouseProvider = PersonNotifierProvider((ref) {
  return PersonProvider();
});
