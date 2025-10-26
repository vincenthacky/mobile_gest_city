import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../models/contribution_response.dart';

class ContributionDataSource {
  final Dio _dio = DioClient.instance;

  Future<ContributionResponse> getDefaultContribution() async {
    try {
      final response = await _dio.get('/contributions/default');

      if (response.statusCode == 200) {
        return ContributionResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération de la cotisation par défaut',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 
            'Erreur lors de la récupération de la cotisation par défaut';
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

  Future<ContributionListResponse> getContributions({int perPage = 3}) async {
    try {
      final response = await _dio.get('/contributions', queryParameters: {
        'per_page': perPage,
      });

      if (response.statusCode == 200) {
        return ContributionListResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération des cotisations',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 
            'Erreur lors de la récupération des cotisations';
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