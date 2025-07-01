class AssignmentList {
  late final int? currentPage;
  late final List<AssignmentData>? data;
  late final int? from;
  late final int? lastPage;
  late final int? perPage;
  late final int? to;
  late final int? total;

  AssignmentList({
    required this.currentPage,
    required this.data,
    required this.from,
    required this.lastPage,
    required this.perPage,
    required this.to,
    required this.total,
  });

  AssignmentList.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'];
    if (json['data'] != null) {
      data = <AssignmentData>[];
      json['data'].forEach((v) {
        data!.add(AssignmentData.fromJson(v));
      });
    }
    from = json['from'];
    lastPage = json['last_page'];
    perPage = json['per_page'];
    to = json['to'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['from'] = from;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['to'] = to;
    data['total'] = total;
    return data;
  }
}

class AssignmentData {
  late final int? assignmentId;
  late final String? assignmentName;
  late final int? obtainedPoints;
  late final int? totalPoints;

  AssignmentData({
    required this.assignmentId,
    required this.assignmentName,
    required this.obtainedPoints,
    required this.totalPoints,
  });

  AssignmentData.fromJson(Map<String, dynamic> json) {
    assignmentId = json['assignment_id'];
    assignmentName = json['assignment_name'];
    obtainedPoints = json['obtained_points'];
    totalPoints = json['total_points'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['assignment_id'] = assignmentId;
    data['assignment_name'] = assignmentName;
    data['obtained_points'] = obtainedPoints;
    data['total_points'] = totalPoints;
    return data;
  }
}
