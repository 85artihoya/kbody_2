class User {
  final String id;
  final String name;
  final String email;
  final String gender;
  final DateTime birthDate;
  final String address;
  final String? detailAddress;
  final String? disabilityType;
  final String? gmfcsLevel;
  final String? developmentalType;
  final String? otherDisabilityName;
  final String userType;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.birthDate,
    required this.address,
    this.detailAddress,
    this.disabilityType,
    this.gmfcsLevel,
    this.developmentalType,
    this.otherDisabilityName,
    this.userType = 'disabled',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '미입력',
      birthDate: json['birth_date'] != null 
        ? DateTime.parse(json['birth_date'].toString()) 
        : DateTime.now(),
      address: json['address']?.toString() ?? '미입력',
      detailAddress: json['detail_address']?.toString(),
      disabilityType: json['disability_type']?.toString(),
      gmfcsLevel: json['gmfcs_level']?.toString(),
      developmentalType: json['developmental_type']?.toString(),
      otherDisabilityName: json['other_disability_name']?.toString(),
      userType: json['user_type']?.toString() ?? 'disabled',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'gender': gender,
      'birth_date': birthDate.toIso8601String(),
      'address': address,
      'detail_address': detailAddress,
      'disability_type': disabilityType,
      'gmfcs_level': gmfcsLevel,
      'developmental_type': developmentalType,
      'other_disability_name': otherDisabilityName,
      'user_type': userType,
    };
  }
}
