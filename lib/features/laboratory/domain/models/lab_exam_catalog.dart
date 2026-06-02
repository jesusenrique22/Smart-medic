import 'package:flutter/material.dart';

/// Tipo de muestra / área del laboratorio.
enum LabSampleType {
  blood,
  urine,
  stool,
  hormones,
  microbiology,
  tumorMarkers,
  coagulation,
  immunology,
  genetics,
  other,
}

extension LabSampleTypeX on LabSampleType {
  String get label {
    switch (this) {
      case LabSampleType.blood:
        return 'Sangre';
      case LabSampleType.urine:
        return 'Orina';
      case LabSampleType.stool:
        return 'Heces';
      case LabSampleType.hormones:
        return 'Hormonas y tiroides';
      case LabSampleType.microbiology:
        return 'Microbiología';
      case LabSampleType.tumorMarkers:
        return 'Marcadores tumorales';
      case LabSampleType.coagulation:
        return 'Coagulación';
      case LabSampleType.immunology:
        return 'Inmunología';
      case LabSampleType.genetics:
        return 'Genética';
      case LabSampleType.other:
        return 'Otros';
    }
  }

  IconData get icon {
    switch (this) {
      case LabSampleType.blood:
        return Icons.bloodtype_rounded;
      case LabSampleType.urine:
        return Icons.water_drop_rounded;
      case LabSampleType.stool:
        return Icons.science_outlined;
      case LabSampleType.hormones:
        return Icons.monitor_heart_rounded;
      case LabSampleType.microbiology:
        return Icons.biotech_rounded;
      case LabSampleType.tumorMarkers:
        return Icons.analytics_rounded;
      case LabSampleType.coagulation:
        return Icons.water_rounded;
      case LabSampleType.immunology:
        return Icons.shield_rounded;
      case LabSampleType.genetics:
        return Icons.family_restroom_rounded;
      case LabSampleType.other:
        return Icons.medical_services_rounded;
    }
  }

  Color get color {
    switch (this) {
      case LabSampleType.blood:
        return const Color(0xFFDC2626);
      case LabSampleType.urine:
        return const Color(0xFFF59E0B);
      case LabSampleType.stool:
        return const Color(0xFF92400E);
      case LabSampleType.hormones:
        return const Color(0xFF7C3AED);
      case LabSampleType.microbiology:
        return const Color(0xFF059669);
      case LabSampleType.tumorMarkers:
        return const Color(0xFFDB2777);
      case LabSampleType.coagulation:
        return const Color(0xFF2563EB);
      case LabSampleType.immunology:
        return const Color(0xFF0891B2);
      case LabSampleType.genetics:
        return const Color(0xFF4F46E5);
      case LabSampleType.other:
        return const Color(0xFF64748B);
    }
  }
}

/// Definición de un examen de laboratorio disponible.
class LabExamDefinition {
  final String id;
  final String name;
  final LabSampleType sampleType;
  final String preparation;
  final String turnaround; // ej. "24 h", "Mismo día"
  final double referencePrice;

  const LabExamDefinition({
    required this.id,
    required this.name,
    required this.sampleType,
    required this.preparation,
    required this.turnaround,
    this.referencePrice = 0,
  });
}

/// Catálogo de exámenes más comunes en laboratorio clínico.
class LabExamCatalog {
  LabExamCatalog._();

  static const List<LabExamDefinition> all = [
    // —— Sangre ——
    LabExamDefinition(
      id: 'hema-cbc',
      name: 'Hemograma completo (CBC)',
      sampleType: LabSampleType.blood,
      preparation: 'No requiere ayunas. Evitar ejercicio intenso 24 h antes.',
      turnaround: '2–4 h',
      referencePrice: 12,
    ),
    LabExamDefinition(
      id: 'bio-glucose',
      name: 'Glucosa en ayunas',
      sampleType: LabSampleType.blood,
      preparation: 'Ayunas de 8 a 12 horas. Solo agua permitida.',
      turnaround: '2 h',
      referencePrice: 8,
    ),
    LabExamDefinition(
      id: 'bio-hba1c',
      name: 'Hemoglobina glicosilada (HbA1c)',
      sampleType: LabSampleType.blood,
      preparation: 'No requiere ayunas.',
      turnaround: '24 h',
      referencePrice: 18,
    ),
    LabExamDefinition(
      id: 'bio-lipid',
      name: 'Perfil lipídico completo',
      sampleType: LabSampleType.blood,
      preparation: 'Ayunas de 12 horas. No alcohol 24 h antes.',
      turnaround: '24 h',
      referencePrice: 22,
    ),
    LabExamDefinition(
      id: 'bio-liver',
      name: 'Perfil hepático (ALT, AST, bilirrubina, FA)',
      sampleType: LabSampleType.blood,
      preparation: 'Ayunas de 8 h recomendadas.',
      turnaround: '24 h',
      referencePrice: 28,
    ),
    LabExamDefinition(
      id: 'bio-renal',
      name: 'Función renal (creatinina, BUN, ácido úrico)',
      sampleType: LabSampleType.blood,
      preparation: 'Hidratación normal. Ayunas no obligatorias.',
      turnaround: '24 h',
      referencePrice: 20,
    ),
    LabExamDefinition(
      id: 'bio-electrolytes',
      name: 'Electrolitos séricos (Na, K, Cl)',
      sampleType: LabSampleType.blood,
      preparation: 'Sin preparación especial.',
      turnaround: '4 h',
      referencePrice: 15,
    ),
    LabExamDefinition(
      id: 'bio-iron',
      name: 'Hierro sérico y ferritina',
      sampleType: LabSampleType.blood,
      preparation: 'Ayunas de 8 h. Evitar suplementos de hierro 24 h antes.',
      turnaround: '24 h',
      referencePrice: 25,
    ),
    LabExamDefinition(
      id: 'bio-vitd',
      name: 'Vitamina D (25-OH)',
      sampleType: LabSampleType.blood,
      preparation: 'No requiere ayunas.',
      turnaround: '48–72 h',
      referencePrice: 35,
    ),
    LabExamDefinition(
      id: 'bio-b12-folate',
      name: 'Vitamina B12 y ácido fólico',
      sampleType: LabSampleType.blood,
      preparation: 'Ayunas de 8 h.',
      turnaround: '48 h',
      referencePrice: 30,
    ),
    LabExamDefinition(
      id: 'serology-hiv',
      name: 'VIH (ELISA / confirmación)',
      sampleType: LabSampleType.blood,
      preparation: 'No requiere ayunas. Consentimiento informado.',
      turnaround: '24–48 h',
      referencePrice: 20,
    ),
    LabExamDefinition(
      id: 'serology-hep',
      name: 'Hepatitis B y C (panel)',
      sampleType: LabSampleType.blood,
      preparation: 'No requiere ayunas.',
      turnaround: '48 h',
      referencePrice: 45,
    ),
    LabExamDefinition(
      id: 'serology-syphilis',
      name: 'Sífilis (VDRL / RPR)',
      sampleType: LabSampleType.blood,
      preparation: 'No requiere ayunas.',
      turnaround: '24 h',
      referencePrice: 12,
    ),
    LabExamDefinition(
      id: 'blood-type',
      name: 'Grupo sanguíneo y Rh',
      sampleType: LabSampleType.blood,
      preparation: 'Sin ayunas.',
      turnaround: '2 h',
      referencePrice: 10,
    ),
    LabExamDefinition(
      id: 'psa',
      name: 'PSA total (próstata)',
      sampleType: LabSampleType.blood,
      preparation: 'Evitar relaciones sexuales y ciclismo 48 h antes.',
      turnaround: '24 h',
      referencePrice: 22,
    ),

    // —— Orina ——
    LabExamDefinition(
      id: 'urine-routine',
      name: 'Examen general de orina (EGO)',
      sampleType: LabSampleType.urine,
      preparation: 'Primera orina de la mañana. Limpieza genital previa.',
      turnaround: '2–4 h',
      referencePrice: 8,
    ),
    LabExamDefinition(
      id: 'urine-culture',
      name: 'Urocultivo con antibiograma',
      sampleType: LabSampleType.urine,
      preparation: 'Orina media. Limpieza genital. Evitar antibióticos si es posible.',
      turnaround: '48–72 h',
      referencePrice: 25,
    ),
    LabExamDefinition(
      id: 'urine-24h-protein',
      name: 'Proteinuria en orina de 24 h',
      sampleType: LabSampleType.urine,
      preparation: 'Recolección de 24 h con frasco estéril proporcionado.',
      turnaround: '48 h',
      referencePrice: 30,
    ),
    LabExamDefinition(
      id: 'urine-pregnancy',
      name: 'Prueba de embarazo en orina (β-hCG)',
      sampleType: LabSampleType.urine,
      preparation: 'Primera orina de la mañana recomendada.',
      turnaround: '30 min',
      referencePrice: 6,
    ),
    LabExamDefinition(
      id: 'urine-drug',
      name: 'Toxicología en orina (panel drogas)',
      sampleType: LabSampleType.urine,
      preparation: 'Muestra reciente bajo supervisión si aplica.',
      turnaround: '24–48 h',
      referencePrice: 40,
    ),

    // —— Heces ——
    LabExamDefinition(
      id: 'stool-routine',
      name: 'Coproparasitario seriado (3 muestras)',
      sampleType: LabSampleType.stool,
      preparation: 'Recolectar en frasco estéril. Una muestra por día en días alternos.',
      turnaround: '48–72 h',
      referencePrice: 18,
    ),
    LabExamDefinition(
      id: 'stool-occult-blood',
      name: 'Sangre oculta en heces (SOH)',
      sampleType: LabSampleType.stool,
      preparation: 'Evitar carnes rojas y aspirina 3 días antes. Dieta blanda 48 h.',
      turnaround: '24 h',
      referencePrice: 12,
    ),
    LabExamDefinition(
      id: 'stool-culture',
      name: 'Coprocultivo',
      sampleType: LabSampleType.stool,
      preparation: 'Muestra fresca en frasco estéril. Evitar laxantes y antibióticos.',
      turnaround: '48–72 h',
      referencePrice: 28,
    ),
    LabExamDefinition(
      id: 'stool-hpylori',
      name: 'Helicobacter pylori en heces (antígeno)',
      sampleType: LabSampleType.stool,
      preparation: 'Suspender IBP y antibióticos 2 semanas antes si es posible.',
      turnaround: '48 h',
      referencePrice: 35,
    ),
    LabExamDefinition(
      id: 'stool-calprotectin',
      name: 'Calprotectina fecal',
      sampleType: LabSampleType.stool,
      preparation: 'Muestra en frasco proporcionado. Sin laxantes.',
      turnaround: '5–7 días',
      referencePrice: 55,
    ),

    // —— Hormonas ——
    LabExamDefinition(
      id: 'thyroid-tsh',
      name: 'TSH (tiroides)',
      sampleType: LabSampleType.hormones,
      preparation: 'Preferible en ayunas. Tomar medicación tiroides después de la muestra.',
      turnaround: '24 h',
      referencePrice: 18,
    ),
    LabExamDefinition(
      id: 'thyroid-panel',
      name: 'Panel tiroideo (TSH, T3, T4 libre)',
      sampleType: LabSampleType.hormones,
      preparation: 'Ayunas de 8 h.',
      turnaround: '24–48 h',
      referencePrice: 42,
    ),
    LabExamDefinition(
      id: 'hormone-cortisol',
      name: 'Cortisol matutino',
      sampleType: LabSampleType.hormones,
      preparation: 'Muestra entre 7:00 y 9:00 AM. Reposo 30 min antes.',
      turnaround: '24 h',
      referencePrice: 22,
    ),
    LabExamDefinition(
      id: 'hormone-testosterone',
      name: 'Testosterona total',
      sampleType: LabSampleType.hormones,
      preparation: 'Muestra matutina (7–10 AM) en hombres.',
      turnaround: '24–48 h',
      referencePrice: 28,
    ),
    LabExamDefinition(
      id: 'hormone-estradiol',
      name: 'Estradiol',
      sampleType: LabSampleType.hormones,
      preparation: 'Indicar día del ciclo menstrual si aplica.',
      turnaround: '24–48 h',
      referencePrice: 26,
    ),
    LabExamDefinition(
      id: 'hormone-progesterone',
      name: 'Progesterona',
      sampleType: LabSampleType.hormones,
      preparation: 'Día 21 del ciclo (o según indicación médica).',
      turnaround: '24–48 h',
      referencePrice: 24,
    ),
    LabExamDefinition(
      id: 'hormone-fsh-lh',
      name: 'FSH y LH',
      sampleType: LabSampleType.hormones,
      preparation: 'Indicar fase del ciclo. Ayunas no obligatorias.',
      turnaround: '24–48 h',
      referencePrice: 32,
    ),
    LabExamDefinition(
      id: 'hormone-prolactin',
      name: 'Prolactina',
      sampleType: LabSampleType.hormones,
      preparation: 'Reposo 30 min. Evitar estrés y relaciones sexuales 24 h antes.',
      turnaround: '24 h',
      referencePrice: 22,
    ),
    LabExamDefinition(
      id: 'hormone-insulin',
      name: 'Insulina en ayunas',
      sampleType: LabSampleType.hormones,
      preparation: 'Ayunas de 10–12 h.',
      turnaround: '24 h',
      referencePrice: 25,
    ),

    // —— Microbiología ——
    LabExamDefinition(
      id: 'micro-strep',
      name: 'Estreptococo (antígeno rápido faringe)',
      sampleType: LabSampleType.microbiology,
      preparation: 'No comer ni beber 15 min antes del hisopado.',
      turnaround: '15–30 min',
      referencePrice: 15,
    ),
    LabExamDefinition(
      id: 'micro-covid',
      name: 'COVID-19 (PCR o antígeno)',
      sampleType: LabSampleType.microbiology,
      preparation: 'Hisopado nasofaríngeo en el laboratorio.',
      turnaround: '2–24 h',
      referencePrice: 25,
    ),
    LabExamDefinition(
      id: 'micro-influenza',
      name: 'Influenza A/B (antígeno rápido)',
      sampleType: LabSampleType.microbiology,
      preparation: 'Hisopado nasofaríngeo.',
      turnaround: '30 min',
      referencePrice: 20,
    ),
    LabExamDefinition(
      id: 'micro-blood-culture',
      name: 'Hemocultivo (2 frascos)',
      sampleType: LabSampleType.microbiology,
      preparation: 'Antes de antibióticos. Desinfección estricta del sitio.',
      turnaround: '3–5 días',
      referencePrice: 45,
    ),
    LabExamDefinition(
      id: 'micro-wound',
      name: 'Cultivo de herida / secreción',
      sampleType: LabSampleType.microbiology,
      preparation: 'Muestra tomada antes de antibióticos si es posible.',
      turnaround: '48–72 h',
      referencePrice: 30,
    ),

    // —— Marcadores tumorales ——
    LabExamDefinition(
      id: 'tumor-cea',
      name: 'CEA (antígeno carcinoembrionario)',
      sampleType: LabSampleType.tumorMarkers,
      preparation: 'No fumar 24 h antes. Ayunas no obligatorias.',
      turnaround: '48 h',
      referencePrice: 28,
    ),
    LabExamDefinition(
      id: 'tumor-ca125',
      name: 'CA-125',
      sampleType: LabSampleType.tumorMarkers,
      preparation: 'Indicar fase del ciclo en mujeres.',
      turnaround: '48 h',
      referencePrice: 32,
    ),
    LabExamDefinition(
      id: 'tumor-ca199',
      name: 'CA 19-9',
      sampleType: LabSampleType.tumorMarkers,
      preparation: 'Ayunas de 8 h recomendadas.',
      turnaround: '48 h',
      referencePrice: 32,
    ),
    LabExamDefinition(
      id: 'tumor-afp',
      name: 'AFP (alfafetoproteína)',
      sampleType: LabSampleType.tumorMarkers,
      preparation: 'No requiere ayunas.',
      turnaround: '48 h',
      referencePrice: 28,
    ),

    // —— Coagulación ——
    LabExamDefinition(
      id: 'coag-pt-inr',
      name: 'TP / INR (tiempo de protrombina)',
      sampleType: LabSampleType.coagulation,
      preparation: 'Informar anticoagulantes. Horario consistente si toma warfarina.',
      turnaround: '2–4 h',
      referencePrice: 12,
    ),
    LabExamDefinition(
      id: 'coag-ptt',
      name: 'TTPa / PTT',
      sampleType: LabSampleType.coagulation,
      preparation: 'Informar heparina u otros anticoagulantes.',
      turnaround: '2–4 h',
      referencePrice: 14,
    ),
    LabExamDefinition(
      id: 'coag-dimer',
      name: 'Dímero D',
      sampleType: LabSampleType.coagulation,
      preparation: 'Sin ayunas.',
      turnaround: '4–24 h',
      referencePrice: 35,
    ),
    LabExamDefinition(
      id: 'coag-fibrinogen',
      name: 'Fibrinógeno',
      sampleType: LabSampleType.coagulation,
      preparation: 'Sin preparación especial.',
      turnaround: '24 h',
      referencePrice: 22,
    ),

    // —— Inmunología ——
    LabExamDefinition(
      id: 'immuno-crp',
      name: 'Proteína C reactiva (PCR)',
      sampleType: LabSampleType.immunology,
      preparation: 'Sin ayunas.',
      turnaround: '4 h',
      referencePrice: 14,
    ),
    LabExamDefinition(
      id: 'immuno-esr',
      name: 'Velocidad de sedimentación (VSG)',
      sampleType: LabSampleType.immunology,
      preparation: 'Sin ayunas.',
      turnaround: '2 h',
      referencePrice: 8,
    ),
    LabExamDefinition(
      id: 'immuno-ana',
      name: 'ANA (anticuerpos antinucleares)',
      sampleType: LabSampleType.immunology,
      preparation: 'Sin ayunas.',
      turnaround: '48–72 h',
      referencePrice: 38,
    ),
    LabExamDefinition(
      id: 'immuno-rf',
      name: 'Factor reumatoide',
      sampleType: LabSampleType.immunology,
      preparation: 'Sin ayunas.',
      turnaround: '24 h',
      referencePrice: 18,
    ),
    LabExamDefinition(
      id: 'allergy-ige-panel',
      name: 'Panel de alergias (IgE específicas)',
      sampleType: LabSampleType.immunology,
      preparation: 'Suspender antihistamínicos 5–7 días si el médico lo indica.',
      turnaround: '5–7 días',
      referencePrice: 80,
    ),

    // —— Genética ——
    LabExamDefinition(
      id: 'gen-karyotype',
      name: 'Cariotipo',
      sampleType: LabSampleType.genetics,
      preparation: 'Muestra de sangre. Consentimiento informado.',
      turnaround: '15–20 días',
      referencePrice: 120,
    ),
    LabExamDefinition(
      id: 'gen-nipt',
      name: 'ADN fetal libre (NIPT)',
      sampleType: LabSampleType.genetics,
      preparation: 'Gestación ≥10 semanas. Consentimiento informado.',
      turnaround: '7–10 días',
      referencePrice: 350,
    ),

    // —— Otros ——
    LabExamDefinition(
      id: 'other-vitals-labs',
      name: 'Gases arteriales (ABG)',
      sampleType: LabSampleType.other,
      preparation: 'Muestra arterial en laboratorio. Sin ayunas.',
      turnaround: '30 min',
      referencePrice: 35,
    ),
    LabExamDefinition(
      id: 'other-lactate',
      name: 'Lactato sérico',
      sampleType: LabSampleType.other,
      preparation: 'Sin torniquete prolongado. Procesar de inmediato.',
      turnaround: '1 h',
      referencePrice: 25,
    ),
  ];

  static List<LabExamDefinition> bySampleType(LabSampleType type) {
    return all.where((e) => e.sampleType == type).toList();
  }

  static LabExamDefinition? findById(String id) {
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  static Map<LabSampleType, List<LabExamDefinition>> get groupedBySampleType {
    final map = <LabSampleType, List<LabExamDefinition>>{};
    for (final type in LabSampleType.values) {
      final items = bySampleType(type);
      if (items.isNotEmpty) map[type] = items;
    }
    return map;
  }

  static int countForType(LabSampleType type) => bySampleType(type).length;
}
