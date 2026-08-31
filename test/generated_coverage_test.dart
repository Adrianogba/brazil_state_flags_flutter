// GENERATED FILE. DO NOT EDIT BY HAND.
//
// Produced by tool/generate_flags.dart. Proves that every
// drawing in the source set is reachable from the public API.

import 'package:brazil_state_flags/brazil_state_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FlagsFull exposes all 31 drawings', () {
    const flags = <String, FlagArtwork>{
      'brazil': FlagsFull.brazil,
      'acre': FlagsFull.acre,
      'alagoas': FlagsFull.alagoas,
      'amapa': FlagsFull.amapa,
      'amazonas': FlagsFull.amazonas,
      'bahia': FlagsFull.bahia,
      'ceara': FlagsFull.ceara,
      'cearaSimplified': FlagsFull.cearaSimplified,
      'distritoFederal': FlagsFull.distritoFederal,
      'espiritoSantoSimplified': FlagsFull.espiritoSantoSimplified,
      'espiritoSanto': FlagsFull.espiritoSanto,
      'goias': FlagsFull.goias,
      'maranhao': FlagsFull.maranhao,
      'matoGrosso': FlagsFull.matoGrosso,
      'matoGrossoDoSul': FlagsFull.matoGrossoDoSul,
      'minasGerais': FlagsFull.minasGerais,
      'para': FlagsFull.para,
      'paraiba': FlagsFull.paraiba,
      'paraibaSimplified': FlagsFull.paraibaSimplified,
      'parana': FlagsFull.parana,
      'pernambuco': FlagsFull.pernambuco,
      'piaui': FlagsFull.piaui,
      'rioDeJaneiro': FlagsFull.rioDeJaneiro,
      'rioGrandeDoNorte': FlagsFull.rioGrandeDoNorte,
      'rioGrandeDoSul': FlagsFull.rioGrandeDoSul,
      'rondonia': FlagsFull.rondonia,
      'roraima': FlagsFull.roraima,
      'santaCatarina': FlagsFull.santaCatarina,
      'saoPaulo': FlagsFull.saoPaulo,
      'sergipe': FlagsFull.sergipe,
      'tocantins': FlagsFull.tocantins,
    };
    expect(flags, hasLength(31));
    for (final entry in flags.entries) {
      expect(entry.value.shapes, isNotEmpty, reason: entry.key);
      expect(entry.value.width, 300.0, reason: entry.key);
      expect(entry.value.height, 200.0, reason: entry.key);
    }
  });

  test('FlagsRounded exposes all 31 drawings', () {
    const flags = <String, FlagArtwork>{
      'brazil': FlagsRounded.brazil,
      'acre': FlagsRounded.acre,
      'alagoas': FlagsRounded.alagoas,
      'amapa': FlagsRounded.amapa,
      'amazonas': FlagsRounded.amazonas,
      'bahia': FlagsRounded.bahia,
      'ceara': FlagsRounded.ceara,
      'cearaSimplified': FlagsRounded.cearaSimplified,
      'distritoFederal': FlagsRounded.distritoFederal,
      'espiritoSantoSimplified': FlagsRounded.espiritoSantoSimplified,
      'espiritoSanto': FlagsRounded.espiritoSanto,
      'goias': FlagsRounded.goias,
      'maranhao': FlagsRounded.maranhao,
      'matoGrosso': FlagsRounded.matoGrosso,
      'matoGrossoDoSul': FlagsRounded.matoGrossoDoSul,
      'minasGerais': FlagsRounded.minasGerais,
      'para': FlagsRounded.para,
      'paraiba': FlagsRounded.paraiba,
      'paraibaSimplified': FlagsRounded.paraibaSimplified,
      'parana': FlagsRounded.parana,
      'pernambuco': FlagsRounded.pernambuco,
      'piaui': FlagsRounded.piaui,
      'rioDeJaneiro': FlagsRounded.rioDeJaneiro,
      'rioGrandeDoNorte': FlagsRounded.rioGrandeDoNorte,
      'rioGrandeDoSul': FlagsRounded.rioGrandeDoSul,
      'rondonia': FlagsRounded.rondonia,
      'roraima': FlagsRounded.roraima,
      'santaCatarina': FlagsRounded.santaCatarina,
      'saoPaulo': FlagsRounded.saoPaulo,
      'sergipe': FlagsRounded.sergipe,
      'tocantins': FlagsRounded.tocantins,
    };
    expect(flags, hasLength(31));
    for (final entry in flags.entries) {
      expect(entry.value.shapes, isNotEmpty, reason: entry.key);
      expect(entry.value.width, 300.0, reason: entry.key);
      expect(entry.value.height, 200.0, reason: entry.key);
    }
  });

  test('FlagsSquareRounded exposes all 31 drawings', () {
    const flags = <String, FlagArtwork>{
      'brazil': FlagsSquareRounded.brazil,
      'acre': FlagsSquareRounded.acre,
      'alagoas': FlagsSquareRounded.alagoas,
      'amapa': FlagsSquareRounded.amapa,
      'amazonas': FlagsSquareRounded.amazonas,
      'bahia': FlagsSquareRounded.bahia,
      'ceara': FlagsSquareRounded.ceara,
      'cearaSimplified': FlagsSquareRounded.cearaSimplified,
      'distritoFederal': FlagsSquareRounded.distritoFederal,
      'espiritoSantoSimplified': FlagsSquareRounded.espiritoSantoSimplified,
      'espiritoSanto': FlagsSquareRounded.espiritoSanto,
      'goias': FlagsSquareRounded.goias,
      'maranhao': FlagsSquareRounded.maranhao,
      'matoGrosso': FlagsSquareRounded.matoGrosso,
      'matoGrossoDoSul': FlagsSquareRounded.matoGrossoDoSul,
      'minasGerais': FlagsSquareRounded.minasGerais,
      'para': FlagsSquareRounded.para,
      'paraiba': FlagsSquareRounded.paraiba,
      'paraibaSimplified': FlagsSquareRounded.paraibaSimplified,
      'parana': FlagsSquareRounded.parana,
      'pernambuco': FlagsSquareRounded.pernambuco,
      'piaui': FlagsSquareRounded.piaui,
      'rioDeJaneiro': FlagsSquareRounded.rioDeJaneiro,
      'rioGrandeDoNorte': FlagsSquareRounded.rioGrandeDoNorte,
      'rioGrandeDoSul': FlagsSquareRounded.rioGrandeDoSul,
      'rondonia': FlagsSquareRounded.rondonia,
      'roraima': FlagsSquareRounded.roraima,
      'santaCatarina': FlagsSquareRounded.santaCatarina,
      'saoPaulo': FlagsSquareRounded.saoPaulo,
      'sergipe': FlagsSquareRounded.sergipe,
      'tocantins': FlagsSquareRounded.tocantins,
    };
    expect(flags, hasLength(31));
    for (final entry in flags.entries) {
      expect(entry.value.shapes, isNotEmpty, reason: entry.key);
      expect(entry.value.width, 200.0, reason: entry.key);
      expect(entry.value.height, 200.0, reason: entry.key);
    }
  });

  test('FlagsCircle exposes all 31 drawings', () {
    const flags = <String, FlagArtwork>{
      'brazil': FlagsCircle.brazil,
      'acre': FlagsCircle.acre,
      'alagoas': FlagsCircle.alagoas,
      'amapa': FlagsCircle.amapa,
      'amazonas': FlagsCircle.amazonas,
      'bahia': FlagsCircle.bahia,
      'ceara': FlagsCircle.ceara,
      'cearaSimplified': FlagsCircle.cearaSimplified,
      'distritoFederal': FlagsCircle.distritoFederal,
      'espiritoSantoSimplified': FlagsCircle.espiritoSantoSimplified,
      'espiritoSanto': FlagsCircle.espiritoSanto,
      'goias': FlagsCircle.goias,
      'maranhao': FlagsCircle.maranhao,
      'matoGrosso': FlagsCircle.matoGrosso,
      'matoGrossoDoSul': FlagsCircle.matoGrossoDoSul,
      'minasGerais': FlagsCircle.minasGerais,
      'para': FlagsCircle.para,
      'paraiba': FlagsCircle.paraiba,
      'paraibaSimplified': FlagsCircle.paraibaSimplified,
      'parana': FlagsCircle.parana,
      'pernambuco': FlagsCircle.pernambuco,
      'piaui': FlagsCircle.piaui,
      'rioDeJaneiro': FlagsCircle.rioDeJaneiro,
      'rioGrandeDoNorte': FlagsCircle.rioGrandeDoNorte,
      'rioGrandeDoSul': FlagsCircle.rioGrandeDoSul,
      'rondonia': FlagsCircle.rondonia,
      'roraima': FlagsCircle.roraima,
      'santaCatarina': FlagsCircle.santaCatarina,
      'saoPaulo': FlagsCircle.saoPaulo,
      'sergipe': FlagsCircle.sergipe,
      'tocantins': FlagsCircle.tocantins,
    };
    expect(flags, hasLength(31));
    for (final entry in flags.entries) {
      expect(entry.value.shapes, isNotEmpty, reason: entry.key);
      expect(entry.value.width, 200.0, reason: entry.key);
      expect(entry.value.height, 200.0, reason: entry.key);
    }
  });
}
