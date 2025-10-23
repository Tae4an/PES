import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/disaster_model.dart';
import '../models/shelter_model.dart';
import '../models/action_card_model.dart';

part 'remote_data_source.g.dart';

@RestApi()
abstract class RemoteDataSource {
  factory RemoteDataSource(Dio dio, {String baseUrl}) = _RemoteDataSource;

  // Disaster Endpoints
  @GET('/api/v1/disasters/active')
  Future<List<DisasterModel>> getActiveDisasters();

  @GET('/api/v1/disasters/nearby')
  Future<List<DisasterModel>> getNearbyDisasters(
    @Query('latitude') double latitude,
    @Query('longitude') double longitude,
    @Query('radius_km') double radiusKm,
  );

  // Shelter Endpoints
  @GET('/api/v1/shelters/nearest')
  Future<List<ShelterModel>> getNearestShelters(
    @Query('latitude') double latitude,
    @Query('longitude') double longitude,
    @Query('limit') int limit,
  );

  @GET('/api/v1/shelters/{id}')
  Future<ShelterModel> getShelterById(@Path('id') int id);

  @GET('/api/v1/shelters/search')
  Future<List<ShelterModel>> searchShelters(@Query('q') String query);

  // Action Card Endpoints
  @POST('/api/v1/action-cards/generate')
  Future<ActionCardModel> generateActionCard(
    @Body() Map<String, dynamic> request,
  );

  // User Endpoints
  // @POST('/api/v1/users/register')
  // Future<Map<String, dynamic>> registerUser(@Body() Map<String, dynamic> data);

  @PUT('/api/v1/users/{userId}')
  Future<void> updateUser(
    @Path('userId') String userId,
    @Body() Map<String, dynamic> data,
  );

  @POST('/api/v1/users/{userId}/fcm-token')
  Future<void> updateFcmToken(
    @Path('userId') String userId,
    @Body() Map<String, dynamic> data,
  );
}

