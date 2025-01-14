import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

import '../models/processing_status.dart';
import '../services/sepa_service.dart';
import '../widgets/file_picker_dialog.dart';
import '../widgets/file_status_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _sepaService = SepaService();
  List<File> selectedFiles = [];
  String? outputDirectory;
  bool isProcessing = false;
  List<ProcessingStatus> processingStatus = [];
  int processedFiles = 0;

  Future<void> _pickXMLFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
    );

    if (result != null) {
      setState(() {
        selectedFiles = [File(result.files.single.path!)];
        processingStatus = [];
        processedFiles = 0;
      });
      _initializeProcessingStatus();
    }
  }

  Future<void> _pickXMLFolder() async {
    String? folderPath = await FilePicker.platform.getDirectoryPath();

    if (folderPath != null) {
      final directory = Directory(folderPath);
      final List<File> xmlFiles = directory
          .listSync(recursive: false)
          .whereType<File>()
          .where((file) => path.extension(file.path).toLowerCase() == '.xml')
          .toList();

      setState(() {
        selectedFiles = xmlFiles;
        processingStatus = [];
        processedFiles = 0;
      });
      _initializeProcessingStatus();
    }
  }

  void _initializeProcessingStatus() {
    setState(() {
      processingStatus = selectedFiles
          .map((file) => ProcessingStatus(path.basename(file.path), 'pending'))
          .toList();
    });
  }

  Future<void> _selectOutputDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choisissez le dossier de sortie',
    );

    if (selectedDirectory != null) {
      setState(() {
        outputDirectory = selectedDirectory;
      });
    }
  }

  Future<void> _pickFiles() async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const FilePickerDialog(),
    );

    if (result == 'file') {
      await _pickXMLFile();
    } else if (result == 'folder') {
      await _pickXMLFolder();
    }
  }

  Future<void> _openOutputFolder() async {
    if (outputDirectory == null) {
      _showMessage('❌ Aucun dossier de sortie sélectionné');
      return;
    }

    try {
      if (Platform.isMacOS) {
        await Process.run('open', [outputDirectory!]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [outputDirectory!]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [outputDirectory!]);
      }
    } catch (e) {
      _showMessage('❌ Impossible d\'ouvrir le dossier');
    }
  }

  Future<void> _processFiles() async {
    if (selectedFiles.isEmpty) {
      _showMessage('❌ Aucun fichier XML sélectionné');
      return;
    }

    if (outputDirectory == null) {
      _showMessage('❌ Veuillez sélectionner un dossier de sortie');
      return;
    }

    setState(() {
      isProcessing = true;
      processedFiles = 0;
    });

    for (var i = 0; i < selectedFiles.length; i++) {
      final file = selectedFiles[i];

      setState(() {
        processingStatus[i] =
            ProcessingStatus(path.basename(file.path), 'processing');
      });

      try {
        final content = await file.readAsString();
        final document = XmlDocument.parse(content);

        if (!_sepaService.isValidSepaFile(document)) {
          throw Exception('Le fichier n\'est pas un fichier SEPA valide');
        }

        if (_sepaService.isAlreadyInstant(document)) {
          setState(() {
            processingStatus[i] = ProcessingStatus(
              path.basename(file.path),
              'already_inst',
              message: 'Ce fichier est déjà en format SEPA instantané',
            );
            processedFiles++;
          });
          continue;
        }

        _sepaService.convertToInstantSepa(document);

        final fileName = path.basenameWithoutExtension(file.path);
        final newPath = path.join(
          outputDirectory!,
          '${fileName}_inst.xml',
        );

        await File(newPath).writeAsString(document.toXmlString(pretty: true));

        setState(() {
          processingStatus[i] =
              ProcessingStatus(path.basename(file.path), 'success');
          processedFiles++;
        });
      } catch (e) {
        setState(() {
          processingStatus[i] = ProcessingStatus(
            path.basename(file.path),
            'error',
            message: e.toString(),
          );
          processedFiles++;
        });
      }
    }

    setState(() {
      isProcessing = false;
    });

    _showMessage('✨ Traitement terminé !');

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('✅ Traitement terminé'),
            content: const Text('Les fichiers ont été convertis avec succès.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Fermer'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openOutputFolder();
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('Ouvrir le dossier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _resetInterface() {
    setState(() {
      selectedFiles = [];
      outputDirectory = null;
      processingStatus = [];
      processedFiles = 0;
      isProcessing = false;
    });
    _showMessage('🔄 Interface réinitialisée');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEPA La Cantine'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _resetInterface,
            icon: const Icon(Icons.refresh),
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📁 Conversion SEPA vers SEPA Instantané',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: isProcessing ? null : _pickFiles,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter des fichiers'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: isProcessing ? null : _selectOutputDirectory,
                  icon: const Icon(Icons.output),
                  label: const Text('Dossier de sortie'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (outputDirectory != null) ...[
              Text(
                '📂 Dossier de sortie: ${path.basename(outputDirectory!)}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
            ],
            if (selectedFiles.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📋 Fichiers sélectionnés (${selectedFiles.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isProcessing)
                    ElevatedButton.icon(
                      onPressed: _processFiles,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Démarrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (isProcessing)
                LinearProgressIndicator(
                  value: processedFiles / selectedFiles.length,
                ),
              const SizedBox(height: 16),
              Expanded(
                child: FileStatusList(processingStatus: processingStatus),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
