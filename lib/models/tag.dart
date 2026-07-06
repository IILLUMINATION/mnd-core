class Tag {
  final String id;
  final String name;
  final String questId;
  final String? backgroundAssetId;
  final String? backgroundAudioId;
  final String folderPath;

  Tag({
    required this.id,
    required this.name,
    required this.questId,
    this.backgroundAssetId,
    this.backgroundAudioId,
    this.folderPath = '/',
  });

  static String normalizeFolderPath(String? raw) {
    final value = (raw ?? '').trim().replaceAll('\\', '/');
    if (value.isEmpty || value == '/') return '/';
    var path = value.startsWith('/') ? value : '/$value';
    path = path.replaceAll(RegExp(r'/+'), '/');
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        id: json['id'] as String,
        name: json['name'] as String,
        questId: json['questId'] as String? ?? '',
        backgroundAssetId: json['backgroundAssetId'] as String?,
        backgroundAudioId: json['backgroundAudioId'] as String?,
        folderPath: normalizeFolderPath(json['folderPath'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (backgroundAssetId != null) 'backgroundAssetId': backgroundAssetId,
        if (backgroundAudioId != null) 'backgroundAudioId': backgroundAudioId,
        if (folderPath != '/') 'folderPath': folderPath,
      };
}
