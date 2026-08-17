import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/organizer_repository.dart';

class OrganizerState {
  final dynamic metrics;
  final bool isLoading;
  final String? error;

  const OrganizerState({
    this.metrics,
    this.isLoading = true,
    this.error,
  });

  OrganizerState copyWith({
    dynamic metrics,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return OrganizerState(
      metrics: metrics ?? this.metrics,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OrganizerViewModel extends Notifier<OrganizerState> {
  late final OrganizerRepository _repository;

  @override
  OrganizerState build() {
    _repository = OrganizerRepository();
    fetchMetrics();
    return const OrganizerState();
  }

  Future<void> fetchMetrics() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repository.fetchDashboard();
      if (res['success'] == true) {
        state = state.copyWith(
          metrics: res['data'],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res['message']?.toString() ?? 'Gagal memuat metrik.',
        );
      }
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat metrik.',
      );
    }
  }
}

final organizerProvider = NotifierProvider<OrganizerViewModel, OrganizerState>(OrganizerViewModel.new);
