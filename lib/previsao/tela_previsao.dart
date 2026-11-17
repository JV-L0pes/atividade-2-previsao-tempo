import 'package:flutter/material.dart';

import 'cache.dart';
import 'cptec.dart';
import 'modelos.dart';
import 'widgets.dart';

class TelaPrevisao extends StatefulWidget {
  const TelaPrevisao({
    super.key,
    required this.cidade,
    required this.cliente,
    required this.cache,
  });

  final Cidade cidade;
  final ClienteCptec cliente;
  final CacheConsulta cache;

  @override
  State<TelaPrevisao> createState() => _TelaPrevisaoState();
}

class _TelaPrevisaoState extends State<TelaPrevisao> {
  PrevisaoCidade? _previsao;
  bool _carregando = false;
  bool _deCache = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final previsao = await widget.cliente.previsao(widget.cidade.id);
      if (!mounted) return;
      setState(() {
        _previsao = previsao;
        _deCache = false;
        _carregando = false;
      });
      if (previsao.dias.isNotEmpty) {
        await widget.cache.salvar(widget.cidade, previsao);
      }
    } on FalhaConexao {
      await _usarCacheOuFalhar('Sem conexão com o CPTEC/INPE.');
    } on RespostaInvalida {
      await _usarCacheOuFalhar(
        'O CPTEC/INPE respondeu em um formato inesperado.',
      );
    }
  }

  Future<void> _usarCacheOuFalhar(String mensagem) async {
    final salva = await widget.cache.ler();
    if (!mounted) return;

    final mesmaCidade =
        salva != null &&
        salva.cidade.id == widget.cidade.id &&
        salva.previsao.dias.isNotEmpty;

    if (mesmaCidade) {
      setState(() {
        _previsao = salva.previsao;
        _deCache = true;
        _carregando = false;
      });
      return;
    }

    setState(() {
      _carregando = false;
      _erro = _previsao == null ? mensagem : null;
    });

    if (_previsao != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível atualizar. $mensagem')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cidade.nome} — ${widget.cidade.uf}'),
        actions: [
          IconButton(
            onPressed: _carregando ? null : _carregar,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    final previsao = _previsao;
    if (_carregando && previsao == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (previsao == null) {
      return Aviso(
        icone: Icons.cloud_off,
        texto: _erro ?? 'Nenhuma previsão disponível para esta cidade.',
        aoTentarNovamente: _carregar,
      );
    }

    final atualizacao = previsao.atualizacao;
    final tema = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (_carregando) const LinearProgressIndicator(),
          if (_deCache && atualizacao != null)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: tema.colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.wifi_off),
                title: const Text('Sem conexão'),
                subtitle: Text(
                  'Exibindo dados atualizados em ${dataNumerica(atualizacao)}.',
                ),
              ),
            ),
          if (previsao.dias.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Nenhuma previsão disponível para esta cidade.',
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            GraficoTemperaturas(dias: previsao.dias),
            for (final dia in previsao.dias) CardDia(dia: dia),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              atualizacao == null
                  ? 'Fonte: CPTEC/INPE'
                  : 'Fonte: CPTEC/INPE · atualizado em '
                        '${dataNumerica(atualizacao)}',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
