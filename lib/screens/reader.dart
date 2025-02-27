import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:bot_toast/bot_toast.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:esys_flutter_share_plus/esys_flutter_share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fanga/custom/widgets/sliding_appbar.dart';
import 'package:fanga/models/chapter.dart';
import 'package:fanga/models/manga.dart';
import 'package:fanga/state/page_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:fanga/state/bookmark_provider.dart';
import 'package:fanga/utils/reading_direction.dart';
import 'package:fanga/utils/size_config.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock/wakelock.dart';

class Reader extends StatefulWidget {
  final List<String?> pages;
  final Manga manga;
  final Chapter chapter;
  Reader(this.pages, this.manga, this.chapter);
  @override
  _ReaderState createState() => _ReaderState();
}

class _ReaderState extends State<Reader> with TickerProviderStateMixin {
  final CarouselController _controller = CarouselController();
  List<int> pages = [];
  bool enabledAppBar = false;
  late AnimationController _appbarController;
  bool showPagesNumber = true;
  bool fullScreen = true;
  bool keepScreenOn = false;
  bool contextualMenu = true;
  double currentPage = 1;
  ReadingDirectionModel? readingDirection = directions[0];
  @override
  void didChangeDependencies() {
    widget.pages.forEach((imageUrl) {
      if (Uri.parse(imageUrl!).isAbsolute) {
        precacheImage(NetworkImage(imageUrl), context);
      }
    });
    super.didChangeDependencies();
  }

  @override
  void initState() {
    // TODO: implement initState
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    _appbarController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    context.read<PageProvider>().findChapter(widget.chapter).then((value) {
      if (value != null) {
        if (!value.finished!) {
          _controller.jumpToPage(value.page!);
        }
      }
    });
    Wakelock.disable();
    super.initState();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: () async {
        if (pages.isEmpty) {
          context
              .read<PageProvider>()
              .updatePage(widget.chapter, 0, false, widget.manga);
        } else {
          List<int> distinctIds = pages.toSet().toList();
          if (distinctIds.reduce(max) == widget.pages.length - 1) {
            context.read<PageProvider>().updatePage(
                widget.chapter, distinctIds.reduce(max), true, widget.manga);
          } else {
            context.read<PageProvider>().updatePage(
                widget.chapter, distinctIds.reduce(max), false, widget.manga);
          }
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: SlidingAppBar(
          controller: _appbarController,
          visible: enabledAppBar,
          child: AppBar(
            backgroundColor: Color.fromRGBO(28, 28, 28, 1),
            title: Column(
              children: [
                Text(
                  widget.manga.title!,
                  style: TextStyle(fontSize: height / 42),
                ),
                Text(
                  widget.chapter.title!.isEmpty
                      ? "Chapitre ${widget.chapter.number}"
                      : widget.chapter.title!,
                  style: TextStyle(
                      fontSize: height / 50,
                      color: Colors.white.withOpacity(0.5)),
                )
              ],
            ),
            actions: [
              Padding(
                padding:
                    EdgeInsets.only(left: SizeConfig.blockSizeHorizontal! * 5),
                child: IconButton(
                    icon: Icon(
                      !context
                              .read<BookmarkProvider>()
                              .bookmarked
                              .contains(widget.chapter)
                          ? Icons.bookmark_border
                          : Icons.bookmark,
                      color: !context
                              .read<BookmarkProvider>()
                              .bookmarked
                              .contains(widget.chapter)
                          ? Colors.white
                          : Colors.cyan,
                    ),
                    onPressed: () {
                      context.read<BookmarkProvider>().bookmark(
                          widget.chapter, MediaQuery.of(context).size, true);
                    }),
              ),
              Padding(
                padding:
                    EdgeInsets.only(right: SizeConfig.blockSizeHorizontal! * 3),
                child: IconButton(
                    icon: Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      showBarModalBottomSheet(
                        context: context,
                        builder: (context) => StatefulBuilder(
                          builder: (context, StateSetter setState) {
                            return SingleChildScrollView(
                              controller: ModalScrollController.of(context),
                              child: Container(
                                height: SizeConfig.screenHeight / 2.5,
                                color: Colors.black,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      left: SizeConfig.blockSizeHorizontal! * 5,
                                      right:
                                          SizeConfig.blockSizeHorizontal! * 5,
                                      top: SizeConfig.blockSizeVertical! * 4),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Mode de lecture",
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                fontSize: SizeConfig
                                                        .blockSizeVertical! *
                                                    1.7),
                                          ),
                                          DropdownButton<ReadingDirectionModel>(
                                            hint: Text("Select item"),
                                            dropdownColor: Colors.black,
                                            underline: SizedBox(),
                                            value: readingDirection,
                                            onChanged:
                                                (ReadingDirectionModel? value) {
                                              setState(() {
                                                readingDirection = value;
                                              });
                                            },
                                            items: directions.map(
                                                (ReadingDirectionModel
                                                    readingDirectionModel) {
                                              return DropdownMenuItem<
                                                  ReadingDirectionModel>(
                                                value: readingDirectionModel,
                                                child: Text(
                                                  readingDirectionModel.text,
                                                  style: TextStyle(
                                                      color: Colors.grey),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Afficher le numéro des pages",
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                fontSize: SizeConfig
                                                        .blockSizeVertical! *
                                                    1.7),
                                          ),
                                          Switch(
                                              inactiveTrackColor: Colors.grey,
                                              value: showPagesNumber,
                                              onChanged: (bool value) {
                                                setState(() {
                                                  showPagesNumber = value;
                                                });
                                              })
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Plein écran",
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                fontSize: SizeConfig
                                                        .blockSizeVertical! *
                                                    1.7),
                                          ),
                                          Switch(
                                              inactiveTrackColor: Colors.grey,
                                              value: fullScreen,
                                              onChanged: (bool value) {
                                                setState(() {
                                                  fullScreen = value;
                                                  if (value) {
                                                    SystemChrome
                                                        .setEnabledSystemUIMode(
                                                            SystemUiMode.manual,
                                                            overlays: []);
                                                  } else {
                                                    SystemChrome
                                                        .setEnabledSystemUIMode(
                                                            SystemUiMode.manual,
                                                            overlays:
                                                                SystemUiOverlay
                                                                    .values);
                                                  }
                                                });
                                              })
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Garder l'écran allumé",
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                fontSize: SizeConfig
                                                        .blockSizeVertical! *
                                                    1.7),
                                          ),
                                          Switch(
                                              inactiveTrackColor: Colors.grey,
                                              value: keepScreenOn,
                                              onChanged: (bool value) {
                                                setState(() {
                                                  keepScreenOn = value;
                                                  Wakelock.toggle(
                                                      enable: value);
                                                });
                                              }),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Menu contextuel (appui prolongé)",
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                fontSize: SizeConfig
                                                        .blockSizeVertical! *
                                                    1.7),
                                          ),
                                          Switch(
                                              inactiveTrackColor: Colors.grey,
                                              value: true,
                                              onChanged: (bool value) {}),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
              ),
            ],
          ),
        ),
        body: Builder(
          builder: (context) {
            return InkWell(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    height: SizeConfig.screenHeight / 6,
                    color: Colors.black,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: SizeConfig.blockSizeVertical! * 2),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.share,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            title: Text(
                              "Partager",
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () async {
                              if (Uri.parse(
                                      widget.pages[currentPage.floor() - 1]!)
                                  .isAbsolute) {
                                var request = await HttpClient().getUrl(Uri.parse(widget.pages[currentPage.floor() - 1]!));
                                var response = await request.close();
                                Uint8List bytes = await consolidateHttpClientResponseBytes(response);
                                final Directory temp = await getTemporaryDirectory();
                                final path = '${temp.path}/image.jpg';
                                File(path).writeAsBytesSync(bytes);
                                await Share.shareFiles(
                                    [path],
                                    text:
                                    "${widget.manga.title}  Chapitre ${widget.chapter.number} page ${currentPage.floor() - 1}");
                              } else {
                                await Share.shareFiles(
                                    [widget.pages[currentPage.floor() - 1]!],
                                    text:
                                        "${widget.manga.title}  Chapitre ${widget.chapter.number} page ${currentPage.floor() - 1}");
                              }
                            },
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.download_outlined,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            title: Text(
                              "Télécharger la Page",
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () async {
                              if (Uri.parse(
                                      widget.pages[currentPage.floor() - 1]!)
                                  .isAbsolute) {
                                if (Platform.isAndroid) {
                                  final taskId =
                                      await FlutterDownloader.enqueue(
                                          url: widget
                                              .pages[currentPage.floor() - 1]!,
                                          savedDir:
                                              "storage/emulated/0/Download",
                                          showNotification:
                                              true, // show download progress in status bar (for Android)
                                          openFileFromNotification:
                                              true, // click on notification to open downloaded file (for Android)
                                          saveInPublicStorage: true,
                                          requiresStorageNotLow: false);
                                }
                              } else {
                                BotToast.showText(
                                    text:
                                        "Le fichier existe déjà sur votre appareil");
                              }
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
              onTap: () {
                setState(() {
                  if (fullScreen) {
                    enabledAppBar = !enabledAppBar;
                    if (enabledAppBar) {
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                          overlays: SystemUiOverlay.values);
                    } else {
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                          overlays: []);
                    }
                  }
                });
              },
              child: Stack(children: [
                Padding(
                  padding: EdgeInsets.only(
                      bottom: SizeConfig.blockSizeVertical! * 10),
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: SizeConfig.screenWidth,
                      height: SizeConfig.screenHeight / 1.4,
                      child: CarouselSlider(
                        carouselController: _controller,
                        options: CarouselOptions(
                          scrollDirection: readingDirection!.readingDirection ==
                                  ReadingDirection.HORIZONTAL
                              ? Axis.horizontal
                              : Axis.vertical,
                          //reverse: true,
                          enableInfiniteScroll: false,
                          onPageChanged: (int nextPage,
                              CarouselPageChangedReason
                                  carouselPageChangedReason) {
                            pages.add(nextPage);
                            setState(() {
                              currentPage = (nextPage + 1).toDouble();
                            });
                          },
                          height: height,
                          viewportFraction: 1.0,
                          enlargeCenterPage: false,
                        ),
                        items: widget.pages
                            .map((item) => Container(
                                  child: Center(
                                      child: InteractiveViewer(
                                    child: Uri.parse(item!).isAbsolute
                                        ? Image.network(
                                            item,
                                            height: height,
                                            fit: BoxFit.cover,
                                            loadingBuilder:
                                                (BuildContext context,
                                                    Widget child,
                                                    ImageChunkEvent?
                                                        loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder: (BuildContext context,
                                                Object exception,
                                                StackTrace? stackTrace) {
                                              return Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "Une erreur est survenue",
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        precacheImage(
                                                            NetworkImage(item),
                                                            context);
                                                        setState(() {});
                                                      },
                                                      child: Text("Recharger"),
                                                    )
                                                  ],
                                                ),
                                              );
                                            },
                                          )
                                        : Image.file(
                                            File(item),
                                            height: height,
                                            fit: BoxFit.cover,
                                          ),
                                    minScale: 0.2,
                                    maxScale: 100.2,
                                    boundaryMargin:
                                        const EdgeInsets.all(double.infinity),
                                  )),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                      bottom: SizeConfig.blockSizeVertical! * 5),
                  child: Align(
                      alignment: Alignment.bottomCenter,
                      child: showPagesNumber
                          ? Text(
                              "${currentPage.toInt().toString()}/${widget.pages.length.toString()}",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: SizeConfig.blockSizeHorizontal! * 4,
                                  fontWeight: FontWeight.bold),
                            )
                          : SizedBox()),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: enabledAppBar
                      ? Container(
                          width: SizeConfig.screenWidth,
                          height: SizeConfig.blockSizeVertical! * 7,
                          color: Color.fromRGBO(28, 28, 28, 1),
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: SizeConfig.blockSizeHorizontal! * 2,
                                right: SizeConfig.blockSizeHorizontal! * 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                IconButton(
                                  icon: Icon(
                                    FontAwesomeIcons.fastBackward,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _controller.previousPage();
                                  },
                                ),
                                Container(
                                    width: SizeConfig.blockSizeHorizontal! * 70,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          currentPage.toInt().toString(),
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: SizeConfig
                                                      .blockSizeHorizontal! *
                                                  4),
                                        ),
                                        Slider(
                                          activeColor: Colors.cyan,
                                          inactiveColor: Colors.grey,
                                          onChanged: (newValue) {
                                            setState(() {
                                              currentPage = newValue;
                                            });
                                            _controller
                                                .jumpToPage(newValue.floor());
                                          },
                                          value: currentPage,
                                          min: 1,
                                          max: widget.pages.length.toDouble(),
                                          divisions: widget.pages.length,
                                        ),
                                        Text(
                                          widget.pages.length.toString(),
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: SizeConfig
                                                      .blockSizeHorizontal! *
                                                  4),
                                        ),
                                      ],
                                    )),
                                IconButton(
                                  icon: Icon(
                                    FontAwesomeIcons.fastForward,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _controller.nextPage();
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(),
                )
              ]),
            );
          },
        ),
      ),
    );
  }
}
