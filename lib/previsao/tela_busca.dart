import 'package:flutter/material.dart';

import 'cache.dart';
import 'cptec.dart';
import 'modelos.dart';
import 'tela_previsao.dart';
import 'widgets.dart';

const _acentos = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
};

String semAcento(String texto) {
  final buffer = StringBuffer();
  for (final caractere in texto.toLowerCase().split('')) {
    buffer.write(_acentos[caractere] ?? caractere);
  }
  return buffer.toString();
}

class TelaBusca extends StatefulWidget {
  const TelaBusca({super.key, required this.cliente, required this.cache});

  final ClienteCptec cliente;
  final CacheConsulta cache;

  @override
  State<TelaBusca> createState() => _TelaBuscaState();
}

class _TelaBuscaState extends State<TelaBusca> {
  final _controlador = TextEditingController();

  bool _carregando = false;
  String? _erro;
  String _termo = '';
  List<Cidade>? _resultados;
  ConsultaSalva? _ultimaConsulta;

  @override
  void initState() {
    super.initState();
    _carregarUltimaConsulta();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _carregarUltimaConsulta() async {
    final salva = await widget.cache.ler();
    if (!mounted) return;
    setState(() => _ultimaConsulta = salva);
  }

  Future<void> _buscar() async {
    final termo = _controlador.text.trim();
    if (termo.length < 2) {
      setState(() {
        _erro = 'Digite pelo menos 2 letras do nome da cidade.';
        _resultados = null;
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
      _termo = termo;
    });

    try {
      final cidades = await widget.cliente.buscarCidades(semAcento(termo));
      if (!mounted) return;
      setState(() {
        _resultados = cidades;
        _carregando = false;
      });
    } on FalhaConexao {
      _falhar(
        'Sem conexão com o CPTEC/INPE. Verifique a internet e tente de novo.',
      );
    } on RespostaInvalida {
      _falhar('O CPTEC/INPE respondeu em um formato inesperado.');
    }
  }

  void _falhar(String mensagem) {
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _erro = mensagem;
      _resultados = null;
    });
  }

  Future<void> _abrir(Cidade cidade) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelaPrevisao(
          cidade: cidade,
          cliente: widget.cliente,
          cache: widget.cache,
        ),
      ),
    );
    if (!mounted) return;
    await _carregarUltimaConsulta();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Previsão do tempo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controlador,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _buscar(),
              decoration: InputDecoration(
                labelText: 'Cidade',
                hintText: 'Ex.: São Paulo',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _carregando ? null : _buscar,
                  tooltip: 'Pesquisar',
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            if (_carregando) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 12),
            Expanded(child: _conteudo(tema)),
            const Divider(),
            Text(
              'Fonte: CPTEC/INPE',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudo(ThemeData tema) {
    final erro = _erro;
    if (erro != null) {
      return Aviso(
        icone: Icons.cloud_off,
        texto: erro,
        aoTentarNovamente: _buscar,
      );
    }

    final resultados = _resultados;
    if (resultados == null) {
      final ultima = _ultimaConsulta;
      return ListView(
        children: [
          if (ultima != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Última consulta'),
                subtitle: Text('${ultima.cidade.nome} — ${ultima.cidade.uf}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _abrir(ultima.cidade),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'Pesquise uma cidade para ver a previsão dos próximos 4 dias.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    if (resultados.isEmpty) {
      return Aviso(
        icone: Icons.search_off,
        texto: 'Nenhuma cidade encontrada para «$_termo».',
      );
    }

    return ListView.separated(
      itemCount: resultados.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, indice) {
        final cidade = resultados[indice];
        return ListTile(
          leading: const Icon(Icons.location_city),
          title: Text(cidade.nome),
          subtitle: Text(cidade.uf),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _abrir(cidade),
        );
      },
    );
  }
}
