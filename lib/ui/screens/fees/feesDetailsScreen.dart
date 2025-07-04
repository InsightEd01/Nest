import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/appConfigurationCubit.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/feesPaymentCubit.dart';
import 'package:eschool/cubits/studentDetailedFeesCubit.dart';
import 'package:eschool/data/models/fees.dart';
import 'package:eschool/data/models/student.dart';
import 'package:eschool/data/repositories/studentRepository.dart';
import 'package:eschool/ui/screens/fees/widgets/paymentSelection.dart';
import 'package:eschool/ui/screens/fees/widgets/studentDownloadFeePaidReceiptButton.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/ui/widgets/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/customTabBarContainer.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/shimmerLoadingContainer.dart';
import 'package:eschool/ui/widgets/tabBarBackgroundContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/uiUtils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/utils/stripeService.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class FeesDetailsScreen extends StatefulWidget {
  final bool isStudentPaying;
  final Student? studentDetails;
  final int? sessionYearId;
  final int? childId;

  const FeesDetailsScreen(
      {super.key,
      required this.studentDetails,
      required this.sessionYearId,
      required this.isStudentPaying,
      this.childId,});

  @override
  FeesDetailsScreenState createState() => FeesDetailsScreenState();
  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments! as Map<String, dynamic>;
    if (arguments['childId'] != null) {
      return CupertinoPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => StudentDetailedFeesCubit(StudentRepository()),
          child: FeesDetailsScreen(
              studentDetails: null,
              sessionYearId: null,
              isStudentPaying: false,
              childId: int.tryParse(arguments['childId'].toString()),),
        ),
      );
    }
    return CupertinoPageRoute(
      builder: (_) => BlocProvider(
        create: (context) => StudentDetailedFeesCubit(StudentRepository()),
        child: FeesDetailsScreen(
            studentDetails: arguments['studentDetails'],
            sessionYearId: arguments['sessionYearId'],
            isStudentPaying: arguments['isStudentPaying'] ?? false,),
      ),
    );
  }
}

class FeesDetailsScreenState extends State<FeesDetailsScreen> {
  String _selectedTabTitle = compulsoryTitleKey;

  //is installment allowed by the admin
  bool isInstallmentAvailable = false;

  //keeping track of both the tab totals along with the total on UI (feesToBePaid)
  double totalCompulsoryFees = 0;
  double totalOptionalFees = 0;
  double feesToBePaid = 0;

  bool isCompulsoryDue = false;
  double dueChargesOnCompulsoryFees = 0;

  //ids of selected fees by the user
  List<int> optionalChoices = [];
  List<int> installmentsChoices = [];

  //switch variable
  bool isPayAsInstallment = false;

  //forPayNowButton
  bool allInstallmentsPaid = false;
  bool allOptionalPaid = false;
  bool isCompulsoryFullyPaid = false;
  bool pastTransactionPendingVisible = false;

  int totalPaidInstallments = 0;

  double amount = 0;
  int paymentTransactionId = 0;

  String orderId = "order0";
  String paymentIntentId = '';
  String clientSecret = '';

  late final Student studentDetails;
  late final int sessionYearId;

  ///payment
  late Razorpay _razorpay;
  late Map paymentGatewayDetails;
  late String selectedPayment;

  @override
  void initState() {
    if (widget.studentDetails != null) {
      studentDetails = widget.studentDetails!;
      sessionYearId = widget.sessionYearId!;
    } else {
      studentDetails = context
          .read<AuthCubit>()
          .getParentDetails()
          .children
          .firstWhere((element) => element.id == widget.childId);
      sessionYearId = context
          .read<AppConfigurationCubit>()
          .getAppConfiguration()
          .sessionYear
          .id;
    }
    fetchDetailedFees();
    optionalChoices.clear();
    installmentsChoices.clear();

    ///payment
    initialiseEnabledPayments();

    super.initState();
  }

  void initialiseEnabledPayments() {
    if (context.read<AppConfigurationCubit>().getPaymentOptions().razorpay !=
        null) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    }
    if (context.read<AppConfigurationCubit>().getPaymentOptions().stripe !=
        null) {
      StripeService.init(
          context
              .read<AppConfigurationCubit>()
              .getPaymentOptions()
              .stripe!
              .stripePublishableKey,
          null,);
    }
  }

  @override
  void dispose() {
    if (context.read<AppConfigurationCubit>().getPaymentOptions().razorpay !=
        null) {
      _razorpay.clear();
    }
    super.dispose();
  }

  void fetchDetailedFees() {
    Future.delayed(Duration.zero, () {
      context.read<StudentDetailedFeesCubit>().fetchDetailedFees(
          childId: widget.isStudentPaying ? null : studentDetails.id,);
    });
  }

  Widget _buildAppBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: ScreenTopBackgroundContainer(
        child: LayoutBuilder(
          builder: (context, boxConstraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                CustomBackButton(
                  onTap: () {
                    if (context.read<FeesPaymentCubit>().state
                        is FeesPaymentFetchInProgress) {
                      return;
                    }
                    Navigator.of(context).pop();
                  },
                ),
                if (widget.isStudentPaying)
                  Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: UiUtils.screenContentHorizontalPadding,
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context)
                              .pushNamed(Routes.feesTransaction);
                        },
                        child: Icon(
                          Icons.history,
                          color: Theme.of(context).scaffoldBackgroundColor,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            30 + UiUtils.screenContentHorizontalPadding,),
                    child: Text(
                      "${UiUtils.getTranslatedLabel(context, classKey)} ${studentDetails.classSectionName} ${UiUtils.getTranslatedLabel(context, feesKey)}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        fontSize: UiUtils.screenTitleFontSize,
                      ),
                    ),
                  ),
                ),
                //tabs and animated container, tabs won't change while a payment is being processed
                AnimatedAlign(
                    curve: UiUtils.tabBackgroundContainerAnimationCurve,
                    duration: UiUtils.tabBackgroundContainerAnimationDuration,
                    alignment: _selectedTabTitle == compulsoryTitleKey
                        ? AlignmentDirectional.centerStart
                        : AlignmentDirectional.centerEnd,
                    child: TabBarBackgroundContainer(
                        boxConstraints: boxConstraints,),),
                CustomTabBarContainer(
                    boxConstraints: boxConstraints,
                    alignment: AlignmentDirectional.centerStart,
                    isSelected: _selectedTabTitle == compulsoryTitleKey,
                    onTap: () {
                      if (context.read<FeesPaymentCubit>().state
                          is! FeesPaymentFetchInProgress) {
                        setState(() {
                          _selectedTabTitle = compulsoryTitleKey;
                          feesToBePaid = totalCompulsoryFees;
                        });
                      }
                    },
                    titleKey: compulsoryTitleKey,),
                CustomTabBarContainer(
                  boxConstraints: boxConstraints,
                  alignment: AlignmentDirectional.centerEnd,
                  isSelected: _selectedTabTitle == optionalTitleKey,
                  onTap: () {
                    if (context.read<FeesPaymentCubit>().state
                        is! FeesPaymentFetchInProgress) {
                      setState(() {
                        _selectedTabTitle = optionalTitleKey;
                        feesToBePaid = totalOptionalFees;
                      });
                    }
                  },
                  titleKey: optionalTitleKey,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget setRow({
    required FeesData feesData,
    required bool isCheckboxRequired,
    required int id,
    bool isCompulsoryDueRow = false,
    bool isInstallment = false,
    bool isCheckboxSelectable = true,
  }) {
    //1:9:5 screen width division row
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              //if fee is not paid and checkbox is there show it
              if (isCheckboxRequired && !feesData.isPaid)
                Expanded(
                  child: SizedBox(
                    width: 15,
                    height: 15,
                    child: Checkbox(
                      activeColor: Theme.of(context).colorScheme.primary,
                      value: isInstallment
                          ? installmentsChoices.contains(id)
                          : optionalChoices.contains(id),
                      onChanged: !isCheckboxSelectable
                          ? null
                          : (value) => _onChanged(feesData),
                    ),
                  ),
                ),
              //if fee is paid, replace the checkbox with verified mark
              if (feesData.isPaid && isCheckboxRequired)
                const Expanded(
                  child: Align(
                    child: Icon(
                      Icons.verified,
                      color: greenColor,
                    ),
                  ),
                ),
              //it there is no checkbox, add a spaces to take it's space for better UI
              if (!isCheckboxRequired) const Spacer(),
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 15),
                  child: GestureDetector(
                    onTap: () {
                      //if there is a clickable checkbox
                      if (isCheckboxRequired &&
                          !feesData.isPaid &&
                          isCheckboxSelectable) {
                        _onChanged(feesData);
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feesData.name,
                          maxLines: 2,
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                        ),
                        //if paid date is there show it
                        if (feesData.isPaid &&
                            isCheckboxRequired &&
                            feesData.paidDate != null)
                          Text(
                            "${UiUtils.getTranslatedLabel(context, paidOnKey)}: ${UiUtils.formatDate(
                              feesData.paidDate ?? DateTime.now(),
                            )}",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              color: greenColor,
                              fontSize: 10,
                            ),
                          ),
                        // if due date is there and it's not paid, show that
                        if ((isInstallment || isCompulsoryDueRow) &&
                            !feesData.isPaid)
                          Text(
                            "${UiUtils.getTranslatedLabel(context, dueDateKey)}: ${UiUtils.formatDate(
                              feesData.dueDate ?? DateTime.now(),
                            )}, ${UiUtils.getTranslatedLabel(context, chargesKey)}: ${feesData.dueChargesInPercentage}%",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                              color: feesData.isDue ? redColor : null,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        UiUtils.formatAmount(
                          strVal: feesData.amount!.toStringAsFixed(2),
                          context: context,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      //if due charge is there
                      if (feesData.isDue &&
                          feesData.dueChargesAmount != null &&
                          feesData.dueChargesAmount != 0 &&
                          !isCompulsoryDueRow &&
                          !feesData.isPaid)
                        Text(
                          UiUtils.formatAmount(
                            strVal:
                                feesData.dueChargesAmount!.toStringAsFixed(2),
                            context: context,
                          ),
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 10, letterSpacing: 2),
                        ),
                      //paid due charges
                      if (feesData.dueChargesPaid != null &&
                          feesData.dueChargesPaid != 0 &&
                          feesData.isPaid)
                        Text(
                          UiUtils.formatAmount(
                            strVal: feesData.dueChargesPaid!.toStringAsFixed(2),
                            context: context,
                          ),
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 10, letterSpacing: 2),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          //if fee is paid with due charges
          if (feesData.dueChargesPaid != null &&
              feesData.dueChargesPaid != 0 &&
              feesData.isPaid)
            Row(
              children: [
                const Spacer(
                  flex: 10,
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 20),
                        child: setDivider(),
                      ),
                      Text(
                        UiUtils.formatAmount(
                          strVal: (feesData.amount! +
                                  (feesData.dueChargesPaid ?? 0))
                              .toStringAsFixed(2),
                          context: context,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (feesData.isDue &&
              feesData.dueChargesAmount != null &&
              feesData.dueChargesAmount != 0 &&
              !isCompulsoryDueRow &&
              !feesData.isPaid)
            Row(
              children: [
                const Spacer(
                  flex: 10,
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 20),
                        child: setDivider(),
                      ),
                      Text(
                        UiUtils.formatAmount(
                          strVal: (feesData.amount! +
                                  (feesData.dueChargesAmount ?? 0))
                              .toStringAsFixed(2),
                          context: context,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _onChanged(FeesData feesData) {
    if (context.read<FeesPaymentCubit>().state is! FeesPaymentFetchInProgress) {
      setState(() {
        if (_selectedTabTitle == compulsoryTitleKey) {
          if (installmentsChoices.contains(feesData.id)) {
            if (feesData.isDue) {
              totalCompulsoryFees = totalCompulsoryFees -
                  feesData.amount! -
                  (feesData.dueChargesAmount ?? 0);
            } else {
              totalCompulsoryFees -= feesData.amount!;
            }

            installmentsChoices.remove(feesData.id);
          } else {
            if (feesData.isDue) {
              totalCompulsoryFees = totalCompulsoryFees +
                  feesData.amount! +
                  (feesData.dueChargesAmount ?? 0);
            } else {
              totalCompulsoryFees += feesData.amount!;
            }
            installmentsChoices.add(feesData.id);
          }
          feesToBePaid = totalCompulsoryFees;
        } else {
          if (optionalChoices.contains(feesData.id)) {
            totalOptionalFees -= feesData.amount!;
            optionalChoices.remove(feesData.id);
          } else {
            totalOptionalFees += feesData.amount!;
            optionalChoices.add(feesData.id);
          }
          feesToBePaid = totalOptionalFees;
        }
      });
    }
  }

  Widget setDivider() {
    return Divider(
      thickness: 1.0,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  //returns the type of fee in int to be used for API calls
  int getTypeOfFee() {
    //0 = compulsory, 1 = installments, 2 = optional
    if (_selectedTabTitle == compulsoryTitleKey) {
      if (isPayAsInstallment) {
        return 1;
      } else {
        return 0;
      }
    } else {
      return 2;
    }
  }

  void payNowProcess(ChildFees childFees) {
    //assigning needed variables for payment process
    selectedFeesToBePaid = _getPaybleFees(childFees);
    if (_selectedTabTitle == compulsoryTitleKey) {
      if (isPayAsInstallment &&
          installmentsChoices.contains(childFees.installmentData.last.id)) {
        isCurrentlyBeingFullyPaid = true;
      } else if (!isPayAsInstallment) {
        isCurrentlyBeingFullyPaid = true;
      } else {
        isCurrentlyBeingFullyPaid = false;
      }
    } else {
      isCurrentlyBeingFullyPaid = false;
    }

    final availablePaymentOptions =
        <({int paymentMethodId, bool isEnabled, String paymentMethodTag})>[
      (
        paymentMethodId: 1,
        isEnabled: context
                .read<AppConfigurationCubit>()
                .getPaymentOptions()
                .razorpay !=
            null,
        paymentMethodTag: "razorpay"
      ),
      (
        paymentMethodId: 2,
        isEnabled:
            context.read<AppConfigurationCubit>().getPaymentOptions().stripe !=
                null,
        paymentMethodTag: "stripe"
      ),
      (
        paymentMethodId: 3,
        isEnabled: context
                .read<AppConfigurationCubit>()
                .getPaymentOptions()
                .paystack !=
            null,
        paymentMethodTag: "paystack"
      ),
      (
        paymentMethodId: 4,
        isEnabled: context
                .read<AppConfigurationCubit>()
                .getPaymentOptions()
                .flutterwave !=
            null,
        paymentMethodTag: "flutterwave"
      ),
    ];

    //if all options are off
    if (availablePaymentOptions.every((e) => !e.isEnabled)) {
      UiUtils.showCustomSnackBar(
          context: context,
          errorMessage:
              UiUtils.getTranslatedLabel(context, noPaymentOptionsAvlKey),
          backgroundColor: Theme.of(context).colorScheme.error,);
    }
    //if only one option is on
    else if (availablePaymentOptions
            .map((e) => e.isEnabled)
            .where((e) => e)
            .toList()
            .length ==
        1) {
      final int paymentMethod = availablePaymentOptions
          .firstWhere((element) => element.isEnabled)
          .paymentMethodId;
      final String chosenPayment = availablePaymentOptions
          .firstWhere((element) => element.isEnabled)
          .paymentMethodTag;
      setState(() {
        selectedPayment = chosenPayment;
      });
      context.read<FeesPaymentCubit>().addFeesTransaction(
          transactionAmount: feesToBePaid,
          childId: widget.isStudentPaying ? null : studentDetails.id,
          typeOfFee: getTypeOfFee(),
          isFullyPaid: isCurrentlyBeingFullyPaid ||
              allInstallmentsPaid ||
              isCompulsoryFullyPaid,
          paidDueCharges: dueChargesOnCompulsoryFees != 0.0 &&
                  isCurrentlyBeingFullyPaid &&
                  !isPayAsInstallment
              ? dueChargesOnCompulsoryFees
              : null,
          compulsoryAmountPaid:
              totalCompulsoryFees - dueChargesOnCompulsoryFees,
          dueChargesPaid: dueChargesOnCompulsoryFees,
          feesType: getTypeOfFee(),
          selectedFees: selectedFeesToBePaid,
          paymentMethod: paymentMethod,);
    } else {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return PaymentSelectionBottomSheet(
              enabledPayments:
                  context.read<AppConfigurationCubit>().getPaymentOptions(),);
        },
      ).then((chosenPayment) {
        if (chosenPayment != null) {
          setState(() {
            selectedPayment = chosenPayment;
          });
          int paymentMethod;
          //1- Razorpay , 2- Stripe , 3 -paystack 4- flutterwave
          switch (chosenPayment) {
            case "razorpay":
              paymentMethod = 1;
              break;
            case "stripe":
              paymentMethod = 2;
              break;
            case "paystack":
              paymentMethod = 3;
              break;
            case "flutterwave":
              paymentMethod = 4;
              break;
            default:
              paymentMethod = 1;
          }
          Future.delayed(
            Duration.zero,
            () {
              context.read<FeesPaymentCubit>().addFeesTransaction(
                  transactionAmount: feesToBePaid,
                  childId: widget.isStudentPaying ? null : studentDetails.id,
                  typeOfFee: getTypeOfFee(),
                  isFullyPaid: isCurrentlyBeingFullyPaid ||
                      allInstallmentsPaid ||
                      isCompulsoryFullyPaid,
                  paidDueCharges: dueChargesOnCompulsoryFees != 0.0 &&
                          isCurrentlyBeingFullyPaid &&
                          !isPayAsInstallment
                      ? dueChargesOnCompulsoryFees
                      : null,
                  compulsoryAmountPaid:
                      totalCompulsoryFees - dueChargesOnCompulsoryFees,
                  dueChargesPaid: dueChargesOnCompulsoryFees,
                  feesType: getTypeOfFee(),
                  selectedFees: selectedFeesToBePaid,
                  paymentMethod: paymentMethod,);
            },
          );
        }
      });
    }
  }

  Widget setPayNowBtn(ChildFees childFees) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 25,
      ),
      child: BlocConsumer<FeesPaymentCubit, FeesPaymentState>(
        listener: (context, state) {
          if (state is FeesPaymentFetchSuccess) {
            amount =
                double.parse(state.paymentGatewayDetails["amount"].toString());
            paymentTransactionId =
                state.paymentGatewayDetails["payment_transaction_id"];

            if ((selectedPayment == 'paystack' ||
                    selectedPayment == 'flutterwave') &&
                (context
                            .read<AppConfigurationCubit>()
                            .getPaymentOptions()
                            .paystack !=
                        null ||
                    context
                            .read<AppConfigurationCubit>()
                            .getPaymentOptions()
                            .flutterwave !=
                        null)) {
              final String paymentUrl = (selectedPayment == 'paystack')
                  ? state.paymentGatewayDetails["payment_gateway_response"]
                      ["data"]["authorization_url"]
                  : state.paymentGatewayDetails["id"].toString();

              Navigator.of(context).pushNamed(Routes.webViewPaymentScreen,
                  arguments: {"paymentURL": paymentUrl},).then((value) {
                if (value is bool) {
                  if (value) {
                    Navigator.of(context)
                        .pushReplacementNamed(Routes.paymentVerify, arguments: {
                      "studentDetails": studentDetails,
                      "orderId": orderId,
                      "transactionId": paymentTransactionId,
                      "status": 1,
                      "isStudentPaying": widget.isStudentPaying,
                    },);
                  } else {
                    Navigator.of(context)
                        .pushReplacementNamed(Routes.paymentVerify, arguments: {
                      "studentDetails": studentDetails,
                      "orderId": orderId,
                      "transactionId": paymentTransactionId,
                      "status": 0,
                      "isStudentPaying": widget.isStudentPaying,
                    },);
                  }
                }
              });
            }
            if (selectedPayment == "razorpay" &&
                context
                        .read<AppConfigurationCubit>()
                        .getPaymentOptions()
                        .razorpay !=
                    null) {
              orderId = state.paymentGatewayDetails["id"].toString();
            }
            if (selectedPayment == "stripe" &&
                context
                        .read<AppConfigurationCubit>()
                        .getPaymentOptions()
                        .stripe !=
                    null) {
              paymentIntentId = state.paymentGatewayDetails["id"];
              clientSecret =
                  state.paymentGatewayDetails["payment_gateway_response"]
                      ["client_secret"];
            }
            if (selectedPayment == "paystack" &&
                context
                        .read<AppConfigurationCubit>()
                        .getPaymentOptions()
                        .paystack !=
                    null) {
              paymentGatewayDetails = state.paymentGatewayDetails;
            }

            switch (selectedPayment) {
              case "razorpay":
                openCheckout(
                  amountToPay: double.parse(amount.toStringAsFixed(2)),
                  apiKey: context
                      .read<AppConfigurationCubit>()
                      .getPaymentOptions()
                      .razorpay!
                      .razorpayApiKey!,
                  orderId: orderId,
                  currencyCode: context
                      .read<AppConfigurationCubit>()
                      .getPaymentOptions()
                      .razorpay!
                      .currencyCode!
                      .toUpperCase(),
                  parentName: context
                      .read<AuthCubit>()
                      .getParentDetails()
                      .getFullName(),
                  parentMobile:
                      context.read<AuthCubit>().getParentDetails().mobile,
                  parentEmail:
                      context.read<AuthCubit>().getParentDetails().email,
                );
                break;
              case "stripe":
                paymentWithStripe(
                  amountToPay:
                      double.parse(amount.toStringAsFixed(2)).toString(),
                  clientSecret: clientSecret,
                  paymentIntentId: paymentIntentId,
                );
                break;
              default:
            }
          }
          if (state is FeesPaymentFetchFailure) {
            UiUtils.showCustomSnackBar(
                context: context,
                errorMessage: UiUtils.getErrorMessageFromErrorCode(
                    context, state.errorMessage,),
                backgroundColor: Theme.of(context).colorScheme.error,);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              if (pastTransactionPendingVisible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(
                      UiUtils.getTranslatedLabel(
                          context, feeTransactionPendingKey,),
                      textAlign: TextAlign.justify,
                      style: const TextStyle(fontSize: 11, color: redColor),),
                ),
              CustomRoundedButton(
                onTap: () {
                  if (feesToBePaid > 0) {
                    if (context
                            .read<StudentDetailedFeesCubit>()
                            .isTransactionPending() &&
                        !pastTransactionPendingVisible) {
                      pastTransactionPendingVisible = true;
                      setState(() {});
                    } else {
                      payNowProcess(childFees);
                    }
                  } else {
                    UiUtils.showCustomSnackBar(
                        context: context,
                        errorMessage: UiUtils.getTranslatedLabel(
                            context, selectFeesToPayKey,),
                        backgroundColor: Theme.of(context).colorScheme.error,);
                  }
                },
                widthPercentage: 0.7,
                height: 50,
                textAlign: TextAlign.center,
                backgroundColor: UiUtils.getColorScheme(context).primary,
                buttonTitle: UiUtils.getTranslatedLabel(context, payNowKey),
                titleColor: Theme.of(context).scaffoldBackgroundColor,
                showBorder: false,
                child: state is FeesPaymentFetchInProgress
                    ? const CustomCircularProgressIndicator(
                        strokeWidth: 2, widthAndHeight: 20,)
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDownloadReceiptButton() {
    return StudentDownloadFeePaidReceiptButton(studentDetails: studentDetails);
  }

  Widget listOfFees({required List<FeesData> fees}) {
    return Column(
      children: List.generate(
        fees.length,
        (index) => isCompulsoryDue &&
                fees[index].id == -1 &&
                isPayAsInstallment //hide due charges when paying in installments
            ? const SizedBox.shrink()
            : setRow(
                feesData: fees[index],
                isCheckboxRequired: _selectedTabTitle != compulsoryTitleKey ||
                    isCompulsoryFullyPaid,
                id: fees[index].id,
                isCompulsoryDueRow: fees[index].id == -1,
              ),
      ),
    );
  }

  Widget listOfInstallments({required List<FeesData> fees}) {
    return Column(
      children: List.generate(fees.length, (index) {
        return setRow(
          feesData: fees[index],
          isCheckboxRequired: true,
          isInstallment: true,
          isCheckboxSelectable: index > totalPaidInstallments &&
              (index == installmentsChoices.length + totalPaidInstallments ||
                  index ==
                      installmentsChoices.length + totalPaidInstallments - 1),
          id: fees[index].id,
        );
      }),
    );
  }

  Widget _buildInstallmentsContainer({required ChildFees childFees}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 8),
          child: Row(
            children: [
              const Spacer(),
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 15),
                  child: Text(
                    UiUtils.getTranslatedLabel(context, payInInstallmentsKey),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Switch(
                    value: isPayAsInstallment,
                    onChanged: totalPaidInstallments != 0
                        ? (value) {}
                        : (value) {
                            if (context.read<FeesPaymentCubit>().state
                                is! FeesPaymentFetchInProgress) {
                              setState(() {
                                isPayAsInstallment = value;
                                if (!isPayAsInstallment) {
                                  feesToBePaid = childFees.compulsoryFeesTotal +
                                      dueChargesOnCompulsoryFees;
                                  totalCompulsoryFees = feesToBePaid;
                                } else {
                                  installmentsChoices.clear();
                                  if (childFees
                                      .installmentData[totalPaidInstallments]
                                      .isDue) {
                                    totalCompulsoryFees = childFees
                                            .installmentData[
                                                totalPaidInstallments]
                                            .amount! +
                                        (childFees
                                                .installmentData[
                                                    totalPaidInstallments]
                                                .dueChargesAmount ??
                                            0);
                                  } else {
                                    totalCompulsoryFees = childFees
                                        .installmentData[totalPaidInstallments]
                                        .amount!;
                                  }
                                  installmentsChoices.add(
                                    childFees
                                        .installmentData[totalPaidInstallments]
                                        .id,
                                  );
                                  feesToBePaid = totalCompulsoryFees;
                                }
                              });
                            }
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isPayAsInstallment)
          listOfInstallments(
            fees: childFees.installmentData,
          ),
      ],
    );
  }

  Widget _buildDetailsContainer({required ChildFees childFees}) {
    final bool allFeesPaid = _selectedTabTitle == compulsoryTitleKey
        ? (allInstallmentsPaid || isCompulsoryFullyPaid)
        : allOptionalPaid;
    final bool thereAreNoFees = _selectedTabTitle == compulsoryTitleKey
        ? childFees.compulsoryFeesData.isEmpty
        : childFees.optionalFeesData.isEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * (0.075),
      ),
      child: Column(
        children: [
          thereAreNoFees
              ? const NoDataContainer(titleKey: noFeesFoundForThisClassKey)
              : listOfFees(
                  fees: _selectedTabTitle == compulsoryTitleKey
                      ? childFees.compulsoryFeesData
                      : childFees.optionalFeesData,
                ),
          if (_selectedTabTitle == compulsoryTitleKey &&
              isInstallmentAvailable &&
              !isCompulsoryFullyPaid &&
              !thereAreNoFees)
            _buildInstallmentsContainer(childFees: childFees),
          if (!thereAreNoFees) setDivider(),
          if (!thereAreNoFees)
            setRow(
              //set total text with formatted amount based on Selection
              feesData: FeesData(
                id: 0,
                name: "Total",
                amount: feesToBePaid,
              ),
              isCheckboxRequired: false,
              id: 0,
            ),
          if (!(allFeesPaid || thereAreNoFees)) setPayNowBtn(childFees),
          if (((isPayAsInstallment && totalPaidInstallments > 0) ||
                  isCompulsoryFullyPaid) &&
              widget.isStudentPaying &&
              !thereAreNoFees)
            //no padding required if pay now button is showing
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: (!(allFeesPaid || thereAreNoFees)) ? 0 : 25,
              ),
              child: _buildDownloadReceiptButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * (0.075),
      ),
      child: ShimmerLoadingContainer(
        child: LayoutBuilder(
          builder: (context, boxConstraints) {
            return Column(
              children: [
                SizedBox(
                  height: 250,
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: UiUtils.defaultShimmerLoadingContentCount,
                    itemBuilder: (context, index) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: ShimmerLoadingContainer(
                          child: CustomShimmerContainer(
                            height: 20,
                            borderRadius: 0,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                CustomShimmerContainer(
                  margin: const EdgeInsets.all(20),
                  height: boxConstraints.maxWidth * (0.18),
                  width: boxConstraints.maxWidth * (0.4),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingContainer() {
    return Align(
      child: _buildShimmerLoader(),
    );
  }

  Widget detailedFeesContainer() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: UiUtils.getScrollViewBottomPadding(context),
        top: UiUtils.getScrollViewTopPadding(
          context: context,
          appBarHeightPercentage: UiUtils.appBarBiggerHeightPercentage,
        ),
      ),
      child: BlocBuilder<StudentDetailedFeesCubit, StudentDetailedFeesState>(
        builder: (context, state) {
          if (state is StudentDetailedFeesFetchSuccess) {
            return Align(
              child: _buildDetailsContainer(childFees: state.childFees),
            );
          }
          if (state is StudentDetailedFeesFetchFailure) {
            return Center(
              child: ErrorContainer(
                errorMessageCode: state.errorMessage,
                onTapRetry: () {
                  fetchDetailedFees();
                },
              ),
            );
          }
          return _buildLoadingContainer();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StudentDetailedFeesCubit, StudentDetailedFeesState>(
      listener: (context, state) {
        /*
         if fees data is fetched, this listener will setup all the initial values properly to be shown to the user
         there are different cases handled by these values set, like which fee is paid and not paid
         if it's an installment payment how many installments are already paid, if 2 and 3rd is remaining auto-select it because user will have no choice but to pay it
         if all optional fees are paid, show total as total optional fees and don't show pay now button
         if all compulsory fees or installments are paid show it's total and not the pay now button
         and there are many more conditions to make different type of UI with different types of data
        */
        if (state is StudentDetailedFeesFetchSuccess) {
          if (!state.childFees.optionalFeesData
              .any((element) => element.isPaid == false)) {
            allOptionalPaid = true;
          }

          if (!state.childFees.compulsoryFeesData
              .any((element) => element.isPaid == false)) {
            isCompulsoryFullyPaid = true;
          }
          //calculating dueCharges on compulsory fees if applicable
          if (state.childFees.compulsoryFeesDueDate != null &&
              state.childFees.compulsoryFeesDueCharges != null &&
              !isCompulsoryFullyPaid) {
            if (state.childFees.compulsoryFeesDueDate!
                    .isBefore(state.childFees.currentDate) &&
                state.childFees.compulsoryFeesDueCharges! != 0) {
              isCompulsoryDue = true;
              dueChargesOnCompulsoryFees = state.childFees.compulsoryFeesTotal *
                  state.childFees.compulsoryFeesDueCharges! /
                  100;
              state.childFees.compulsoryFeesData.add(
                FeesData(
                  id: -1,
                  name: "Due Charges",
                  isDue: true,
                  dueChargesInPercentage:
                      state.childFees.compulsoryFeesDueCharges,
                  dueDate: state.childFees.compulsoryFeesDueDate,
                  amount: dueChargesOnCompulsoryFees,
                ),
              );
            }
          }

          isInstallmentAvailable = state.childFees.installmentData.isNotEmpty;
          if (isInstallmentAvailable) {
            //calculating amount of each installment using the total amount
            final installmentAmount = state.childFees.compulsoryFeesTotal /
                state.childFees.installmentData.length;
            for (int i = 0; i < state.childFees.installmentData.length; i++) {
              state.childFees.installmentData[i].amount = installmentAmount;
              if (state.childFees.installmentData[i].isPaid) {
                totalPaidInstallments += 1;
                isPayAsInstallment = true;
              }
              try {
                state.childFees.installmentData[i].dueChargesAmount =
                    (installmentAmount *
                            state.childFees.installmentData[i]
                                .dueChargesInPercentage!) /
                        100;
              } catch (_) {
                //
              }
            }

            if (totalPaidInstallments != 0 &&
                totalPaidInstallments <
                    state.childFees.installmentData.length) {
              //it's not compulsory if even a single installment is paid
              isCompulsoryFullyPaid = false;
              //choosing initial installment if not fully paid
              installmentsChoices.clear();
              installmentsChoices.add(
                state.childFees.installmentData[totalPaidInstallments].id,
              );
              if (state
                  .childFees.installmentData[totalPaidInstallments].isDue) {
                totalCompulsoryFees = totalCompulsoryFees +
                    state.childFees.installmentData[totalPaidInstallments]
                        .amount! +
                    (state.childFees.installmentData[totalPaidInstallments]
                            .dueChargesAmount ??
                        0);
              } else {
                totalCompulsoryFees += state
                    .childFees.installmentData[totalPaidInstallments].amount!;
              }

              feesToBePaid = totalCompulsoryFees;
            }
          }
          //if all installments are paid
          if (isInstallmentAvailable &&
              totalPaidInstallments == state.childFees.installmentData.length) {
            allInstallmentsPaid = true;
            isCompulsoryFullyPaid = false;
            totalCompulsoryFees = state.childFees.installmentData.fold<double>(
              0,
              (previousValue, element) =>
                  previousValue +
                  (element.amount ?? 0) +
                  (element.dueChargesPaid ?? 0),
            );
            feesToBePaid = totalCompulsoryFees;
          } else if (isCompulsoryFullyPaid) {
            //if not a single installment is paid and compulsory fully paid
            totalCompulsoryFees =
                state.childFees.compulsoryFeesData.fold<double>(
              0,
              (previousValue, element) => previousValue + (element.amount ?? 0),
            );
          } else if (!isPayAsInstallment) {
            //if not compulsory fully paid and not installment payment
            totalCompulsoryFees = state.childFees.compulsoryFeesTotal +
                dueChargesOnCompulsoryFees;
          }
          if (allOptionalPaid) {
            //if all optional paid, make total it's total, else let the user select
            totalOptionalFees = state.childFees.optionalFeesTotal;
          }
          //check the current tab and make total visible (feesToBePaid) accordingly
          if (_selectedTabTitle == compulsoryTitleKey && !isPayAsInstallment) {
            feesToBePaid = totalCompulsoryFees;
          } else if (_selectedTabTitle == optionalTitleKey) {
            feesToBePaid = totalOptionalFees;
          }
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, dynamic result) {
          if (context.read<FeesPaymentCubit>().state
              is! FeesPaymentFetchInProgress) {
            if (didPop) {
              return;
            }
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              detailedFeesContainer(),
              _buildAppBar(),
            ],
          ),
        ),
      ),
    );
  }

  ///payments

  //Razorpay
  Future<void> openCheckout(
      {required double amountToPay,
      required String currencyCode,
      required String apiKey,
      required String orderId,
      required String parentName,
      required String parentMobile,
      required String parentEmail,}) async {
    final options = {
      'key': apiKey,
      'amount': amountToPay,
      'order_id': orderId,
      'name': parentName,
      'currency': currencyCode,
      'prefill': {'contact': parentMobile, 'email': parentEmail},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: e');
    }
  }

  //storing selected fees details to send to api either optional or installments
  late List<FeesData> selectedFeesToBePaid;
  bool isCurrentlyBeingFullyPaid = false;

  List<FeesData> _getPaybleFees(ChildFees childFees) {
    final int feesType =
        getTypeOfFee(); //0 = compulsory, 1 = installments, 2 = optional
    final List<FeesData> temp = [];
    if (feesType == 1) {
      for (int i = 0; i < childFees.installmentData.length; i++) {
        if (installmentsChoices.contains(childFees.installmentData[i].id)) {
          temp.add(childFees.installmentData[i]);
        }
      }
    } else if (feesType == 2) {
      for (int i = 0; i < childFees.optionalFeesData.length; i++) {
        if (optionalChoices.contains(childFees.optionalFeesData[i].id)) {
          temp.add(childFees.optionalFeesData[i]);
        }
      }
    }
    return temp;
  }

  ///Razorpay
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Navigator.of(context).pushReplacementNamed(
      Routes.paymentVerify,
      arguments: {
        "studentDetails": studentDetails,
        "orderId": orderId,
        "transactionId": paymentTransactionId,
        "paymentSignature": response.signature,
        "paymentId": response.paymentId,
        "status": 1,
        "isStudentPaying": widget.isStudentPaying,
      },
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Navigator.of(context).pushReplacementNamed(
      Routes.paymentVerify,
      arguments: {
        "studentDetails": studentDetails,
        "orderId": orderId,
        "transactionId": paymentTransactionId,
        "status": 0,
        "isStudentPaying": widget.isStudentPaying,
      },
    );
  }

//stripe
  Future<void> paymentWithStripe(
      {required String amountToPay,
      required String clientSecret,
      required String paymentIntentId,}) async {
    try {
      await StripeService.payWithPaymentSheet(
        merchantDisplayName: context
            .read<AppConfigurationCubit>()
            .getAppConfiguration()
            .schoolName,
        amount: amountToPay,
        currency: context
            .read<AppConfigurationCubit>()
            .getPaymentOptions()
            .stripe!
            .currencyCode!,
        clientSecret: clientSecret,
        paymentIntentId: paymentIntentId,
      );

      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(
          Routes.paymentVerify,
          arguments: {
            "studentDetails": studentDetails,
            "transactionId": paymentTransactionId,
            "paymentIntentId": paymentIntentId,
            "isStudentPaying": widget.isStudentPaying,
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(
          Routes.paymentVerify,
          arguments: {
            "studentDetails": studentDetails,
            "transactionId": paymentTransactionId,
            "paymentIntentId": paymentIntentId,
            "isStudentPaying": widget.isStudentPaying,
          },
        );
      }
    }
  }
}
