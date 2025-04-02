class Token {
  final String accessToken;
  final String refreshToken;
  final int expirationTime;

  Token({
    required this.accessToken,
    required this.refreshToken,
    required this.expirationTime,
  });

  factory Token.empty() {
    return Token(
      accessToken: '',
      refreshToken: '',
      expirationTime: 0,
    );
  }

  Token.fromJson(Map<String, dynamic> json)
      : accessToken = json['accessToken'],
        refreshToken = json['refreshToken'],
        expirationTime = json['expirationTime'];

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expirationTime': expirationTime,
  };
}