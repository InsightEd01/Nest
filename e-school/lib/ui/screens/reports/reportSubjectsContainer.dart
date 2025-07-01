import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/studentDashboardCubit.dart';
import 'package:eschool/data/models/subject.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/shimmerLoaders/subjectsShimmerLoadingContainer.dart';
import 'package:eschool/ui/widgets/studentSubjectsContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/uiUtils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportSubjectsContainer extends StatefulWidget {
  final int? childId;
  final List<Subject>? subjects;
  const ReportSubjectsContainer({super.key, this.childId, this.subjects});

  @override
  ReportSubjectsContainerState createState() => ReportSubjectsContainerState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments! as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => ReportSubjectsContainer(
        childId: arguments['childId'],
        subjects: arguments['subjects'],
      ),
    );
  }
}

class ReportSubjectsContainerState extends State<ReportSubjectsContainer> {
  List<Subject>? subjects;

  @override
  void initState() {
    super.initState();
    if (widget.subjects != null) subjects = List.from(widget.subjects!);
  }

  Widget _buildAppBar() {
    return ScreenTopBackgroundContainer(
      padding: EdgeInsets.zero,
      heightPercentage: UiUtils.appBarSmallerHeightPercentage,
      child: Stack(
        children: [
          context.read<AuthCubit>().isParent()
              ? CustomBackButton(
                  topPadding: MediaQuery.of(context).padding.top +
                      UiUtils.appBarContentTopPadding,
                )
              : const SizedBox.shrink(),
          Align(
            child: Text(
              UiUtils.getTranslatedLabel(context, subjectsKey),
              style: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
                fontSize: UiUtils.screenTitleFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMySubjects() {
    //remove blank subject entry [added for all assignment filter from previous screen]
    if (context.read<AuthCubit>().isParent() && subjects != null) {
      subjects!.removeWhere((element) => element.id == 0);
    }
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: UiUtils.getScrollViewTopPadding(
          context: context,
          appBarHeightPercentage: UiUtils.appBarSmallerHeightPercentage,
        ),
      ),
      child: (context.read<AuthCubit>().isParent())
          ? subjects!.isEmpty
              ? const NoDataContainer(titleKey: noSubjectsKey)
              : StudentSubjectsContainer(
                  subjects: subjects!,
                  subjectsTitleKey: '', //already shown in title
                  childId: widget.childId,
                  showReport: true,
                )
          : BlocBuilder<StudentDashboardCubit, StudentDashboardState>(
              builder: (context, state) {
                if (state is StudentDashboardFetchSuccess) {
                  if (context
                      .read<StudentDashboardCubit>()
                      .getSubjects()
                      .isEmpty) {
                    return const NoDataContainer(titleKey: noSubjectsKey);
                  }
                  return StudentSubjectsContainer(
                    subjects:
                        context.read<StudentDashboardCubit>().getSubjects(),
                    subjectsTitleKey: '', //already shown in title
                    childId: context.read<AuthCubit>().getStudentDetails().id,
                    showReport: true,
                  );
                }
                if (state is StudentDashboardFetchFailure) {
                  return Center(
                    child: ErrorContainer(
                      errorMessageCode: state.errorMessage,
                      onTapRetry: () {
                        context.read<StudentDashboardCubit>().fetchDashboard();
                      },
                    ),
                  );
                }
                return Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * (0.025),
                    ),
                    const SubjectsShimmerLoadingContainer(),
                  ],
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return (context.read<AuthCubit>().isParent())
        ? Scaffold(
            body: Stack(
              children: [
                _buildMySubjects(),
                Align(
                  alignment: Alignment.topCenter,
                  child: _buildAppBar(),
                ),
              ],
            ),
          )
        : Stack(
            children: [
              _buildMySubjects(),
              Align(
                alignment: Alignment.topCenter,
                child: _buildAppBar(),
              ),
            ],
          );
  }
}
