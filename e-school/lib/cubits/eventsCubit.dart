import 'package:equatable/equatable.dart';
import 'package:eschool/data/models/event.dart';
import 'package:eschool/data/repositories/systemInfoRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class EventsState extends Equatable {}

class EventsInitial extends EventsState {
  @override
  List<Object?> get props => [];
}

class EventsFetchInProgress extends EventsState {
  @override
  List<Object?> get props => [];
}

class EventsFetchSuccess extends EventsState {
  final List<Event> events;

  EventsFetchSuccess({required this.events});
  @override
  List<Object?> get props => [events];
}

class EventsFetchFailure extends EventsState {
  final String errorMessage;

  EventsFetchFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class EventsCubit extends Cubit<EventsState> {
  final SystemRepository _systemRepository;

  EventsCubit(this._systemRepository) : super(EventsInitial());

  Future<void> fetchEvents() async {
    emit(EventsFetchInProgress());
    try {
      emit(
        EventsFetchSuccess(
          events: await _systemRepository.fetchEvents(),
        ),
      );
    } catch (e) {
      emit(EventsFetchFailure(e.toString()));
    }
  }

  List<Event> events() {
    if (state is EventsFetchSuccess) {
      return (state as EventsFetchSuccess).events;
    }
    return [];
  }
}
