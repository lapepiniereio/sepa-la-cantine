import 'package:flutter/material.dart';

class FilePickerDialog extends StatelessWidget {
  const FilePickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Sélectionner'),
      children: <Widget>[
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context, 'file');
          },
          child: const Row(
            children: [
              Icon(Icons.file_upload),
              SizedBox(width: 10),
              Text('Un fichier XML'),
            ],
          ),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context, 'folder');
          },
          child: const Row(
            children: [
              Icon(Icons.folder_open),
              SizedBox(width: 10),
              Text('Un dossier de fichiers XML'),
            ],
          ),
        ),
      ],
    );
  }
}
