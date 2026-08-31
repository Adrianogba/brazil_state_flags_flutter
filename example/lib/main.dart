import 'package:brazil_state_flags/brazil_state_flags.dart';
import 'package:brazil_state_flags/lookup.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'brazil_state_flags',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF009B43),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF009B43),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FlagStyle _style = FlagStyle.circle;
  String _pickedUf = 'SP';

  static const _styleLabels = {
    FlagStyle.full: 'Full',
    FlagStyle.rounded: 'Rounded',
    FlagStyle.squareRounded: 'Square',
    FlagStyle.circle: 'Circle',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandeiras dos Estados'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SectionTitle('Estilo / Style'),
          const SizedBox(height: 8),
          SegmentedButton<FlagStyle>(
            segments: [
              for (final style in FlagStyle.values)
                ButtonSegment(value: style, label: Text(_styleLabels[style]!)),
            ],
            selected: {_style},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _style = s.first),
          ),
          const SizedBox(height: 28),

          _SectionTitle('Busca por UF / Lookup by UF'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  BrazilStateFlag(
                    flagForUf(_pickedUf, style: _style)!,
                    size: 64,
                    semanticLabel: 'Bandeira de ${stateNameForUf(_pickedUf)}',
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _pickedUf,
                      decoration: const InputDecoration(
                        labelText: 'UF',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final state in brazilStates)
                          DropdownMenuItem(
                            value: state.uf,
                            child: Text('${state.uf}  ${state.name}'),
                          ),
                      ],
                      onChanged: (v) =>
                          setState(() => _pickedUf = v ?? _pickedUf),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          _SectionTitle('Qualquer tamanho / Any size'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final size in [16.0, 24.0, 32.0, 48.0, 72.0, 112.0])
                    BrazilStateFlag(
                      flagForUf('SP', style: _style)!,
                      size: size,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          _SectionTitle('Todos os 28 / All 28'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: brazilStates.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 110,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, i) {
              final state = brazilStates[i];
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BrazilStateFlag(
                    state.flag(_style),
                    size: 56,
                    semanticLabel: 'Bandeira de ${state.name}',
                  ),
                  const SizedBox(height: 8),
                  Text(state.uf, style: theme.textTheme.labelLarge),
                  Text(
                    state.name,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          _SectionTitle('Variantes / Variants'),
          const SizedBox(height: 4),
          Text(
            'Três estados têm um desenho alternativo. '
            'Three states ship an alternative drawing.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Variant('Paraíba', FlagsCircle.paraiba),
                  _Variant(
                    'Paraíba\nsimplified',
                    FlagsCircle.paraibaSimplified,
                  ),
                  _Variant('Ceará', FlagsCircle.ceara),
                  _Variant('Ceará\nsimplified', FlagsCircle.cearaSimplified),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w600),
  );
}

class _Variant extends StatelessWidget {
  const _Variant(this.label, this.artwork);
  final String label;
  final FlagArtwork artwork;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      BrazilStateFlag(artwork, size: 52),
      const SizedBox(height: 8),
      Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}
