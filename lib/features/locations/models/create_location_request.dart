class CreateLocationRequest {
  final int? communityId;
  final String? newCommunityName;
  final int? streetNameId;
  final String? newStreetName;
  final String streetNumber;
  final int squareFootage;
  final String? lotNumber;
  final String? city;
  final String? state;

  CreateLocationRequest({
    this.communityId,
    this.newCommunityName,
    this.streetNameId,
    this.newStreetName,
    required this.streetNumber,
    this.squareFootage = 1,
    this.lotNumber,
    this.city,
    this.state,
  });

  Map<String, dynamic> toJson() {
    return {
      'communityId': communityId,
      'newCommunityName': newCommunityName,
      'streetNameId': streetNameId,
      'newStreetName': newStreetName,
      'streetNumber': streetNumber,
      'squareFootage': squareFootage,
      'lotNumber': lotNumber,
      'city': city,
      'state': state,
    };
  }
}
