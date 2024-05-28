import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/material/environment.dart';
import 'package:flutter_scene/material/material.dart';
import 'package:flutter_scene/shaders.dart';

import 'package:flutter_scene_importer/flatbuffer.dart' as fb;

class MeshStandardMaterial extends Material {
  static MeshStandardMaterial fromFlatbuffer(
      fb.Material fbMaterial, List<gpu.Texture> textures) {
    if (fbMaterial.type != fb.MaterialType.kPhysicallyBased) {
      throw Exception('Cannot unpack PBR material from non-PBR material');
    }

    MeshStandardMaterial material = MeshStandardMaterial();

    // Base color.

    if (fbMaterial.baseColorFactor != null) {
      material.baseColorFactor = ui.Color.fromARGB(
          (fbMaterial.baseColorFactor!.a * 255).toInt(),
          (fbMaterial.baseColorFactor!.r * 255).toInt(),
          (fbMaterial.baseColorFactor!.g * 255).toInt(),
          (fbMaterial.baseColorFactor!.b * 255).toInt());
    }

    if (fbMaterial.baseColorTexture >= 0 &&
        fbMaterial.baseColorTexture < textures.length) {
      material.baseColorTexture = textures[fbMaterial.baseColorTexture];
    }

    // Metallic-roughness.

    material.metallicFactor = fbMaterial.metallicFactor;
    material.roughnessFactor = fbMaterial.roughnessFactor;

    if (fbMaterial.metallicRoughnessTexture >= 0 &&
        fbMaterial.metallicRoughnessTexture < textures.length) {
      material.metallicRoughnessTexture =
          textures[fbMaterial.metallicRoughnessTexture];
    }

    // Normal.

    if (fbMaterial.normalTexture >= 0 &&
        fbMaterial.normalTexture < textures.length) {
      material.normalTexture = textures[fbMaterial.normalTexture];
    }

    material.normalScale = fbMaterial.normalScale;

    // Emissive.

    if (fbMaterial.emissiveFactor != null) {
      material.emissiveFactor = ui.Color.fromARGB(
          (fbMaterial.emissiveFactor!.x * 255).toInt(),
          (fbMaterial.emissiveFactor!.y * 255).toInt(),
          (fbMaterial.emissiveFactor!.z * 255).toInt(),
          255);
    }

    if (fbMaterial.emissiveTexture >= 0 &&
        fbMaterial.emissiveTexture < textures.length) {
      material.emissiveTexture = textures[fbMaterial.emissiveTexture];
    }

    // Occlusion.

    if (fbMaterial.occlusionTexture >= 0 &&
        fbMaterial.occlusionTexture < textures.length) {
      material.occlusionTexture = textures[fbMaterial.occlusionTexture];
    }

    return material;
  }

  MeshStandardMaterial(
      {gpu.Texture? colorTexture,
      gpu.Texture? metallicRoughnessTexture,
      gpu.Texture? normalTexture,
      gpu.Texture? emissiveTexture,
      gpu.Texture? occlusionTexture,
      this.environment}) {
    setFragmentShader(baseShaderLibrary['StandardFragment']!);
    baseColorTexture = colorTexture ?? Material.getWhitePlaceholderTexture();
    metallicRoughnessTexture =
        metallicRoughnessTexture ?? Material.getWhitePlaceholderTexture();
    normalTexture = normalTexture ?? Material.getWhitePlaceholderTexture();
    emissiveTexture = emissiveTexture ?? Material.getWhitePlaceholderTexture();
    occlusionTexture =
        occlusionTexture ?? Material.getWhitePlaceholderTexture();
  }

  late gpu.Texture baseColorTexture;
  ui.Color baseColorFactor = const ui.Color(0xFFFFFFFF);
  double vertexColorWeight = 1.0;

  late gpu.Texture metallicRoughnessTexture;
  double metallicFactor = 1.0;
  double roughnessFactor = 1.0;

  late gpu.Texture normalTexture;
  double normalScale = 1.0;

  late gpu.Texture emissiveTexture;
  ui.Color emissiveFactor = const ui.Color(0x00000000);

  late gpu.Texture occlusionTexture;

  Environment? environment;

  @override
  void bind(gpu.RenderPass pass, gpu.HostBuffer transientsBuffer,
      Environment environment) {
    Environment env = this.environment ?? environment;
    gpu.Texture environmentTexture =
        env.texture ?? Material.getWhitePlaceholderTexture();

    var fragInfo = Float32List.fromList([
      baseColorFactor.red / 256.0, baseColorFactor.green / 256.0,
      baseColorFactor.blue / 256.0, baseColorFactor.alpha / 256.0, // color
      vertexColorWeight, // vertex_color_weight
      0.0, 0.0, 0.0, // padding
      1.0, // exposure
      0.0, 0.0, 0.0, // padding
      metallicFactor, // metallic
      0.0, 0.0, 0.0, // padding
      roughnessFactor, // roughness
      0.0, 0.0, 0.0, // padding
      normalScale, // normal_scale
      0.0, 0.0, 0.0, // padding
      normalScale, // environment_intensity
      0.0, 0.0, 0.0, // padding
    ]);
    pass.bindUniform(fragmentShader.getUniformSlot("FragInfo"),
        transientsBuffer.emplace(ByteData.sublistView(fragInfo)));
    pass.bindTexture(
        fragmentShader.getUniformSlot('base_color_texture'), baseColorTexture,
        sampler: gpu.SamplerOptions(
            widthAddressMode: gpu.SamplerAddressMode.repeat,
            heightAddressMode: gpu.SamplerAddressMode.repeat));
    pass.bindTexture(
        fragmentShader.getUniformSlot('metallic_roughness_texture'),
        metallicRoughnessTexture,
        sampler: gpu.SamplerOptions(
            widthAddressMode: gpu.SamplerAddressMode.repeat,
            heightAddressMode: gpu.SamplerAddressMode.repeat));
    pass.bindTexture(
        fragmentShader.getUniformSlot('normal_texture'), normalTexture,
        sampler: gpu.SamplerOptions(
            widthAddressMode: gpu.SamplerAddressMode.repeat,
            heightAddressMode: gpu.SamplerAddressMode.repeat));
    pass.bindTexture(fragmentShader.getUniformSlot('environment_texture'),
        environmentTexture,
        sampler: gpu.SamplerOptions(
            widthAddressMode: gpu.SamplerAddressMode.repeat,
            heightAddressMode: gpu.SamplerAddressMode.repeat));
  }
}
