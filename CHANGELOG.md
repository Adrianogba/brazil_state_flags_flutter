# Changelog

Este projeto segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/)
e [Semantic Versioning](https://semver.org/lang/pt-BR/).

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and [Semantic Versioning](https://semver.org/).

## 1.0.0

Primeira versão. / First release.

### Adicionado / Added

**Português**

- 28 bandeiras (26 estados, Distrito Federal e Brasil) em 4 estilos: `full`,
  `rounded`, `square-rounded` e `circle`.
- Coleções `FlagsFull`, `FlagsRounded`, `FlagsSquareRounded` e `FlagsCircle`,
  cada bandeira exposta como uma constante independente para permitir tree
  shaking.
- Atalhos por sigla de UF em cada coleção, por exemplo `FlagsCircle.sp`.
- Widget `BrazilStateFlag`, com `size`, `width`, `height` e `semanticLabel`.
- Busca em tempo de execução em `package:brazil_state_flags/lookup.dart`, com
  `flagForUf`, `stateNameForUf`, `brazilStates` e `brazilStateNames`.
- Variantes alternativas para Paraíba, Ceará e Espírito Santo.
- `parseFlagPath` exposto para quem quiser desenhar as bandeiras em um
  `CustomPainter` próprio.
- Sem assets e sem dependências além do Flutter.

**English**

- 28 flags (26 states, the Federal District and Brazil) in 4 styles: `full`,
  `rounded`, `square-rounded` and `circle`.
- `FlagsFull`, `FlagsRounded`, `FlagsSquareRounded` and `FlagsCircle`
  collections, with each flag exposed as an independent constant so unused ones
  are tree shaken away.
- UF code shorthands on every collection, for example `FlagsCircle.sp`.
- `BrazilStateFlag` widget, taking `size`, `width`, `height` and
  `semanticLabel`.
- Runtime lookup in `package:brazil_state_flags/lookup.dart`, providing
  `flagForUf`, `stateNameForUf`, `brazilStates` and `brazilStateNames`.
- Alternative variants for Paraíba, Ceará and Espírito Santo.
- `parseFlagPath` exported for anyone wanting to draw the flags in their own
  `CustomPainter`.
- No assets and no dependencies beyond Flutter.
