import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/sync_models.dart';

class ReportDataSource {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> getReports({
    String? status,
    String? priority,
    String? reportType,
    int perPage = 15,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (status != null) queryParams['status'] = status;
      if (priority != null) queryParams['priority'] = priority;
      if (reportType != null) queryParams['report_type'] = reportType;
      queryParams['per_page'] = perPage.toString();
      queryParams['page'] = page.toString();

      final response = await _dio.get(
        '/reports',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération des signalements',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la récupération des signalements';
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

  /// Synchronise les signalements avec le serveur
  Future<ReportSyncResponse> syncReports(ReportSyncRequest request) async {
    try {
      final data = request.toJson();
      
      final response = await _dio.get(
        '/reports/sync',
        queryParameters: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ReportSyncResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la synchronisation des signalements',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la synchronisation des signalements';
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
}