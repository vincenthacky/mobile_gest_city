import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';
import '../models/admin_overview_model.dart';

class AdminOverviewDataSource {
  final Dio _dio = DioClient.instance;

  Future<AdminOverviewModel> getOverview() async {
    try {
      debugPrint('🔄 [ADMIN OVERVIEW] Fetching overview data...');

      final response = await _dio.get('/overview/admin');

      debugPrint('📥 [ADMIN OVERVIEW] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [ADMIN OVERVIEW] Data received successfully');
        return AdminOverviewModel.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération des données',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [ADMIN OVERVIEW] Error: ${e.message}');

      if (e.response?.statusCode == 401) {
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }

      throw Exception(
        e.response?.data['message'] ??
            'Erreur lors de la récupération des données',
      );
    } catch (e) {
      debugPrint('❌ [ADMIN OVERVIEW] Unexpected error: $e');
      rethrow;
    }
  }
}
