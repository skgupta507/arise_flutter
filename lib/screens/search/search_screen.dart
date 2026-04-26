import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api/muzo_api.dart';
import '../../models/song_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cards/song_card.dart';
import '../../widgets/common/section_header.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _ctrl.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SearchProvider>().search(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final search  = context.watch<SearchProvider>();
    final isDark  = context.watch<ThemeProvider>().isDark;
    final accent  = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final bg      = isDark ? AriseColors.demonBg      : AriseColors.angelBg;
    final textPri = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textMut = isDark ? AriseColors.demonMuted   : AriseColors.angelMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: TextField(
          controller:    _ctrl,
          autofocus:     widget.initialQuery == null,
          style:         TextStyle(fontFamily:'Rajdhani', color:textPri, fontSize:16),
          decoration: InputDecoration(
            hintText:      'Search songs, artists, albums…',
            hintStyle:     TextStyle(fontFamily:'Rajdhani', color:textMut),
            border:        InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIcon:    Icon(Icons.search_rounded, color:textMut),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, color:textMut),
                    onPressed: () {
                      _ctrl.clear();
                      context.read<SearchProvider>().clear();
                    },
                  )
                : null,
          ),
          onChanged: (q) => context.read<SearchProvider>().onQueryChanged(q),
          onSubmitted: (q) {
            if (q.trim().isNotEmpty) context.read<SearchProvider>().search(q);
          },
          textInputAction: TextInputAction.search,
        ),
      ),
      body: Column(
        children: [
          // ── Tab bar ─────────────────────────────────────────────────────────
          if (search.hasResults)
            TabBar(
              controller:          _tabs,
              indicatorColor:      accent,
              labelColor:          accent,
              unselectedLabelColor:textMut,
              labelStyle:          const TextStyle(fontFamily:'Rajdhani', fontWeight:FontWeight.w700, fontSize:13),
              dividerColor:        Colors.transparent,
              isScrollable:        true,
              tabs: const [
                Tab(text: 'ALL'),
                Tab(text: 'SONGS'),
                Tab(text: 'ALBUMS'),
                Tab(text: 'ARTISTS'),
              ],
            ),

          Expanded(
            child: search.loading
                ? Center(child: CircularProgressIndicator(color: accent))
                : !search.hasResults && search.suggestions.isEmpty
                    ? _EmptyState(isDark: isDark, textMut: textMut)
                    : search.suggestions.isNotEmpty && !search.hasResults
                        ? _SuggestionList(
                            suggestions: search.suggestions,
                            accent: accent,
                            textSub: isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext,
                            onTap: (s) {
                              _ctrl.text = s;
                              context.read<SearchProvider>().search(s);
                            },
                          )
                        : TabBarView(
                            controller: _tabs,
                            children: [
                              _AllTab(search: search, isDark: isDark),
                              _SongsTab(songs: search.songs),
                              _AlbumsTab(albums: search.albums, isDark: isDark, accent: accent),
                              _ArtistsTab(artists: search.artists, isDark: isDark, accent: accent),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Suggestion list ────────────────────────────────────────────────────────────
class _SuggestionList extends StatelessWidget {
  final List<String> suggestions;
  final Color accent, textSub;
  final void Function(String) onTap;
  const _SuggestionList({required this.suggestions, required this.accent, required this.textSub, required this.onTap});

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: suggestions.length,
    itemBuilder: (_, i) => ListTile(
      leading:  Icon(Icons.search_rounded, color: textSub, size: 18),
      title:    Text(suggestions[i], style: TextStyle(fontFamily:'Rajdhani', color: textSub)),
      trailing: Icon(Icons.north_west_rounded, color: textSub, size: 16),
      onTap:    () => onTap(suggestions[i]),
    ),
  );
}

// ── All results tab ────────────────────────────────────────────────────────────
class _AllTab extends StatelessWidget {
  final SearchProvider search;
  final bool isDark;
  const _AllTab({required this.search, required this.isDark});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (search.songs.isNotEmpty) ...[
        SectionHeader(title: '🎵 Songs'),
        ...search.songs.take(5).map((s) => SongTile(song:s, queue:search.songs)),
        const SizedBox(height: 16),
      ],
      if (search.albums.isNotEmpty) ...[
        SectionHeader(title: '💿 Albums'),
        SizedBox(
          height: 155,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: search.albums.take(8).length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final a = search.albums[i];
              final images = a['image'] as List?;
              final thumb  = images != null && images.length > 1 ? images[1]['url']?.toString() : null;
              return GestureDetector(
                onTap: () => context.go('/albums/${a['id']}'),
                child: SizedBox(width:110, child:Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(imageUrl:thumb??'', width:110, height:110, fit:BoxFit.cover,
                        errorWidget:(_,__,___)=>Container(width:110,height:110,color:Colors.grey.withOpacity(.2),
                          child:const Icon(Icons.album_rounded,size:40)))),
                    const SizedBox(height:4),
                    Text(a['name']?.toString()??'', maxLines:1, overflow:TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily:'Rajdhani', fontWeight:FontWeight.w700, fontSize:12)),
                  ],
                )),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (search.artists.isNotEmpty) ...[
        SectionHeader(title: '🎤 Artists'),
        SizedBox(
          height: 115,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: search.artists.take(8).length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final a = search.artists[i];
              final images = a['image'] as List?;
              final thumb  = images?.lastOrNull?['url']?.toString();
              final name   = a['name']?.toString() ?? '';
              final isDark = context.read<ThemeProvider>().isDark;
              final accent = isDark ? AriseColors.demonAccent : AriseColors.angelAccent;
              return GestureDetector(
                onTap: () => context.go('/artists/${a['id']}?name=${Uri.encodeComponent(name)}'),
                child: SizedBox(width:72, child:Column(children:[
                  Container(width:64, height:64,
                    decoration: BoxDecoration(shape:BoxShape.circle,
                      border:Border.all(color:accent.withOpacity(.3),width:2)),
                    child: ClipOval(child: thumb!=null
                      ? CachedNetworkImage(imageUrl:thumb, fit:BoxFit.cover)
                      : Container(color:accent.withOpacity(.1),
                          child:Center(child:Text(name.isNotEmpty?name[0].toUpperCase():'?',
                            style:TextStyle(fontFamily:'Orbitron',color:accent,fontSize:20,fontWeight:FontWeight.w900)))))),
                  const SizedBox(height:4),
                  Text(name, textAlign:TextAlign.center, maxLines:2, overflow:TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily:'Rajdhani', fontSize:11)),
                ])),
              );
            },
          ),
        ),
      ],
    ],
  );
}

// ── Songs tab ─────────────────────────────────────────────────────────────────
class _SongsTab extends StatelessWidget {
  final List<SongModel> songs;
  const _SongsTab({required this.songs});

  @override
  Widget build(BuildContext context) => songs.isEmpty
      ? const Center(child: Text('No songs found'))
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: songs.length,
          itemBuilder: (_, i) => SongTile(song:songs[i], queue:songs, showIndex:true, index:i),
        );
}

// ── Albums tab ────────────────────────────────────────────────────────────────
class _AlbumsTab extends StatelessWidget {
  final List<Map<String,dynamic>> albums;
  final bool isDark;
  final Color accent;
  const _AlbumsTab({required this.albums, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) => albums.isEmpty
      ? const Center(child: Text('No albums found'))
      : GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
            childAspectRatio: .85,
          ),
          itemCount: albums.length,
          itemBuilder: (_, i) {
            final a = albums[i];
            final images = a['image'] as List?;
            final thumb  = images != null && images.length > 1 ? images[1]['url']?.toString() : null;
            return GestureDetector(
              onTap: () => context.go('/albums/${a['id']}'),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                ClipRRect(borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(imageUrl:thumb??'', width:double.infinity, height:160, fit:BoxFit.cover,
                    errorWidget:(_,__,___)=>Container(height:160,color:accent.withOpacity(.1),
                      child:Icon(Icons.album_rounded,color:accent,size:50)))),
                const SizedBox(height:6),
                Text(a['name']?.toString()??'', maxLines:1, overflow:TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily:'Rajdhani', fontWeight:FontWeight.w700, fontSize:13)),
                Text(a['description']?.toString()??'', maxLines:1, overflow:TextOverflow.ellipsis,
                  style: TextStyle(fontFamily:'Rajdhani', color:isDark?AriseColors.demonSubtext:AriseColors.angelSubtext, fontSize:11)),
              ]),
            );
          },
        );
}

// ── Artists tab ───────────────────────────────────────────────────────────────
class _ArtistsTab extends StatelessWidget {
  final List<Map<String,dynamic>> artists;
  final bool isDark;
  final Color accent;
  const _ArtistsTab({required this.artists, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) => artists.isEmpty
      ? const Center(child: Text('No artists found'))
      : GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, mainAxisSpacing: 20, crossAxisSpacing: 12,
            childAspectRatio: .8,
          ),
          itemCount: artists.length,
          itemBuilder: (_, i) {
            final a = artists[i];
            final name   = a['name']?.toString() ?? '';
            final images = a['image'] as List?;
            final thumb  = images?.lastOrNull?['url']?.toString();
            return GestureDetector(
              onTap: () => context.go('/artists/${a['id']}?name=${Uri.encodeComponent(name)}'),
              child: Column(children:[
                Container(width:80, height:80,
                  decoration: BoxDecoration(shape:BoxShape.circle,
                    border:Border.all(color:accent.withOpacity(.3),width:2)),
                  child: ClipOval(child: thumb!=null
                    ? CachedNetworkImage(imageUrl:thumb,fit:BoxFit.cover)
                    : Container(color:accent.withOpacity(.1),
                        child:Center(child:Text(name.isNotEmpty?name[0].toUpperCase():'?',
                          style:TextStyle(fontFamily:'Orbitron',color:accent,fontSize:24,fontWeight:FontWeight.w900)))))),
                const SizedBox(height:6),
                Text(name, textAlign:TextAlign.center, maxLines:2, overflow:TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily:'Rajdhani', fontWeight:FontWeight.w600, fontSize:12)),
              ]),
            );
          },
        );
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final Color textMut;
  const _EmptyState({required this.isDark, required this.textMut});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(isDark ? '🔮' : '🔍', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('Search for songs, artists, albums',
          style: TextStyle(fontFamily:'Rajdhani', color:textMut, fontSize:15)),
      ],
    ),
  );
}

extension _ListExt<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}

extension _CtxRead on BuildContext {
  T read<T>() => Provider.of<T>(this, listen: false);
}
