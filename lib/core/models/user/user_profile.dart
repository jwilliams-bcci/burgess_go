enum UserRole {
  trade,
  superintendent,
  areaManager,
  divisionManager,
  regionalManager,
  nationalManager,
  admin,
}

class UserProfile {
  final int securityUserId;
  final String email;
  final UserRole role;

  final List<int> communityIds;
  final List<int> divisionIds;
  final List<int> builderIds;
  final List<int> locationIds;
  final int? tradeId;

  UserProfile({
    required this.securityUserId,
    required this.email,
    required this.role,
    this.communityIds = const [],
    this.divisionIds = const [],
    this.builderIds = const [],
    this.locationIds = const [],
    this.tradeId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // 1. Get API Role (e.g., "Area Manager") and clean it
    String apiRoleRaw = (json['role'] as String? ?? '').replaceAll(' ', '');
    // Result: "AreaManager" (PascalCase)

    // 2. Match to Enum
    // We compare case-insensitively to be safe, OR you can strictly convert to camelCase.
    // This robust method finds the matching enum even if API is "AreaManager" and enum is "areaManager".
    UserRole parsedRole = UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == apiRoleRaw.toLowerCase(),
      orElse: () => UserRole.superintendent,
    );

    // 3. Parse Scopes (Standard logic)
    List<int> communities = [];
    List<int> divisions = [];
    List<int> builders = [];
    List<int> locations = [];
    int? trade;

    if (json['scopes'] != null) {
      for (var scope in json['scopes']) {
        String type = (scope['scopeType'] as String? ?? '').toLowerCase();
        int val = scope['scopeValue'] as int? ?? 0;

        if (val == 0) continue;

        switch (type) {
          case 'community':
            communities.add(val);
            break;
          case 'division':
            divisions.add(val);
            break;
          case 'builder':
            builders.add(val);
            break;
          case 'location':
            locations.add(val);
            break;
          case 'trade':
            trade = val;
            break;
        }
      }
    }

    return UserProfile(
      securityUserId: json['securityUserId'] ?? 0,
      email: json['email'] ?? '',
      role: parsedRole,
      communityIds: communities,
      divisionIds: divisions,
      builderIds: builders,
      locationIds: locations,
      tradeId: trade,
    );
  }
}
