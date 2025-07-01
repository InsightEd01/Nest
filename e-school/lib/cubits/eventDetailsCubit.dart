import 'package:eschool/data/models/eventSchedule.dart';
import 'package:eschool/data/repositories/systemInfoRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class EventDetailsState {}

class EventDetailsInitial extends EventDetailsState {}

class EventDetailsFetchInProgress extends EventDetailsState {}

class EventDetailsFetchSuccess extends EventDetailsState {
  final List<EventSchedule> eventDetails;
  final List<DateTime> sortedDates;

  EventDetailsFetchSuccess(
      {required this.eventDetails, required this.sortedDates,});
}

class EventDetailsFetchFailure extends EventDetailsState {
  final String errorMessage;

  EventDetailsFetchFailure(this.errorMessage);
}

class EventDetailsCubit extends Cubit<EventDetailsState> {
  final SystemRepository _systemRepository;

  EventDetailsCubit(this._systemRepository) : super(EventDetailsInitial());

  Future<void> fetchEventDetails({required String eventId}) async {
    emit(EventDetailsFetchInProgress());
    try {
      final List<EventSchedule> schedules =
          await _systemRepository.fetchEventDetails(eventId: eventId);
      final List<DateTime> days = schedules.map<DateTime>((e) => e.date).toList();

      // Sorting the list of dates in ascending order
      days.sort((a, b) => a.compareTo(b));

      // Removing duplicate dates
      final List<DateTime> uniqueDates = days.toSet().toList();

      emit(
        EventDetailsFetchSuccess(
          eventDetails: schedules,
          sortedDates: uniqueDates,
        ),
      );
    } catch (e) {
      emit(EventDetailsFetchFailure(e.toString()));
    }
  }
}
