import 'song_model.dart';

class PlaylistModel {
  final String       id;
  final String       name;
  final List<SongModel> songs;
  final String?      thumbnail;
  final String       source;   // 'local' | 'youtube' | 'spotify'
  final int          createdAt;

  const PlaylistModel({
    required this.id,
    required this.name,
    this.songs = const [],
    this.thumbnail,
    this.source = 'local',
    required this.createdAt,
  });

  int get count => songs.length;

  PlaylistModel copyWith({
    String? name,
    List<SongModel>? songs,
    String? thumbnail,
  }) => PlaylistModel(
    id: id,
    name: name ?? this.name,
    songs: songs ?? this.songs,
    thumbnail: thumbnail ?? this.thumbnail,
    source: source,
    createdAt: createdAt,
  );

  Map<String,dynamic> toJson() => {
    'id': id, 'name': name,
    'songs': songs.map((s) => s.toJson()).toList(),
    'thumbnail': thumbnail, 'source': source, 'createdAt': createdAt,
  };

  factory PlaylistModel.fromJson(Map<String,dynamic> j) => PlaylistModel(
    id:        j['id']?.toString() ?? '',
    name:      j['name']?.toString() ?? 'Playlist',
    songs:     (j['songs'] as List?)
                  ?.map((s) => SongModel.fromJson(Map<String,dynamic>.from(s as Map)))
                  .toList() ?? [],
    thumbnail: j['thumbnail']?.toString(),
    source:    j['source']?.toString() ?? 'local',
    createdAt: int.tryParse(j['createdAt']?.toString() ?? '0') ?? 0,
  );
}
