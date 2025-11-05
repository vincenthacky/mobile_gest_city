import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/cash_movements_response_model.dart';

class CashMovementsDataSource {
  final Dio _dio = DioClient.instance;

  Future<CashMovementsResponse> getCashMovements({
    String? filter,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'per_page': perPage,
      };
      
      if (filter != null && filter.isNotEmpty) {
        queryParameters['filter'] = filter;
      }

      final response = await _dio.get(
        '/transactions/cash-movements',
        queryParameters: queryParameters,
      );

      return CashMovementsResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la récupération des mouvements de caisse';
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