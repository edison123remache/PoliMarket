import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String nombre;
  final String? avatarUrl;
  final String? bio;
  final double ratingAvg;
  final String rol;
  
  //final bool isVerified;

  const UserModel({
    required this.id,
    required this.email,
    required this.nombre,
    this.avatarUrl,
    this.bio,
    this.ratingAvg = 0,
    this.rol = 'user',
    //this.isVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
      rol: json['rol'] as String? ?? 'user',
      //isVerified: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'avatar_url': avatarUrl,
      'bio': bio,
      'rating_avg': ratingAvg,
      'rol': rol,
      //'is_verified': isVerified,
    };
  }

  @override
  List<Object?> get props => [
    id,
    email,
    nombre,
    avatarUrl,
    bio,
    ratingAvg,
    rol,
    //isVerified,
  ];
}
