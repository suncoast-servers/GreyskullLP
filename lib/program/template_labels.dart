import 'package:greyskull_lp/models/training_state.dart';

/// Plain-language labels for barbell templates (issue #79).
///
/// The book keeps its full names in the data layer; the UI avoids chapter
/// references and variant jargon.
class TemplateLabels {
  const TemplateLabels._();

  static const Map<BarbellTemplate, String> shortName = {
    BarbellTemplate.ogBase: 'OG Base',
    BarbellTemplate.villain: 'Villain',
    BarbellTemplate.gladiator: 'Gladiator',
    BarbellTemplate.twoDaySplit: 'Two-Day Split',
    BarbellTemplate.fourDaySplit: 'Four-Day Split',
    BarbellTemplate.custom: 'Custom',
  };

  static const Map<BarbellTemplate, String> oneLiner = {
    BarbellTemplate.ogBase: 'The classic three-day A/B program.',
    BarbellTemplate.villain: 'OG Base plus arms, neck and weighted chins.',
    BarbellTemplate.gladiator: 'Advanced splits with more volume.',
    BarbellTemplate.twoDaySplit: 'Two lifting days a week.',
    BarbellTemplate.fourDaySplit: 'One main lift per day.',
    BarbellTemplate.custom: 'Your own template.',
  };

  static String nameFor(BarbellTemplate template) =>
      shortName[template] ?? template.name;

  static String lineFor(BarbellTemplate template) => oneLiner[template] ?? '';
}
