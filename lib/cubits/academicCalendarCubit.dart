import 'package:eschool/data/models/academicCalendar.dart';
import 'package:eschool/data/models/event.dart';
import 'package:eschool/data/models/exam.dart';
import 'package:eschool/data/models/holiday.dart';
import 'package:eschool/data/repositories/studentRepository.dart';
import 'package:eschool/data/repositories/systemInfoRepository.dart';
import 'package:eschool/ui/screens/academicCalendar/academicCalendarScreen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AcademicCalendarState {}

class AcademicCalendarInitial extends AcademicCalendarState {}

class AcademicCalendarFetchInProgress extends AcademicCalendarState {}

class AcademicCalendarFetchSuccess extends AcademicCalendarState {
  final List<AcademicCalendar> academicCalendarItems;

  AcademicCalendarFetchSuccess({required this.academicCalendarItems});
}

class AcademicCalendarFetchFailure extends AcademicCalendarState {
  final String errorMessage;

  AcademicCalendarFetchFailure(this.errorMessage);
}

class AcademicCalendarCubit extends Cubit<AcademicCalendarState> {
  final SystemRepository _systemRepository;
  final StudentRepository _studentRepository;

  AcademicCalendarCubit(this._systemRepository, this._studentRepository)
      : super(AcademicCalendarInitial());

  Future<void> fetchData({int? childId}) async {
    emit(AcademicCalendarFetchInProgress());
    try {
      emit(
        AcademicCalendarFetchSuccess(
          academicCalendarItems: [
            ...(await _systemRepository.fetchHolidays()).map<AcademicCalendar>(
                (holiday) => AcademicCalendar<Holiday>(
                    data: holiday,
                    date: holiday.date,
                    highlightColor: AcademicCalendarScreen.holidayColor,),),
            ...(await _systemRepository.fetchEvents()).map<AcademicCalendar>(
                (event) => AcademicCalendar<Event>(
                    data: event,
                    date: event.startDate,
                    highlightColor: AcademicCalendarScreen.eventColor,
                    rangeEndDate: event.endDate,),),
            ...(await _studentRepository.fetchExamsList(
              childId: childId ?? 0,
              examStatus: 0,
              useParentApi: childId != null,
              getTimetable: true,
            ))
                .map<AcademicCalendar>((exam) => AcademicCalendar<Exam>(
                    data: exam,
                    date: exam.getStartDate(),
                    highlightColor: AcademicCalendarScreen.examColor,
                    rangeEndDate: exam.getEndDate(),),),
          ],
        ),
      );
    } catch (e) {
      emit(AcademicCalendarFetchFailure(e.toString()));
    }
  }

  List<AcademicCalendar> calendarItems() {
    if (state is AcademicCalendarFetchSuccess) {
      return (state as AcademicCalendarFetchSuccess).academicCalendarItems;
    }
    return [];
  }
}
