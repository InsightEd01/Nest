import 'dart:convert';
import 'package:eschool/data/models/feesTransaction.dart';
import 'package:eschool/data/models/customNotification.dart';
import 'package:eschool/data/models/sessionYear.dart';
import 'package:eschool/data/models/attendanceDay.dart';
import 'package:eschool/data/models/coreSubject.dart';
import 'package:eschool/data/models/electiveSubject.dart';
import 'package:eschool/data/models/exam.dart';
import 'package:eschool/data/models/fees.dart';
import 'package:eschool/data/models/paidFees.dart';
import 'package:eschool/data/models/parent.dart';
import 'package:eschool/data/models/result.dart';
import 'package:eschool/data/models/timeTableSlot.dart';
import 'package:eschool/utils/stripeService.dart';
import 'package:eschool/utils/api.dart';
import 'package:eschool/utils/errorMessageKeysAndCodes.dart';
import 'package:eschool/utils/hiveBoxKeys.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StudentRepository {
  //get all dashboard data for students
  Future<Map<String, dynamic>> fetchStudentDashboard() async {
    return (await Api.get(
        url: Api.studentDashboard, useAuthToken: true,))['data'];
  }

  //LocalDataSource
  Future<void> setLocalCoreSubjects(List<CoreSubject> subjects) async {
    final box = Hive.box(studentSubjectsBoxKey);
    final List<Map<String, dynamic>> jsonSubjects =
        subjects.map((e) => e.toJson()).toList();

    box.put(coreSubjectsHiveKey, jsonSubjects);
  }

  Future<void> setLocalElectiveSubjects(List<ElectiveSubject> subjects) async {
    final box = Hive.box(studentSubjectsBoxKey);
    final List<Map<String, dynamic>> jsonSubjects =
        subjects.map((e) => e.toJson()).toList();

    box.put(electiveSubjectsHiveKey, jsonSubjects);
  }

  List<CoreSubject> getLocalCoreSubjects() {
    final coreSubjects =
        (Hive.box(studentSubjectsBoxKey).get(coreSubjectsHiveKey) ?? [])
            as List;

    return coreSubjects
        .map((e) => CoreSubject.fromJson(json: Map.from(e)))
        .toList();
  }

  List<ElectiveSubject> getLocalElectiveSubjects() {
    final electiveSubjects =
        (Hive.box(studentSubjectsBoxKey).get(electiveSubjectsHiveKey) ?? [])
            as List;

    return electiveSubjects
        .map(
          (e) => ElectiveSubject.fromJson(
            electiveSubjectGroupId: 0,
            json: Map.from(e),
          ),
        )
        .toList();
  }

  //currently this is unused as we're getting it in dashboard API anyways
  Future<Map<String, dynamic>> fetchSubjects() async {
    try {
      final result =
          await Api.get(url: Api.studentSubjects, useAuthToken: true);

      final coreSubjects = (result['data']['core_subject'] as List)
          .map((e) => CoreSubject.fromJson(json: Map.from(e ?? {})))
          .toList();

      //If class have any elective subjects then of key of elective subject will be there
      //if elective subject key has empty list means student has not sleeted any
      //elective subjects

      //If there is not elective subjects key in result means no elective subjects
      //in given class
      final electiveSubjects =
          ((result['data']['elective_subject'] ?? []) as List)
              .map(
                (e) => ElectiveSubject.fromJson(
                  electiveSubjectGroupId: 0,
                  json: Map.from(e['subject']),
                ),
              )
              .toList();

      return {
        "coreSubjects": coreSubjects,
        "electiveSubjects": electiveSubjects,
        "doesClassHaveElectiveSubjects":
            result['data']['elective_subject'] != null,
      };
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> selectElectiveSubjects({
    required Map<int, List<int>> electedSubjectGroups,
  }) async {
    try {
      final electedSubjectGroupIds = electedSubjectGroups.keys
          .map((key) => {"id": key, "subject_id": electedSubjectGroups[key]})
          .toList();

      final body = {"subject_group": electedSubjectGroupIds};
      await Api.post(
        url: Api.selectStudentElectiveSubjects,
        useAuthToken: true,
        body: body,
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchParentDetails() async {
    try {
      final result = await Api.get(
        url: Api.parentDetailsOfStudent,
        useAuthToken: true,
      );

      return {
        "mother": result['data']['mother'] != null &&
                result['data']['mother'].isNotEmpty
            ? Parent.fromJson(Map.from(result['data']['mother']))
            : null,
        "father": result['data']['father'] != null &&
                result['data']['father'].isNotEmpty
            ? Parent.fromJson(Map.from(result['data']['father']))
            : null,
        "guardian": result['data']['guardian'] != null &&
                result['data']['guardian'].isNotEmpty
            ? Parent.fromJson(Map.from(result['data']['guardian']))
            : null,
      };
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<TimeTableSlot>> fetchTimeTable({
    required bool useParentApi,
    required int childId,
  }) async {
    try {
      final result = await Api.get(
        url:
            useParentApi ? Api.getStudentTimetableParent : Api.studentTimeTable,
        useAuthToken: true,
        queryParameters: useParentApi ? {"child_id": childId} : null,
      );

      return (result['data'] as List)
          .map((e) => TimeTableSlot.fromJson(Map.from(e)))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchExamResults({
    int? page,
    required bool useParentApi,
    required int childId,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {"page": page ?? 0};
      if (queryParameters['page'] == 0) {
        queryParameters.remove('page');
      }
      if (useParentApi) {
        queryParameters.addAll({"child_id": childId});
      }
      final result = await Api.get(
        url: useParentApi ? Api.getStudentResultsParent : Api.studentResults,
        useAuthToken: true,
        queryParameters: queryParameters,
      );

      return {
        "results": ((result['data'] ?? []) as List)
            .map((result) => Result.fromJson(Map.from(result)))
            .toList(),
      };
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchAttendance({
    required int month,
    required int year,
    required bool useParentApi,
    required int childId,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        "month": month,
        "year": year,
      };

      if (useParentApi) {
        queryParameters.addAll({"child_id": childId});
      }

      final result = await Api.get(
        url: useParentApi
            ? Api.getStudentAttendanceParent
            : Api.getStudentAttendance,
        queryParameters: queryParameters,
        useAuthToken: true,
      );

      return {
        "attendanceDays": (result['data']['attendance'] as List)
            .map((attendance) => AttendanceDay.fromJson(Map.from(attendance)))
            .toList(),
        "sessionYear":
            SessionYear.fromJson(Map.from(result['data']['session_year'] ?? {})),
      };
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  //
  //This method is used to fetch exams list
  Future<List<Exam>> fetchExamsList({
    required bool useParentApi,
    required int childId,
    required int examStatus,
    bool getTimetable = false,
  }) async {
    try {
      final result = await Api.get(
        url: useParentApi ? Api.getStudentExamListParent : Api.studentExamList,
        useAuthToken: true,
        queryParameters: useParentApi
            ? {
                "child_id": childId,
                'status': examStatus,
                if (getTimetable) "get_timetable": "1",
              }
            : {'status': examStatus, if (getTimetable) "get_timetable": "1"},
      );

      return (result['data'] as List)
          .map((e) => Exam.fromExamJson(Map.from(e)))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  //
  //This method is used to fetch time-table of particular exam
  Future<List<ExamTimeTable>> fetchExamTimeTable({
    required bool useParentApi,
    required int childId,
    required int examId,
  }) async {
    try {
      final result = await Api.get(
        url: useParentApi
            ? Api.getStudentExamDetailsParent
            : Api.studentExamDetails,
        useAuthToken: true,
        queryParameters: useParentApi
            ? {"child_id": childId, "exam_id": examId}
            : {"exam_id": examId},
      );

      return (result['data'] as List)
          .map((e) => ExamTimeTable.fromJson(Map.from(e)))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<PaidFees>> fetchFeesList({required int childId}) async {
    try {
      final result = await Api.get(
        url: Api.getPaidFeesListParent,
        useAuthToken: true,
        queryParameters: {
          "child_id": childId,
        },
      );

      return (result['data'] as List)
          .map((e) => PaidFees.fromJson(Map.from(e)))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Uint8List> downloadFeesReceipt({
    int? feesPaidId,
  }) async {
    //if feesPaidId id is not provided, it assumes that the student/child himself is download receipt
    try {
      final result = await Api.get(
        url: feesPaidId == null
            ? Api.downloadFeesPaidReceiptStudent
            : Api.downloadFeesPaidReceiptParent,
        useAuthToken: true,
        queryParameters: {
          if (feesPaidId != null) "fees_paid_id": feesPaidId,
        },
      );
      return base64Decode(result['pdf']);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<ChildFees> fetchDetailedFees({int? childId}) async {
    try {
      //if child id is not provided, it assumes that the student/child himself is paying the fees
      final result = await Api.get(
        url: childId == null
            ? Api.getStudentFeesDetailStudent
            : Api.getStudentFeesDetailParent,
        useAuthToken: true,
        queryParameters: {
          if (childId != null) "child_id": childId,
        },
      );
      return ChildFees.fromJson(result);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map> addFeesTransaction(
      {required double transactionAmount,
      int? childId,
      required int typeOfFee,
      required bool isFullyPaid,
      required double? paidDueCharges,
      double? compulsoryAmountPaid,
      double? dueChargesPaid,
      required int feesType, //0 = compulsory, 1 = installments, 2 = optional
      required List<FeesData> selectedFees,
      required int paymentMethod,}) async {
    try {
      final body = {
        if (childId != null) "child_id": childId,
        "amount": transactionAmount.toStringAsFixed(2),
        "type_of_fee": typeOfFee,
        "is_fully_paid": isFullyPaid ? "1" : "0",
        "payment_method": paymentMethod,
        if (feesType == 0 && paidDueCharges != null)
          "due_charges": paidDueCharges.toStringAsFixed(2),
        if (feesType == 1)
          "installment_data": selectedFees
              .map(
                (e) => {
                  "id": e.id,
                  "name": e.name,
                  "amount": e.amount!.toStringAsFixed(2),
                  if (e.isDue && e.dueChargesAmount != null)
                    "due_charges": e.dueChargesAmount!.toStringAsFixed(2),
                },
              )
              .toList(),
        if (feesType == 2)
          "optional_fees_data": selectedFees
              .map(
                (e) => {
                  "id": e.id,
                  "amount": e.amount!.toStringAsFixed(2),
                },
              )
              .toList(),
      };
      //if child id is not provided, it assumes that the student/child himself is paying the fees
      final result = await Api.post(
        body: body,
        url: childId == null
            ? Api.addFeesTransactionStudent
            : Api.addFeesTransaction,
        useAuthToken: true,
      );
      return result["payment_gateway_details"];
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> storeFees({
    required String transactionId,
    int? childId,
    String? paymentId,
    String? paymentSignature,
  }) async {
    try {
      //if child id is not provided, it assumes that the student/child himself is paying the fees
      await Api.post(
        url: childId == null ? Api.storeFeesStudent : Api.storeFeesParent,
        useAuthToken: true,
        body: {
          "transaction_id": transactionId,
          if (childId != null) "child_id": childId,
          if (paymentId != null) "payment_id": paymentId,
          if (paymentSignature != null) "payment_signature": paymentSignature,
        },
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> failPaymentTransaction({
    required String transactionId,
    required bool isStudentPayingFees,
  }) async {
    try {
      await Api.post(
        url: isStudentPayingFees
            ? Api.failPaymentTransactionStudent
            : Api.failPaymentTransaction,
        body: {
          "payment_transaction_id": transactionId,
        },
        useAuthToken: true,
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>> fetchFeesTransactions({
    required int page,
    required bool isStudentLoggedIn,
  }) async {
    try {
      final response = await Api.get(
        url: isStudentLoggedIn
            ? Api.getFeesTransactionsStudent
            : Api.getFeesTransactions,
        useAuthToken: true,
        queryParameters: {"page": page},
      );

      final List<FeesTransaction> fetchedTransactions = [];

      for (int i = 0; i < response['data']['transaction-data'].length; i++) {
        fetchedTransactions.add(
          FeesTransaction.fromJson(
            response['data']['transaction-data'][i],
          ),
        );
      }

      return {
        "feesTransactions": fetchedTransactions,
        "currentPage": response['data']['current_page'],
        "totalPage": response['data']['last_page'],
      };
    } catch (error) {
      throw ApiException(error.toString());
    }
  }

  Future<String> confirmStripePayment({
    required String paymentIntentId,
    required bool isStudentLoggedIn,
  }) async {
    try {
      final response = await Api.post(
        url: isStudentLoggedIn
            ? Api.verifyStripePaymentStudent
            : Api.verifyStripePayment,
        useAuthToken: true,
        body: {"payment_intent_id": paymentIntentId},
      );
      final statusOfTransaction = (response['data'] ?? "").toString();
      return statusOfTransaction;
    } on PlatformException catch (err) {
      throw ApiException(
        StripeService.getPlatformExceptionErrorResult(err).message ??
            ErrorMessageKeysAndCode.defaultErrorMessageCode,
      );
    } catch (error) {
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageCode);
    }
  }

  //get custom notifications for student
  Future<Map<String, dynamic>> fetchNotifications({required int page}) async {
    try {
      final response = await Api.get(
        url: Api.getStudentNotifications,
        useAuthToken: true,
        queryParameters: {"page": page},
      );

      final List<CustomNotification> notifications = [];

      for (int i = 0; i < response['data']['data'].length; i++) {
        notifications.add(
          CustomNotification.fromJson(
            response['data']['data'][i],
          ),
        );
      }

      return {
        "notifications": notifications,
        "currentPage": response['data']['current_page'],
        "totalPage": response['data']['last_page'],
      };
    } catch (error) {
      throw ApiException(error.toString());
    }
  }

  //to send notification to parents/guardians to pay fees
  Future<void> askParentsToPayFees() async {
    try {
      await Api.get(
        url: Api.askParentsToPayFees,
        useAuthToken: true,
      );
    } catch (error) {
      throw ApiException(error.toString());
    }
  }
}
