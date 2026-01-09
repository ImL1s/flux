import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

Future<void> initHivePlatform() async {
  final appDir = await getApplicationDocumentsDirectory();
  final fluxDir = Directory('${appDir.path}/flux_persistence');
  if (!await fluxDir.exists()) {
    await fluxDir.create(recursive: true);
  }
  Hive.init(fluxDir.path);
}
