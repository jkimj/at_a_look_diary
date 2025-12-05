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
      'color': '#FFF9C4', // 파스텔 옐로우
      'icon': '😊',
    },
    {
      'id': 'love',
      'name': '사랑',
      'color': '#FFE0E6', // 파스텔 핑크
      'icon': '🥰',
    },
    {
      'id': 'excited',
      'name': '설렘',
      'color': '#E1BEE7', // 파스텔 퍼플
      'icon': '💜',
    },
    {
      'id': 'peace',
      'name': '평온',
      'color': '#B2DFDB', // 파스텔 민트
      'icon': '😌',
    },
    {
      'id': 'sad',
      'name': '슬픔',
      'color': '#BBDEFB', // 파스텔 블루
      'icon': '😢',
    },
    {
      'id': 'tired',
      'name': '피곤',
      'color': '#D7CCC8', // 파스텔 베이지
      'icon': '😴',
    },
    {
      'id': 'annoyed',
      'name': '짜증',
      'color': '#FFCCBC', // 파스텔 오렌지
      'icon': '😤',
    },
    {
      'id': 'angry',
      'name': '화남',
      'color': '#FFCDD2', // 파스텔 레드
      'icon': '😠',
    },
  ];
}