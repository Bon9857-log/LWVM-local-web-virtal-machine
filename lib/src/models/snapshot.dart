import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'snapshot.freezed.dart';
part 'snapshot.g.dart';

@freezed
class Snapshot with _$Snapshot {
  const factory Snapshot({
    required String id,
    required String name,
    required DateTime timestamp,
    @Default('') String description,
  }) = _Snapshot;

  factory Snapshot.fromJson(Map<String, dynamic> json) => _$SnapshotFromJson(json);

  factory Snapshot.fromQemuLine(String line) {
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 2) return Snapshot(id: '', name: '', timestamp: DateTime.now());
    return Snapshot(
      id: parts.first,
      name: parts.length > 2 ? parts[2] : parts.first,
      timestamp: DateTime.now(),
      description: parts.length > 2 ? parts[2] : '',
    );
  }

  factory Snapshot.fromJsonString(String json) {
    final Map<String, dynamic> map = jsonDecode(json) as Map<String, dynamic>;
    return Snapshot(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp'] as String) 
          : DateTime.now(),
      description: map['description'] as String? ?? '',
    );
  }
}