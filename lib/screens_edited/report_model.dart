class ReportModel {
  // Placeholder model for report data
  final String? id;
  final String? type;
  final String? roomId;
  final int? points;

  ReportModel({this.id, this.type, this.roomId, this.points});

  // Add serialization if needed
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'roomId': roomId,
        'points': points,
      };

  static ReportModel fromJson(Map<String, dynamic> json) => ReportModel(
        id: json['id'] as String?,
        type: json['type'] as String?,
        roomId: json['roomId'] as String?,
        points: json['points'] as int?,
      );
}
