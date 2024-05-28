import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart' as gpu;

import 'package:flutter_scene/material/environment.dart';
import 'package:flutter_scene/material/mesh_standard_material.dart';
import 'package:flutter_scene/material/mesh_unlit_material.dart';
import 'package:flutter_scene_importer/flatbuffer.dart' as fb;

abstract class Material {
  static gpu.Texture? _whitePlaceholderTexture;

  static gpu.Texture getWhitePlaceholderTexture() {
    if (_whitePlaceholderTexture != null) {
      return _whitePlaceholderTexture!;
    }
    _whitePlaceholderTexture =
        gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, 1, 1);
    if (_whitePlaceholderTexture == null) {
      throw Exception('Failed to create placeholder texture.');
    }
    _whitePlaceholderTexture!
        .overwrite(Uint32List.fromList(<int>[0xFFFFFFFF]).buffer.asByteData());
    return _whitePlaceholderTexture!;
  }

  static Material fromFlatbuffer(
      fb.Material fbMaterial, List<gpu.Texture> textures) {
    switch (fbMaterial.type) {
      case fb.MaterialType.kUnlit:
        return MeshUnlitMaterial.fromFlatbuffer(fbMaterial, textures);
      case fb.MaterialType.kPhysicallyBased:
        return MeshStandardMaterial.fromFlatbuffer(fbMaterial, textures);
      default:
        throw Exception('Unknown material type');
    }
  }

  gpu.Shader? _fragmentShader;
  gpu.Shader get fragmentShader {
    if (_fragmentShader == null) {
      throw Exception('Fragment shader has not been set');
    }
    return _fragmentShader!;
  }

  void setFragmentShader(gpu.Shader shader) {
    _fragmentShader = shader;
  }

  void bind(gpu.RenderPass pass, gpu.HostBuffer transientsBuffer,
      Environment environment);
}
