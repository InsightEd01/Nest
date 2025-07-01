import 'package:eschool/data/models/student.dart';
import 'package:eschool/ui/widgets/customUserProfileImageWidget.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/ui/widgets/dynamicFieldListContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/uiUtils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class StudentProfileScreen extends StatefulWidget {
  final Student studentDetails;

  const StudentProfileScreen({super.key, required this.studentDetails});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();

  static Route route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => StudentProfileScreen(
        studentDetails: routeSettings.arguments! as Student,
      ),
    );
  }
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  Widget _buildProfileDetailsTile({
    required String label,
    required String value,
    required String iconUrl,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12.5),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1a212121),
                  offset: Offset(0, 10),
                  blurRadius: 16,
                ),
              ],
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: SvgPicture.asset(
              iconUrl,
              colorFilter: iconColor == null
                  ? null
                  : ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * (0.05),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(top: 3.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w400,
                      fontSize: 12.0,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: CustomAppBar(
        title: UiUtils.getTranslatedLabel(context, profileKey),
      ),
    );
  }

  Widget _buildProfileDetailsContainer() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: UiUtils.getScrollViewTopPadding(
            context: context,
            appBarHeightPercentage: UiUtils.appBarSmallerHeightPercentage,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * (0.25),
              height: MediaQuery.of(context).size.width * (0.25),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              child: CustomUserProfileImageWidget(
                profileUrl: widget.studentDetails.image,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              widget.studentDetails.getFullName(),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 18.0,
              ),
            ),
            const SizedBox(
              height: 5.0,
            ),
            Text(
              "${UiUtils.getTranslatedLabel(context, grNumberKey)} - ${widget.studentDetails.admissionNo}",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12.0,
              ),
            ),
            const SizedBox(
              height: 10.0,
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * (0.075),
              ),
              child: Divider(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(
              height: 10.0,
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * (0.075),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      UiUtils.getTranslatedLabel(context, personalDetailsKey),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  _buildProfileDetailsTile(
                    label: UiUtils.getTranslatedLabel(context, classKey),
                    value: UiUtils.formatEmptyValue(
                      widget.studentDetails
                          .classSectionNameWithSemester(context: context),
                    ),
                    iconUrl: UiUtils.getImagePath("user_pro_class_icon.svg"),
                  ),
                  _buildProfileDetailsTile(
                    label: UiUtils.getTranslatedLabel(context, mediumKey),
                    value: UiUtils.formatEmptyValue(
                      widget.studentDetails.mediumName,
                    ),
                    iconUrl: UiUtils.getImagePath("medium_icon.svg"),
                  ),
                  if (widget.studentDetails.shift != null &&
                      widget.studentDetails.shift!.title.trim().isNotEmpty)
                    _buildProfileDetailsTile(
                      label: UiUtils.getTranslatedLabel(context, shiftKey),
                      value: UiUtils.formatEmptyValue(
                        "${widget.studentDetails.shift!.title}${widget.studentDetails.shift!.startToEndTime == null ? '' : ' (${widget.studentDetails.shift!.startToEndTime})'}",
                      ),
                      iconUrl: UiUtils.getImagePath("user_pro_shift_icon.svg"),
                    ),
                  _buildProfileDetailsTile(
                    label: UiUtils.getTranslatedLabel(context, rollNumberKey),
                    value: widget.studentDetails.rollNumber.toString(),
                    iconUrl: UiUtils.getImagePath("user_pro_roll_no_icon.svg"),
                  ),
                  _buildProfileDetailsTile(
                    label: UiUtils.getTranslatedLabel(context, dateOfBirthKey),
                    value: UiUtils.formatEmptyValue(
                        DateTime.tryParse(widget.studentDetails.dob) == null
                            ? widget.studentDetails.dob
                            : UiUtils.formatDate(
                                DateTime.tryParse(widget.studentDetails.dob)!,),),
                    iconUrl: UiUtils.getImagePath("user_pro_dob_icon.svg"),
                  ),
                  _buildProfileDetailsTile(
                    label: UiUtils.getTranslatedLabel(
                      context,
                      currentAddressKey,
                    ),
                    value: UiUtils.formatEmptyValue(
                      widget.studentDetails.currentAddress,
                    ),
                    iconUrl: UiUtils.getImagePath("user_pro_address_icon.svg"),
                  ),
                  _buildProfileDetailsTile(
                    label: UiUtils.getTranslatedLabel(
                      context,
                      permanentAddressKey,
                    ),
                    value: UiUtils.formatEmptyValue(
                      widget.studentDetails.permanentAddress,
                    ),
                    iconUrl: UiUtils.getImagePath("user_pro_address_icon.svg"),
                  ),
                  _buildProfileDetailsTile(
                    label: UiUtils.getTranslatedLabel(context, bloodGroupKey),
                    value: UiUtils.formatEmptyValue(
                      widget.studentDetails.bloodGroup,
                    ),
                    iconUrl: UiUtils.getImagePath("blood_icon.svg"),
                  ),
                  _buildProfileDetailsTile(
                    label: UiUtils.getTranslatedLabel(context, weightKey),
                    value: UiUtils.formatEmptyValue(
                      widget.studentDetails.weight,
                    ),
                    iconUrl: UiUtils.getImagePath("weight_icon.svg"),
                  ),
                  _buildProfileDetailsTile(
                    label: UiUtils.getTranslatedLabel(context, heightKey),
                    value: UiUtils.formatEmptyValue(
                      widget.studentDetails.height,
                    ),
                    iconUrl: UiUtils.getImagePath("height_icon.svg"),
                  ),
                ],
              ),
            ),
            //dynamic field data
            if (widget.studentDetails.dynamicFields != null)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * (0.075),
                ),
                child: Divider(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.75),
                ),
              ),
            if (widget.studentDetails.dynamicFields?.isNotEmpty ?? false) ...[
              const SizedBox(
                height: 10.0,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * (0.075),
                ),
                child: DynamicFieldListContainer(
                  dynamicFields: widget.studentDetails.dynamicFields!,
                ),
              ),
            ],
            SizedBox(
              height: MediaQuery.of(context).size.height * (0.1),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildProfileDetailsContainer(),
          _buildAppBar(),
        ],
      ),
    );
  }
}
