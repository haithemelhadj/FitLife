import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/anatomy_models.dart';
import '../models/anatomy_asset_provider.dart';

/// A default implementation of [AnatomyAssetProvider] that uses bundled SVG assets.
class DefaultAnatomyProvider implements AnatomyAssetProvider {
  final AnatomyStyle style;

  const DefaultAnatomyProvider({
    this.style = AnatomyStyle.minimal,
  });

  @override
  Future<String> getAnatomySvgRawString(
      AnatomyGender gender, AnatomyView view) async {
    final genderStr = gender == AnatomyGender.male ? 'male' : 'female';
    final viewStr = view == AnatomyView.front ? 'front' : 'back';

    // Les SVG féminins s'appellent "muscles", les masculins "muscle".
    final fileName = gender == AnatomyGender.female
        ? '${genderStr}_${viewStr}_muscles_anatomy.svg'
        : '${genderStr}_${viewStr}_muscle_anatomy.svg';

    return await rootBundle.loadString('assets/anatomy/minimal/$fileName');
  }

  @override
  Widget buildSvgWidget(String svgString, {BoxFit fit = BoxFit.contain}) {
    return SvgPicture.string(
      svgString,
      fit: fit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DefaultAnatomyProvider && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
