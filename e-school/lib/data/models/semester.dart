class Semester {
  String id;
  String? name;
  String startMonthName;
  String endMonthName;

  Semester({
    required this.id,
    required this.name,
    required this.startMonthName,
    required this.endMonthName,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
      startMonthName: json['start_month_name']?.toString() ?? '',
      endMonthName: json['end_month_name']?.toString() ?? '',
    );
  }
}
