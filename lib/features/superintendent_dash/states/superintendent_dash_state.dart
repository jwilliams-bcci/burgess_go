import 'package:burgess_go/core/models/inspection/inspection.dart';

class SuperintendentDashState {
  final List<Inspection> inspections;
  final List<Inspection> failedInspections;
  final List<Inspection> upcomingInspections;
  final bool isLoading;

  SuperintendentDashState({
    this.inspections = const [],
    this.failedInspections = const [],
    this.upcomingInspections = const [],
    this.isLoading = true,
  });

  SuperintendentDashState copyWith({
    List<Inspection>? inspections,
    List<Inspection>? failedInspections,
    List<Inspection>? upcomingInspections,
    bool? isLoading,
  }) {
    return SuperintendentDashState(
      inspections: inspections ?? this.inspections,
      failedInspections: failedInspections ?? this.failedInspections,
      upcomingInspections: upcomingInspections ?? this.upcomingInspections,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
