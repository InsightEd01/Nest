import 'package:eschool/cubits/addLeaveCubit.dart';
import 'package:eschool/cubits/appConfigurationCubit.dart';
// import 'package:eschool/cubits/appConfigurationCubit.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/holidaysCubit.dart';
import 'package:eschool/data/models/leave.dart';
import 'package:eschool/data/models/student.dart';
import 'package:eschool/data/repositories/leaveRepository.dart';
import 'package:eschool/data/repositories/systemInfoRepository.dart';
import 'package:eschool/ui/screens/leave/widgets/oneDayLeaveStatusContainer.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/bottomSheetTextFiledContainer.dart';
import 'package:eschool/ui/widgets/bottomsheetAddFilesDottedBorderContainer.dart';
// import 'package:eschool/ui/widgets/bottomSheetTextFiledContainer.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
// import 'package:eschool/ui/widgets/customTextFieldContainer.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/uiUtils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

class AddLeaveScreen extends StatefulWidget {
  final Student studentDetails;
  const AddLeaveScreen({super.key, required this.studentDetails});

  @override
  State<AddLeaveScreen> createState() => _AddLeaveScreenState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments! as Map<String, dynamic>;

    return CupertinoPageRoute<bool?>(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<AddLeaveCubit>(
            create: (context) => AddLeaveCubit(LeaveRepository()),
          ),
          BlocProvider<HolidaysCubit>(
              create: (context) => HolidaysCubit(SystemRepository()),),
        ],
        child: AddLeaveScreen(studentDetails: arguments['studentDetails']),
      ),
    );
  }
}

class _AddLeaveScreenState extends State<AddLeaveScreen> {
  final TextEditingController _reasonTextController = TextEditingController();
  List<PlatformFile> pickedAttachements = [];
  DateTimeRange? pickedDateRange;

  List<LeaveDateWithType> leaveDetails = [];

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      //fetching holidays as they won't be counted in the leave calculation
      context.read<HolidaysCubit>().fetchHolidays();
    });
    super.initState();
  }

  @override
  void dispose() {
    _reasonTextController.dispose();
    super.dispose();
  }

  List<DateTime> datesBetween(DateTime start, DateTime end) {
    final List<DateTime> dates = [];
    DateTime date = start;

    while (date.isBefore(end) || date.isAtSameMomentAs(end)) {
      dates.add(date);
      date = date.add(const Duration(days: 1));
    }

    return dates;
  }

  void _setLeaveDetails() {
    if (leaveDetails.isNotEmpty) {
      leaveDetails.clear();
    }
    final List<DateTime> allDates =
        datesBetween(pickedDateRange!.start, pickedDateRange!.end);
    for (final date in allDates) {
      //if the date is a holiday, don't add it to leave details
      if (context
          .read<HolidaysCubit>()
          .holidays()
          .any((element) => element.date.isSameAs(date))) {
        continue;
      } else if (context
          .read<AppConfigurationCubit>()
          .getHolidayWeekDays()
          .contains(date.getWeekDayName().toLowerCase())) {
        continue;
      }
      leaveDetails.add(LeaveDateWithType(date: date, type: LeaveType.full));
    }
  }

  void _pickDateRange() {
    showDateRangePicker(
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  onPrimary: Theme.of(context).scaffoldBackgroundColor,
                ),
          ),
          child: child!,
        );
      },
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((range) {
      FocusScope.of(context).unfocus();
      if (range != null) {
        setState(() {
          pickedDateRange = range;
          _setLeaveDetails();
        });
      }
    });
  }

  void addLeaveRequest() {
    if (_reasonTextController.text.trim().isEmpty) {
      UiUtils.showCustomSnackBar(
        context: context,
        errorMessage: UiUtils.getTranslatedLabel(context, reasonRequiredKey),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } else if (pickedDateRange == null) {
      UiUtils.showCustomSnackBar(
        context: context,
        errorMessage:
            UiUtils.getTranslatedLabel(context, pickDateRangeToSubmitKey),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } else if (leaveDetails.isEmpty) {
      UiUtils.showCustomSnackBar(
        context: context,
        errorMessage: UiUtils.getTranslatedLabel(
          context,
          pickValidDateRangeWithoutHolidaysKey,
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } else {
      context.read<AddLeaveCubit>().addLeave(
          reason: _reasonTextController.text,
          leaveDetails: leaveDetails,
          filePaths: pickedAttachements
              .map<String>((element) => element.path ?? '')
              .toList(),
          isParent: context.read<AuthCubit>().isParent(),
          childId: widget.studentDetails.id,);
    }
  }

  Widget _buildSubmitButton() {
    return BlocConsumer<AddLeaveCubit, AddLeaveState>(
      listener: (context, state) {
        if (state is AddLeaveSuccess) {
          UiUtils.showCustomSnackBar(
            context: context,
            errorMessage: UiUtils.getTranslatedLabel(
              context,
              UiUtils.getTranslatedLabel(
                  context, leaveRequestAddedSuccessfullyKey,),
            ),
            backgroundColor: Theme.of(context).colorScheme.onPrimary,
          );
          Navigator.of(context).pop(true); //to refresh the previous page
        } else if (state is AddLeaveFailure) {
          UiUtils.showCustomSnackBar(
            context: context,
            errorMessage: UiUtils.getErrorMessageFromErrorCode(
              context,
              state.errorMessage,
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      },
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * .18,
          ),
          child: CustomRoundedButton(
            onTap: () {
              if (state is AddLeaveInProgress) {
                return;
              }
              addLeaveRequest();
            },
            height: 45,
            widthPercentage: MediaQuery.of(context).size.width * (0.6),
            backgroundColor: Theme.of(context).colorScheme.primary,
            buttonTitle: UiUtils.getTranslatedLabel(
              context,
              submitLeaveKey,
            ),
            showBorder: false,
            child: state is AddLeaveInProgress
                ? const CustomCircularProgressIndicator(
                    strokeWidth: 2,
                    widthAndHeight: 20,
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildAddLeaveForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: 25,
        right: UiUtils.screenContentHorizontalPaddingInPercentage *
            MediaQuery.of(context).size.width,
        left: UiUtils.screenContentHorizontalPaddingInPercentage *
            MediaQuery.of(context).size.width,
        top: UiUtils.getScrollViewTopPadding(
            context: context,
            appBarHeightPercentage: UiUtils.appBarSmallerHeightPercentage,),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BottomSheetTextFieldContainer(
            hintText: UiUtils.getTranslatedLabel(context, reasonKey),
            margin: const EdgeInsets.only(bottom: 20),
            maxLines: 4,
            textEditingController: _reasonTextController,
          ),
          GestureDetector(
            onTap: _pickDateRange,
            child: BottomSheetTextFieldContainer(
              hideText: false,
              margin: const EdgeInsets.only(bottom: 20),
              hintText: UiUtils.getTranslatedLabel(context, fromDateKey),
              maxLines: 1,
              disabled: true,
              contentPadding: const EdgeInsetsDirectional.only(start: 15),
              textEditingController: TextEditingController(
                  text: pickedDateRange != null
                      ? UiUtils.formatDate(pickedDateRange!.start)
                      : null,),
            ),
          ),
          GestureDetector(
            onTap: _pickDateRange,
            child: BottomSheetTextFieldContainer(
              margin: const EdgeInsets.only(bottom: 20),
              hintText: UiUtils.getTranslatedLabel(context, toDateKey),
              maxLines: 1,
              disabled: true,
              contentPadding: const EdgeInsetsDirectional.only(start: 15),
              textEditingController: TextEditingController(
                  text: pickedDateRange != null
                      ? UiUtils.formatDate(pickedDateRange!.end)
                      : null,),
            ),
          ),
          BottomsheetAddFilesDottedBorderContainer(
            onTap: () async {
              FocusScope.of(context).unfocus();
              final permission = await Permission.storage.request();
              if (permission.isGranted) {
                final pickedFile =
                    await FilePicker.platform.pickFiles(allowMultiple: true);
                if (pickedFile != null) {
                  pickedAttachements.addAll(pickedFile.files);
                  setState(() {});
                }
              } else {
                try {
                  final pickedFile =
                      await FilePicker.platform.pickFiles(allowMultiple: true);
                  if (pickedFile != null) {
                    pickedAttachements.addAll(pickedFile.files);
                    setState(() {});
                  }
                } on Exception {
                  if (context.mounted) {
                    UiUtils.showCustomSnackBar(
                        context: context,
                        errorMessage: UiUtils.getTranslatedLabel(
                            context, allowStoragePermissionToContinueKey,),
                        backgroundColor: Theme.of(context).colorScheme.error,);
                    await Future.delayed(const Duration(seconds: 2));
                    openAppSettings();
                  }
                }
              }
            },
            title:
                UiUtils.getTranslatedLabel(context, addMultipleAttachmentsKey),
          ),
          if (pickedAttachements.isNotEmpty)
            ...List.generate(
              pickedAttachements.length,
              (index) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          pickedAttachements[index].name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            pickedAttachements.removeAt(index);
                          });
                        },
                        child: Icon(Icons.delete_outline,
                            color: redColor.withValues(alpha: 0.7),),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (leaveDetails.isNotEmpty) ...[
            ...List.generate(
                leaveDetails.length,
                (index) => OneDayLeaveStatusContainer(
                    leaveDayDetails: leaveDetails[index],),),
          ],
          const SizedBox(height: 20),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: BlocBuilder<HolidaysCubit, HolidaysState>(
              builder: (context, state) {
                if (state is HolidaysFetchSuccess) {
                  return _buildAddLeaveForm();
                } else if (state is HolidaysFetchFailure) {
                  return Center(
                    child: ErrorContainer(
                      errorMessageCode: state.errorMessage,
                      onTapRetry: () {
                        context.read<HolidaysCubit>().fetchHolidays();
                      },
                    ),
                  );
                } else {
                  return const CustomCircularProgressIndicator(
                      strokeWidth: 2, widthAndHeight: 20,);
                }
              },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: CustomAppBar(
              title: UiUtils.getTranslatedLabel(context, addLeaveKey),
            ),
          ),
        ],
      ),
    );
  }
}
