import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mooltik/home/projects_manager_model.dart';

class AddProjectButton extends StatelessWidget {
  const AddProjectButton({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<ProjectsManagerModel>();

    return FloatingActionButton(
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Icon(
        FontAwesomeIcons.plus,
        size: 18,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      onPressed: manager.addProject,
    );
  }
}