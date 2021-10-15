import 'package:flutter/material.dart';
import 'package:Fanga/constants/assets.dart';
import 'package:Fanga/custom/widgets/app_drawer.dart';
import 'package:Fanga/custom/widgets/search_delegate.dart';
import 'package:Fanga/screens/Lelscan/all_manga.dart';
import 'package:Fanga/screens/Lelscan/latest_update.dart';
import 'package:Fanga/screens/Lelscan/top_manga.dart';
import 'package:Fanga/screens/mangafox/manga_list.dart';

class Mangafox extends StatefulWidget {
  @override
  _MangafoxState createState() => _MangafoxState();
}

class _MangafoxState extends State<Mangafox> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Color.fromRGBO(28, 28, 28, 1),
          bottom: TabBar(
            isScrollable: true,
            onTap: (index) {
              // Tab index when user select it, it start from zero
            },
            tabs: [
              Tab(
                text: "Manga Populaires",
              ),
              Tab(
                text: "Mises à jour",
              ),
              Tab(
                text: "Liste Des Mangas",
              ),
              Tab(
                text: "Top Mangas",
              ),
            ],
          ),
          title: Text(
            "MangaFox",
            style: TextStyle(color: Colors.white, fontSize: 22.0),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              color: Colors.white,
              onPressed: () {
                showSearch(
                    context: context,
                    delegate: SearchManga(Assets.mangafoxCatalogName));
              },
            ),
            IconButton(
              icon: Icon(
                Icons.sort,
                color: Colors.white,
              ),
              onPressed: () {},
            ),
          ],
        ),
        drawer: AppDrawer(),
        body: TabBarView(
          children: [
            MangaList(),
            LatestUpdates(),
            AllManga(),
            TopManga(),
          ],
        ),
      ),
    ));
  }
}
