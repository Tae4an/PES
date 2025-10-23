// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disaster_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisasterModel _$DisasterModelFromJson(Map<String, dynamic> json) =>
    DisasterModel(
      serialNumber: (json['serial_number'] as num).toInt(),
      date: json['date'] as String,
      time: json['time'] as String,
      category: json['category'] as String,
      message: json['message'] as String,
      issuedAt: json['issued_at'] as String,
    );

Map<String, dynamic> _$DisasterModelToJson(DisasterModel instance) =>
    <String, dynamic>{
      'serial_number': instance.serialNumber,
      'date': instance.date,
      'time': instance.time,
      'category': instance.category,
      'message': instance.message,
      'issued_at': instance.issuedAt,
    };
