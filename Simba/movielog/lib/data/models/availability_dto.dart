/// 닉네임/이메일 중복 체크 응답: { "available": true }
class AvailabilityDto {
  const AvailabilityDto({required this.available});

  final bool available;

  factory AvailabilityDto.fromJson(Map<String, dynamic> json) {
    return AvailabilityDto(available: json['available'] as bool? ?? false);
  }
}
