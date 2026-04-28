

class SongModel {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? thumbnail;
  final String? streamUrl;   // Saavn download URL (pre-resolved)
  final String? ytId;        // YouTube video ID
  final String source;       // 'saavn' | 'youtube'
  final String? duration;
  final int?    durationSec;
  final int     addedAt;
  final String? language;
  final String? albumId;
  final String? artistId;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.thumbnail,
    this.streamUrl,
    this.ytId,
    this.source = 'youtube',
    this.duration,
    this.durationSec,
    this.addedAt = 0,
    this.language,
    this.albumId,
    this.artistId,
  });

  /// From JioSaavn song JSON
  factory SongModel.fromSaavn(Map<String,dynamic> json) {
    final images  = json['image'] as List?;
    final artists = (json['artists']?['primary'] as List?)
        ?.map((a) => a['name']?.toString() ?? '').join(', ')
        ?? (json['artists']?['all'] as List?)
            ?.map((a) => a['name']?.toString() ?? '').join(', ')
        ?? '';

    // Best stream URL
    String? url;
    final urls = json['downloadUrl'] as List?;
    if (urls != null && urls.isNotEmpty) {
      final sorted = List.from(urls)..sort((a,b) {
        const order = {'320kbps':0,'160kbps':1,'96kbps':2,'48kbps':3,'12kbps':4};
        return (order[a['quality']] ?? 5).compareTo(order[b['quality']] ?? 5);
      });
      url = sorted.first['url'] as String?;
    }

    return SongModel(
      id:          json['id']?.toString() ?? '',
      title:       json['name']?.toString() ?? json['title']?.toString() ?? '',
      artist:      artists,
      album:       json['album']?['name']?.toString(),
      thumbnail:   images != null && images.length > 1
                    ? images[1]['url']?.toString()
                    : images?.lastOrNull?['url']?.toString(),
      streamUrl:   url,
      source:      'saavn',
      duration:    json['duration']?.toString(),
      durationSec: int.tryParse(json['duration']?.toString() ?? ''),
      addedAt:     DateTime.now().millisecondsSinceEpoch,
      language:    json['language']?.toString(),
      albumId:     json['album']?['id']?.toString(),
      artistId:    (json['artists']?['primary'] as List?)?.firstOrNull?['id']?.toString(),
    );
  }

  /// From Muzo / YouTube Music JSON
  factory SongModel.fromMuzo(Map<String,dynamic> json) {
    final artists = (json['artists'] as List?)
        ?.map((a) => a['name']?.toString() ?? a.toString()).join(', ')
        ?? json['author']?.toString()
        ?? json['channelTitle']?.toString()
        ?? '';
    final id = json['videoId']?.toString() ?? json['id']?.toString() ?? '';
    final thumb = (json['thumbnails'] as List?)?.lastOrNull?['url']?.toString()
        ?? (id.isNotEmpty ? 'https://i.ytimg.com/vi/$id/hqdefault.jpg' : null);
    return SongModel(
      id:        id,
      ytId:      id,
      title:     json['title']?.toString() ?? json['name']?.toString() ?? '',
      artist:    artists,
      thumbnail: thumb,
      source:    'youtube',
      duration:  json['duration']?.toString(),
      addedAt:   DateTime.now().millisecondsSinceEpoch,
    );
  }

  SongModel copyWith({String? streamUrl, String? ytId}) => SongModel(
    id: id, title: title, artist: artist, album: album,
    thumbnail: thumbnail, source: source, duration: duration,
    durationSec: durationSec, addedAt: addedAt, language: language,
    albumId: albumId, artistId: artistId,
    streamUrl: streamUrl ?? this.streamUrl,
    ytId: ytId ?? this.ytId,
  );

  Map<String,dynamic> toJson() => {
    'id': id, 'title': title, 'artist': artist, 'album': album,
    'thumbnail': thumbnail, 'streamUrl': streamUrl, 'ytId': ytId,
    'source': source, 'duration': duration, 'addedAt': addedAt,
  };

  @override
  String toString() => 'SongModel($title — $artist)';
}

