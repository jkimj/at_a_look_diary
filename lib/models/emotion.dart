import 'package:flutter/material.dart';

class Emotion {
  final String id;
  final String name;
  final String color;
  final String iconUrl;

  Emotion({
    required this.id,
    required this.name,
    required this.color,
    required this.iconUrl,
  });

  factory Emotion.fromJson(String id, Map<String, dynamic> json) {
    return Emotion(
      id: id,
      name: json['name'] ?? '',
      color: json['color'] ?? '#000000',
      iconUrl: json['iconUrl'] ?? '',
    );
  }

  Color getColor() {
    return Color(int.parse(color.replaceFirst('#', '0xFF')));
  }
}

// 기본 감정 리스트 (Firebase 초기화 전 사용)
class EmotionData {
  static final List<Map<String, String>> defaultEmotions = [
    {
      'id': 'joy',
      'name': '기쁨',
      'color': '#FFEB3B',
      'icon': '😊',
    },
    {
      'id': 'angry',
      'name': '화남',
      'color': '#F44336',
      'icon': '😠',
    },
    {
      'id': 'sad',
      'name': '슬픔',
      'color': '#2196F3',
      'icon': '😢',
    },
    {
      'id': 'annoyed',
      'name': '짜증',
      'color': '#4CAF50',
      'icon': '😤',
    },
    {
      'id': 'excited',
      'name': '설렘',
      'color': '#E91E63',
      'icon': '🥰',
    },
  ];
}
