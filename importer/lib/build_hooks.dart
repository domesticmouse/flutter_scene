import 'dart:io';

import 'package:native_assets_cli/native_assets_cli.dart';

void buildModels({
  required BuildConfig buildConfig,
  required List<String> inputFilePaths,
  String outputDirectory = 'build/models/',
}) {
  final outDir =
      Directory.fromUri(buildConfig.packageRoot.resolve(outputDirectory));
  outDir.createSync(recursive: true);

  for (final inputFilePath in inputFilePaths) {
    String outputFileName = Uri(path: inputFilePath).pathSegments.last;

    // Verify that the input file is a glTF file
    if (!outputFileName.endsWith('.glb')) {
      throw Exception('Input file must be a .glb file. Given file path: $inputFilePath');
    }

    // Replace output extension with .model
    outputFileName = '${outputFileName.substring(0, outputFileName.lastIndexOf('.'))}.model';

    /// dart --enable-experiment=native-assets run flutter_scene_importer:import \
    ///      --input <input> --output <output> --working-directory <working-directory>
    final importerResult = Process.runSync(
      'dart',
      [
        '--enable-experiment=native-assets',
        'run',
        'flutter_scene_importer:import',
        '--input',
        inputFilePath,
        '--output',
        outDir.uri.resolve(outputFileName).toFilePath(),
        '--working-directory',
        buildConfig.packageRoot.toFilePath(),
      ],
    );
    if (importerResult.exitCode != 0) {
      throw Exception(
          'Failed to run flutter_scene_importer:import command in build hook (exit code ${importerResult.exitCode}):\nSTDERR: ${importerResult.stderr}\nSTDOUT: ${importerResult.stdout}');
    }
  }
}
