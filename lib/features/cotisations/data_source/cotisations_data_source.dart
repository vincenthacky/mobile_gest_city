import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/models/contribution_response.dart';

class CotisationsDataSource {
  final Dio _dio = DioClient.instance;

  Future<ContributionListResponse> getContributions({
    int perPage = 10,
    int page = 1,
    String? search,
    String? status, // finished, pending
    bool? alreadyPaid,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'per_page': perPage,
        'page': page,
      };

      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      if (alreadyPaid != null) {
        queryParameters['already_paid'] = alreadyPaid;
      }

      final response = await _dio.get('/contributions', queryParameters: queryParameters);

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