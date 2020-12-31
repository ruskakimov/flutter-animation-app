import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mooltik/gallery/ui/add_project_button.dart';
import 'package:mooltik/gallery/ui/home_bar.dart';
import 'package:mooltik/gallery/ui/projects_gallery.dart';
import 'package:mooltik/gallery/data/projects_manager_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProjectsManagerModel manager = ProjectsManagerModel();

  @override
  void initState() {
    super.initState();
    _initProjectsManager();
  }

  Future<void> _initProjectsManager() async {
    if (await Permission.storage.request().isGranted) {
      final Directory dir = await getApplicationDocumentsDirectory();
      await manager.init(dir);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProjectsManagerModel>.value(
      value: manager,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeBar(),
            Expanded(child: ProjectGallery()),
          ],
        ),
        floatingActionButton: AddProjectButton(),
      ),
    );
  }
}
