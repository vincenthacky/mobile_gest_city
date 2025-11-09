import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/dio_client.dart';
import '../models/cash_totals_model.dart';

class CashTotalsDataSource {
  final Dio _dio = DioClient.instance;

  Future<CashTotalsResponse> getCashTotals() async {
    try {
      debugPrint('=== APPEL API CASH TOTALS ===');
      debugPrint('URL: ${_dio.options.baseUrl}/transactions/cash-totals');
      
      final response = await _dio.get('/transactions/cash-totals');
      
      debugPrint('Réponse API reçue: ${response.statusCode}');
      debugPrint('Données brutes: ${response.data}');
      
      final result = CashTotalsResponse.fromJson(response.data);
      debugPrint('Données parsées - Recettes: ${result.data.totals.totalReceipts}');
      debugPrint('==============================');
      
      return result;
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la récupération des totaux';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message: errorMessage,
        );
      } else {
        throw DioException(
          requestOptions: e.requestOptions,
          message: 'Erreur de réseau. Vérifiez votre connexion internet.',
        );
      }
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }
}