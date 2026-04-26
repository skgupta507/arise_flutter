import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../api/saavn_api.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});
  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  final _ctrl      = TextEditingController();
  List<Map<String,dynamic>> _trending = [];
  List<Map<String,dynamic>> _results  = [];
  bool _loadingT   = true;
  bool _loadingS   = false;

  static const _trendingNames = [
    'Arijit Singh','Shreya Ghoshal','AP Dhillon','Diljit Dosanjh',
    'Badshah','Neha Kakkar','Jubin Nautiyal','Atif Aslam',
    'Armaan Malik','Darshan Raval','Guru Randhawa','B Praak',
    'Sonu Nigam','Udit Narayan','Sunidhi Chauhan','KK',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _loadTrending() async {
    final results = await SaavnApi.searchArtists('trending indian artists');
    if (!mounted) return;
    setState(() { _trending = results; _loadingT = false; });
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) { setState(() => _results = []); return; }
    setState(() => _loadingS = true);
    final r = await SaavnApi.searchArtists(q);
    if (!mounted) return;
    setState(() { _results = r; _loadingS = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final accent  = isDark ? AriseColors.demonAccent  : AriseColors.angelAccent;
    final bg      = isDark ? AriseColors.demonBg      : AriseColors.angelBg;
    final textPri = isDark ? AriseColors.demonText    : AriseColors.angelText;
    final textSub = isDark ? AriseColors.demonSubtext : AriseColors.angelSubtext;
    final textMut = isDark ? AriseColors.demonMuted   : AriseColors.angelMuted;

    final displayList = _results.isNotEmpty ? _results : _trending;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Artists', style: TextStyle(fontFamily:'Orbitron', color:accent, fontSize:16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _ctrl,
              style: TextStyle(fontFamily:'Rajdhani', color:textPri),
              decoration: InputDecoration(
                hintText:  'Search artists…',
                hintStyle: TextStyle(fontFamily:'Rajdhani', color:textMut),
                prefixIcon:Icon(Icons.search_rounded, color:textMut),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, color:textMut),
                        onPressed: () { _ctrl.clear(); setState(() => _results = []); })
                    : null,
              ),
              onChanged: (q) => Future.delayed(
                const Duration(milliseconds:300), () { if (_ctrl.text == q) _search(q); }),
            ),
          ),
        ),
      ),
      body: _loadingT && _results.isEmpty
          ? Center(child: CircularProgressIndicator(color:accent))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, mainAxisSpacing: 20, crossAxisSpacing: 12,
                childAspectRatio: .75,
              ),
              itemCount: displayList.length,
              itemBuilder: (_, i) {
                final a      = displayList[i];
                final name   = a['name']?.toString() ?? '';
                final images = a['image'] as List?;
                final thumb  = images != null && images.length > 1
                    ? images[1]['url']?.toString()
                    : images?.lastOrNull?['url']?.toString();
                return GestureDetector(
                  onTap: () => context.go('/artists/${a['id']}?name=${Uri.encodeComponent(name)}'),
                  child: Column(children:[
                    Container(
                      width:80, height:80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color:accent.withOpacity(.35), width:2),
                        gradient: LinearGradient(
                          colors: [accent.withOpacity(.2), accent.withOpacity(.05)]),
                      ),
                      child: ClipOval(
                        child: thumb != null
                            ? CachedNetworkImage(imageUrl:thumb, fit:BoxFit.cover,
                                errorWidget:(_,__,___)=>Center(child:Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style:TextStyle(fontFamily:'Orbitron', color:accent, fontSize:24, fontWeight:FontWeight.w900))))
                            : Center(child:Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style:TextStyle(fontFamily:'Orbitron', color:accent, fontSize:24, fontWeight:FontWeight.w900))),
                      ),
                    ),
                    const SizedBox(height:6),
                    Text(name, textAlign:TextAlign.center, maxLines:2, overflow:TextOverflow.ellipsis,
                      style:TextStyle(fontFamily:'Rajdhani', color:textSub, fontSize:12, fontWeight:FontWeight.w600)),
                  ]),
                );
              },
            ),
    );
  }
}

extension _ListExt<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
