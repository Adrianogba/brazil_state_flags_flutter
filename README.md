<h1 align="center">brazil_state_flags</h1>

<p align="center">
  Bandeiras dos 26 estados brasileiros, do Distrito Federal e do Brasil.<br>
  Nítidas em qualquer tamanho, em puro dart, compatível com qualquer sistema.
</p>

<p align="center">
  <a href="https://pub.dev/packages/brazil_state_flags"><img src="https://img.shields.io/pub/v/brazil_state_flags.svg?logo=dart&color=0175C2" alt="pub package"></a>
  <a href="https://pub.dev/packages/brazil_state_flags/score"><img src="https://img.shields.io/pub/points/brazil_state_flags?logo=dart&color=0175C2" alt="pub points"></a>
  <a href="https://pub.dev/packages/brazil_state_flags"><img src="https://img.shields.io/badge/platforms-all%206-42A5F5?logo=flutter" alt="platforms"></a>
  <a href="https://github.com/Adrianogba/brazil_state_flags_flutter/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="license"></a>
</p>

<p align="center">
  <b>Português</b> · <a href="#english">English</a>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/Adrianogba/brazil_state_flags_flutter/main/screenshots/all_flags_circle.png" width="300" alt="Todas as bandeiras no estilo circle">
  <img src="https://raw.githubusercontent.com/Adrianogba/brazil_state_flags_flutter/main/screenshots/styles_full.png" width="300" alt="Estilo full">
</p>

## O que você recebe

- **28 bandeiras** em **4 estilos**: `full` (3:2), `rounded` (3:2 com cantos arredondados), `square-rounded` e `circle`.
- **Zero assets e zero dependências a mais.** Cada bandeira é um `Path` vetorial compilado em Dart.
- **Tree shaking.** O Flutter não remove assets não usados, mas remove constantes não usadas. Um app que cita uma bandeira leva **4,9 KB** do pacote, medido com `flutter build apk --analyze-size`, e não os cerca de 500 KB de dados de todas as 124.
- Nítidas em qualquer tamanho, de 16 px a tela cheia.
- Suporte a leitores de tela usando `semanticLabel`.

## Instalação

```bash
flutter pub add brazil_state_flags
```

## Uso

```dart
import 'package:brazil_state_flags/brazil_state_flags.dart';

// Escolha o estilo, depois o estado.
BrazilStateFlag(FlagsCircle.saoPaulo, size: 48)
BrazilStateFlag(FlagsFull.rioDeJaneiro, width: 120)
BrazilStateFlag(FlagsSquareRounded.bahia, size: 32)

// Siglas de UF funcionam como atalho.
BrazilStateFlag(FlagsCircle.sp, size: 24)
BrazilStateFlag(FlagsCircle.mg, size: 24)
```

As quatro coleções são `FlagsFull`, `FlagsRounded`, `FlagsSquareRounded` e
`FlagsCircle`.

### Tamanho

Passe `size`, `width`, `height`, ou uma combinação. O que faltar é calculado a
partir da proporção da arte, então a bandeira nunca é esticada.

```dart
BrazilStateFlag(FlagsFull.parana, width: 150)   // vira 150 x 100
BrazilStateFlag(FlagsCircle.parana, size: 64)   // vira 64 x 64
```

### Busca por UF

Formulários de endereço precisam escolher a bandeira a partir de uma string.
Isso mora em um import separado:

```dart
import 'package:brazil_state_flags/lookup.dart';

final bandeira = flagForUf('sp', style: FlagStyle.circle);
if (bandeira != null) BrazilStateFlag(bandeira, size: 32);

// Montando um dropdown:
for (final estado in brazilStates) {
  print('${estado.uf} ${estado.name}');
}
```

O import é separado de propósito. As tabelas de busca citam todas as bandeiras
de um estilo, então importar `lookup.dart` faz o app carregar as 28. Vale a pena
quando você realmente precisa resolver uma sigla em tempo de execução, e não
vale quando você só quer duas ou três bandeiras fixas.

### Variantes

Três estados têm dois desenhos no conjunto original. Eles não seguem um eixo
único de "detalhado" e "simples", então cada um é exposto pelo que realmente é:

| Padrão | Alternativa | Diferença |
|---|---|---|
| `paraiba` | `paraibaSimplified` | a versão simplificada não traz a palavra NEGO |
| `ceara` | `cearaSimplified` | a versão simplificada não traz o brasão |
| `espiritoSanto` | `espiritoSantoSimplified` | a padrão traz o lema TRABALHA E CONFIA |

### Acessibilidade

```dart
BrazilStateFlag(
  FlagsCircle.bahia,
  size: 40,
  semanticLabel: 'Bandeira da Bahia',
)
```

Sem `semanticLabel` a bandeira é tratada como decorativa, que costuma ser o
certo quando já existe um texto ao lado.

## Requisitos

| Requisito | Mínimo |
|---|---|
| Flutter | 3.27.0 |
| Dart | 3.6.0 |

## Plataformas

| Android | iOS | Web | macOS | Windows | Linux |
|:---:|:---:|:---:|:---:|:---:|:---:|
| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## Créditos

A arte vem de
[icones-bandeiras-br-uf](https://github.com/pierrelapalu/icones-bandeiras-br-uf),
de Pierre Lapalu, publicada sob CC0 1.0. Os SVGs foram convertidos em código
Dart por `tool/generate_flags.dart`, incluído no repositório.

---

<h2 id="english">English</h2>

Flags of the 26 Brazilian states, the Federal District and Brazil, drawn as
vectors in pure Dart. No assets, no dependencies, sharp at any size.

### What you get

- **28 flags** in **4 styles**: `full` (3:2), `rounded` (3:2 with rounded corners), `square-rounded` and `circle`.
- **Zero assets and zero dependencies.** Each flag is a vector `Path` compiled into Dart.
- **Tree shaking that actually works.** Flutter does not drop unused assets, but it does drop unused constants. An app that names one flag pulls in **4.9 KB** of this package, measured with `flutter build apk --analyze-size`, not the roughly 500 KB of data behind all 124 drawings.
- Sharp at any size, from 16 px to full screen.
- Screen reader support through `semanticLabel`.

### Install

```bash
flutter pub add brazil_state_flags
```

### Usage

```dart
import 'package:brazil_state_flags/brazil_state_flags.dart';

// Pick the style, then the state.
BrazilStateFlag(FlagsCircle.saoPaulo, size: 48)
BrazilStateFlag(FlagsFull.rioDeJaneiro, width: 120)
BrazilStateFlag(FlagsSquareRounded.bahia, size: 32)

// UF codes work as a shorthand.
BrazilStateFlag(FlagsCircle.sp, size: 24)
```

The four collections are `FlagsFull`, `FlagsRounded`, `FlagsSquareRounded` and
`FlagsCircle`.

### Sizing

Pass `size`, `width`, `height`, or a combination. Whatever you leave out is
worked out from the artwork's proportions, so the flag is never stretched.

```dart
BrazilStateFlag(FlagsFull.parana, width: 150)   // becomes 150 x 100
BrazilStateFlag(FlagsCircle.parana, size: 64)   // becomes 64 x 64
```

### Lookup by UF

Address forms need to pick a flag from a string. That lives in a separate
import:

```dart
import 'package:brazil_state_flags/lookup.dart';

final flag = flagForUf('sp', style: FlagStyle.circle);
if (flag != null) BrazilStateFlag(flag, size: 32);

// Building a picker:
for (final state in brazilStates) {
  print('${state.uf} ${state.name}');
}
```

The separate import is deliberate. The lookup tables name every flag in a
style, so importing `lookup.dart` means your app carries all 28. That is the
right trade when you genuinely need to resolve a code at runtime, and the wrong
one when you just want two or three fixed flags.

### Variants

Three states ship two drawings in the source set. They do not follow a single
"detailed versus simple" axis, so each is exposed for what it actually is:

| Default | Alternative | Difference |
|---|---|---|
| `paraiba` | `paraibaSimplified` | the simplified one drops the word NEGO |
| `ceara` | `cearaSimplified` | the simplified one drops the coat of arms |
| `espiritoSanto` | `espiritoSantoSimplified` | the default carries the TRABALHA E CONFIA motto |

### Accessibility

```dart
BrazilStateFlag(
  FlagsCircle.bahia,
  size: 40,
  semanticLabel: 'Bandeira da Bahia',
)
```

With no `semanticLabel` the flag is treated as decorative, which is usually
right when a label already sits next to it.

### Credits

Artwork from
[icones-bandeiras-br-uf](https://github.com/pierrelapalu/icones-bandeiras-br-uf)
by Pierre Lapalu, released under CC0 1.0. The SVGs are converted to Dart source
by `tool/generate_flags.dart`, which is included in the repository.

## License

MIT. See [LICENSE](https://github.com/Adrianogba/brazil_state_flags_flutter/blob/main/LICENSE).
