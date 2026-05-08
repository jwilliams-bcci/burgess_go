class ElevationPhoto {
  final String? localPath;
  final String? elevationPhotoLink;
  final bool isUploaded;

  ElevationPhoto({
    this.localPath,
    this.elevationPhotoLink,
    this.isUploaded = false,
  });

  factory ElevationPhoto.fromMap(Map<String, dynamic> data) {
    return ElevationPhoto(
      elevationPhotoLink: data['elevationPhotoLink'] as String?,
      isUploaded: true,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'elevationPhotoLink': elevationPhotoLink,
    };
  }

  ElevationPhoto copyWith({
    String? localPath,
    String? elevationPhotoLink,
    bool? isUploaded,
  }) {
    return ElevationPhoto(
      localPath: localPath ?? this.localPath,
      elevationPhotoLink: elevationPhotoLink ?? this.elevationPhotoLink,
      isUploaded: isUploaded ?? this.isUploaded,
    );
  }
}
