import 'package:equatable/equatable.dart';

/// ─────────────────────────────────────────────
/// Domain Entities
/// ─────────────────────────────────────────────

class User extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final int xp;
  final int coins;
  final int streakDays;
  final int hearts;
  final int maxHearts;
  final bool isNewUser;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.xp = 0,
    this.coins = 0,
    this.streakDays = 0,
    this.hearts = 5,
    this.maxHearts = 5,
    this.isNewUser = false,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, email];

  User copyWith({
    int? id, String? name, String? email, String? phone,
    String? avatar, int? xp, int? coins, int? streakDays,
    int? hearts, int? maxHearts, bool? isNewUser,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      streakDays: streakDays ?? this.streakDays,
      hearts: hearts ?? this.hearts,
      maxHearts: maxHearts ?? this.maxHearts,
      isNewUser: isNewUser ?? this.isNewUser,
      createdAt: createdAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      xp: json['xp'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      streakDays: json['streak_days'] as int? ?? 0,
      hearts: json['hearts'] as int? ?? 5,
      maxHearts: json['max_hearts'] as int? ?? 5,
      isNewUser: json['is_new_user'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'avatar': avatar,
    'xp': xp,
    'coins': coins,
    'streak_days': streakDays,
    'hearts': hearts,
    'max_hearts': maxHearts,
    'is_new_user': isNewUser,
  };
}

/// Auth token pair
class AuthTokens extends Equatable {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn = 3600,
  });

  @override
  List<Object?> get props => [accessToken];

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: json['expires_in'] as int? ?? 3600,
    );
  }
}

/// Exam type entity
class ExamType extends Equatable {
  final int id;
  final String name;
  final String code;
  final String? description;
  final bool isPrimary;

  const ExamType({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.isPrimary = false,
  });

  @override
  List<Object?> get props => [id, code];

  factory ExamType.fromJson(Map<String, dynamic> json) {
    return ExamType(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

/// Question entity (note: is_correct is never returned by API)
class Question extends Equatable {
  final int id;
  final String text;
  final String type; // mcq | match | fill_blank | hear_touch
  final List<QuestionOption> options;
  final String? audioUrl;
  final int difficulty; // 1=easy, 2=medium, 3=hard

  const Question({
    required this.id,
    required this.text,
    required this.type,
    required this.options,
    this.audioUrl,
    this.difficulty = 1,
  });

  @override
  List<Object?> get props => [id];

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      text: json['question_text'] as String,
      type: json['type'] as String? ?? 'mcq',
      options: (json['options'] as List)
          .map((o) => QuestionOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      audioUrl: json['audio_url'] as String?,
      difficulty: json['difficulty'] as int? ?? 1,
    );
  }
}

class QuestionOption extends Equatable {
  final int id;
  final String text;

  const QuestionOption({required this.id, required this.text});

  @override
  List<Object?> get props => [id];

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'] as int,
      text: json['option_text'] as String,
    );
  }
}
