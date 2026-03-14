class LiveStreamRequest {
  final String sdpOffer;
  final String streamType;

  LiveStreamRequest({
    required this.sdpOffer,
    required this.streamType,
  });

  Map<String, dynamic> toJson() {
    return {
      'sdpOffer': sdpOffer,
      'streamType': streamType,
    };
  }
}

class StreamStartResponse {
  final String sdpAnswer;
  final String sessionId;

  StreamStartResponse({
    required this.sdpAnswer,
    required this.sessionId,
  });

  factory StreamStartResponse.fromJson(Map<String, dynamic> json) {
    return StreamStartResponse(
      sdpAnswer: json['sdpAnswer'] ?? '',
      sessionId: json['sessionId'] ?? '',
    );
  }
}