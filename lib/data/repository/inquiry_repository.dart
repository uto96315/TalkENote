import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../constants/inquiry_category.dart';

class InquiryRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  InquiryRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('inquiries');

  /// お問い合わせを送信（Firestoreに保存）
  Future<String> submitInquiry({
    required String userId,
    required String? userEmail,
    required InquiryCategory category,
    required String content,
  }) async {
    try {
      final inquiryId = _uuid.v4();
      final now = DateTime.now();

      await _collection.doc(inquiryId).set({
        'id': inquiryId,
        'userId': userId,
        'userEmail': userEmail,
        'category': category.value,
        'content': content,
        'createdAt': Timestamp.fromDate(now),
        'status': 'pending', // pending, in_progress, resolved
      });

      return inquiryId;
    } catch (e) {
      debugPrint("🚨Error submitting inquiry: $e");
      rethrow;
    }
  }
}

