import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestrore_datetime.dart';

/// Model data untuk ulasan / rating produk yang tersimpan di Firestore koleksi `reviews`.
class ReviewModel {
  final String id;
  final String orderId;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String ulasan;
  final DateTime createdAt;

  ReviewModel({
    this.id = '',
    required this.orderId,
    required this.productId,
    required this.userId,
    this.userName = 'Pengguna Fodos',
    required this.rating,
    this.ulasan = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ReviewModel copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? userId,
    String? userName,
    double? rating,
    String? ulasan,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      ulasan: ulasan ?? this.ulasan,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Pengguna Fodos',
      rating: doubleFromDynamic(json['rating']),

      ulasan: json['ulasan'] as String? ?? json['catatan'] as String? ?? '',
      createdAt: dateTimeFromJson(json['createdAt']),
    );
  }

  factory ReviewModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final mapWithId = Map<String, dynamic>.from(data)..['id'] = doc.id;
    return ReviewModel.fromJson(mapWithId);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'ulasan': ulasan,
      'createdAt': dateTimeToJson(createdAt),
    };
  }

  Map<String, dynamic> toFirestore() {
    final map = toJson();
    map.remove('id');
    return map;
  }
}
