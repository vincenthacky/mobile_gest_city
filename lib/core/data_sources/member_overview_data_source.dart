import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../models/member_overview_model.dart';

class MemberOverviewDataSource {
  final Dio _dio = DioClient.instance;

  /// Récupère les données overview member depuis l'API
  Future<MemberOverviewModel> getMemberOverview() async {
    try {
      final response = await _dio.get('/overview/member');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Vérifier la structure de la réponse
        if (data['success'] == true && data['data'] != null) {
          return MemberOverviewModel.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Réponse invalide du serveur');
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Erreur lors de la récupération des données overview',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Erreur lors de la récupération des données overview';
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
      throw Exception('Erreur inattendue lors de la récupération des données overview: $e');
    }
  }
}