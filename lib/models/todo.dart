import 'package:flutter/material.dart';

class Todo {
  String title;
  DateTime dateTime;

  Todo({
    required this.title,
    required this.dateTime,
  });

  // Método para converter JSON em um objeto Todo
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      title: json['title'],
      dateTime: DateTime.parse(json['dateTime']),
    );
  }

  // Método para converter um objeto Todo em JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'dateTime': dateTime.toIso8601String(),
    };
  }
}
