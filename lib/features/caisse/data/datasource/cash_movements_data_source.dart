import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/cash_movements_response.dart';

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
      throw Exception('Erreur lors de la récupération des mouvements de caisse: ${e.message}');
    }
  }
}