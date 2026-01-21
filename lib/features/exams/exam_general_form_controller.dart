import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'exam_models.dart';

class SectionInput {
  final int correct;
  final int wrong;

  const SectionInput({this.correct = 0, this.wrong = 0});

  SectionInput copyWith({int? correct, int? wrong}) => SectionInput(
        correct: correct ?? this.correct,
        wrong: wrong ?? this.wrong,
      );

  double get net => correct - (wrong / 4.0);
}

class GeneralFormState {
  final ExamType type;
  final String name;
  final Map<String, SectionInput> inputs;
  final Set<String> wrongTopics;

  const GeneralFormState({
    required this.type,
    this.name = '',
    this.inputs = const {},
    this.wrongTopics = const {},
  });

  GeneralFormState copyWith({
    String? name,
    Map<String, SectionInput>? inputs,
    Set<String>? wrongTopics,
  }) {
    return GeneralFormState(
      type: type,
      name: name ?? this.name,
      inputs: inputs ?? this.inputs,
      wrongTopics: wrongTopics ?? this.wrongTopics,
    );
  }
}

final generalExamFormProvider = StateNotifierProvider.autoDispose
    .family<GeneralExamFormController, GeneralFormState, ExamType>(
  (ref, type) => GeneralExamFormController(type),
);

class GeneralExamFormController extends StateNotifier<GeneralFormState> {
  GeneralExamFormController(ExamType type) : super(GeneralFormState(type: type));

  void ensureSections(List<String> sections) {
    final next = Map<String, SectionInput>.from(state.inputs);
    for (final s in sections) {
      next.putIfAbsent(s, () => const SectionInput());
    }
    next.removeWhere((k, _) => !sections.contains(k));
    state = state.copyWith(inputs: next);
  }

  void setName(String name) => state = state.copyWith(name: name);

  void setCorrect(String section, int value) {
    final cur = state.inputs[section] ?? const SectionInput();
    state = state.copyWith(
      inputs: {...state.inputs, section: cur.copyWith(correct: value < 0 ? 0 : value)},
    );
  }

  void setWrong(String section, int value) {
    final cur = state.inputs[section] ?? const SectionInput();
    state = state.copyWith(
      inputs: {...state.inputs, section: cur.copyWith(wrong: value < 0 ? 0 : value)},
    );
  }

  void toggleWrongTopic(String key) {
    final next = <String>{...state.wrongTopics};
    next.contains(key) ? next.remove(key) : next.add(key);
    state = state.copyWith(wrongTopics: next);
  }

  double totalNet() => state.inputs.values.fold(0.0, (sum, e) => sum + e.net);

  bool isValid() => state.name.trim().isNotEmpty;
}
