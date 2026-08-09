class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String subscriptionPlan;
  final String subscriptionStatus;
  final String kycStatus;
  final String registrationDate;
  final String? manager;
  final String? managerId;
  final String? expiryDate;
  final String? planPrice;
  final String? startDate;
  final String registrationStatus;
  final String registrationType;
  final String registrationSource;
  final String planSource;
  final List<String> plans; // List of active plan names
  final String? userId; // Display ID
  final Map<String, dynamic>? paymentIntent; // Added for Pending Approval logic
  final String panCard;
  final String userStatus; // ACTIVE or SUSPENDED
  final bool isViewOnly;

  UserModel({
    required this.id,
    this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.subscriptionPlan,
    required this.subscriptionStatus,
    required this.kycStatus,
    required this.registrationDate,
    this.manager,
    this.managerId,
    this.expiryDate,
    this.planPrice,
    this.startDate,
    required this.registrationStatus,
    required this.registrationType,
    required this.registrationSource,
    required this.planSource,
    this.plans = const [],
    this.paymentIntent,
    this.panCard = '',
    this.userStatus = 'ACTIVE',
    this.isViewOnly = false,
  });

  String get fullName => lastName.isEmpty ? firstName : '$firstName $lastName';
  String get createdAt => registrationDate;
  String get formattedPhone => mobile;

  bool get isAdmin =>
      subscriptionPlan.toLowerCase() == 'admin' ||
      subscriptionPlan.toLowerCase() == 'super_admin';

  bool get isResearcher => subscriptionPlan.toLowerCase() == 'researcher';

  bool get isDirector => subscriptionPlan.toLowerCase() == 'director';

  static String _parseMongoId(dynamic id) {
    if (id is Map && id.containsKey('\$oid'))
      return id['\$oid']?.toString() ?? '';
    return id?.toString() ?? '';
  }

  static String _parseMongoDate(dynamic date) {
    if (date is Map && date.containsKey('\$date'))
      return date['\$date']?.toString() ?? '';
    return date?.toString() ?? '';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userDetails = json['userDetails'] ?? {};
    return UserModel(
      id: _parseMongoId(json['_id'] ?? json['id']),
      firstName:
          json['fullName'] ?? json['username'] ?? userDetails['APP_NAME'] ?? '',
      lastName: '',
      email:
          json['email'] ??
          json['emailAddress'] ??
          userDetails['APP_EMAIL'] ??
          '',
      mobile:
          json['phone']?.toString() ??
          userDetails['APP_MOB_NO']?.toString() ??
          '',
      subscriptionPlan:
          json['packageName'] ??
          json['subscriptionPlan'] ??
          json['userType'] ??
          json['deparment'] ??
          json['department'] ??
          'N/A',
      subscriptionStatus:
          json['packagestatus'] ?? json['subscriptionStatus'] ?? 'N/A',
      kycStatus: json['kycStatus'] ?? 'N/A',
      registrationDate: _parseMongoDate(
        json['createdAt'] ?? json['registrationDate'],
      ),
      manager: json['Manager'] ?? json['managerName'] ?? json['manager'],
      managerId: json['ManagerId'] ?? json['managerId'],
      expiryDate: _parseMongoDate(
        json['subscriptionEndDate'] ??
            json['packageEndDate'] ??
            json['expiryDate'],
      ),
      planPrice: (json['packageAmount'] ?? json['planPrice'])?.toString(),
      startDate: _parseMongoDate(json['packageStartDate'] ?? json['startDate']),
      registrationStatus: json['registrationStatus'] ?? 'PENDING',
      registrationType: json['registrationType'] ?? 'N/A',
      registrationSource: json['registrationSource'] ?? 'APP',
      planSource: json['planSource'] ?? 'APP',
      plans:
          (json['plans'] as List?)
              ?.map((p) => p['packageName'].toString())
              .toList() ??
          (json['activePlans'] as List?)
              ?.map((p) => (p['packageName'] ?? 'N/A').toString())
              .toList() ??
          [],
      userId: json['userId'],
      paymentIntent: json['paymentIntent'] ?? json['paymentsIntent'],
      panCard:
          json['panCard'] ??
          json['panNumber'] ??
          userDetails['APP_PAN_NO'] ??
          '',
      userStatus: json['userStatus'] ?? 'ACTIVE',
      isViewOnly: json['isViewOnly'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobile': mobile,
      'subscriptionPlan': subscriptionPlan,
      'subscriptionStatus': subscriptionStatus,
      'kycStatus': kycStatus,
      'registrationDate': registrationDate,
      'manager': manager,
      'managerId': managerId,
      'expiryDate': expiryDate,
      'planPrice': planPrice,
      'startDate': startDate,
      'registrationStatus': registrationStatus,
      'registrationType': registrationType,
      'registrationSource': registrationSource,
      'planSource': planSource,
      'paymentIntent': paymentIntent,
      'panCard': panCard,
    };
  }
}
