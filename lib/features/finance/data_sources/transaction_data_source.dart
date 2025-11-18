import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/transaction_sync_models.dart';

class TransactionDataSource {
  final Dio _dio = DioClient.instance;

  /// Synchronise les transactions avec le serveur
  Future<TransactionSyncResponse> syncTransactions(TransactionSyncRequest request) async {
    try {
      final data = request.toJson();
      
      final response = await _dio.post(
        '/transactions/sync',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TransactionSyncResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la synchronisation des transactions',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la synchronisation des transactions';
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
      throw Exception('Erreur inattendue lors de la synchronisation: $e');
    }
  }

  /// Récupère les données de solde/recettes/dépenses
  Future<Map<String, dynamic>> getFinancialSummary() async {
    try {
      final response = await _dio.get('/financial-summary');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération du résumé financier',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la récupération du résumé financier';
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