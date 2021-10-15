import 'package:dartz/dartz.dart';
import 'package:fanga/models/manga.dart';
import 'package:fanga/networking/services/lelscan_service.dart';
import 'package:fanga/state/base_provider.dart';
import 'package:fanga/utils/n_exception.dart';

class ReadmangatodayUpdatesProvider extends BaseProvider {
  Either<NException, List<Manga>> updatedMangaList = Right([]);

  getUpdatedMangaList(String catalogName, int page, bool forceRefresh) {
    this.toggleLoadingState();
    lelscanService
        .updatedMangaList(catalogName, page, forceRefresh)
        .then((mangas) {
      this.toggleLoadingState();
      updatedMangaList = Right(mangas!);
    }).catchError((error) {
      this.toggleLoadingState();
      print(error);
      updatedMangaList = Left(error);
    });
  }
}
