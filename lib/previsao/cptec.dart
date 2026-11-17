import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'modelos.dart';

/// Rede fora, timeout ou status diferente de 200.
class FalhaConexao implements Exception {
  const FalhaConexao();
}

/// Resposta recebida, mas fora do formato documentado pelo CPTEC/INPE.
class RespostaInvalida implements Exception {
  const RespostaInvalida();
}

class ClienteCptec {
  ClienteCptec({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _base = 'http://servicos.cptec.inpe.br/XML';
  static const _limite = Duration(seconds: 15);

  Future<List<Cidade>> buscarCidades(String termo) async {
    final uri = Uri.parse(
      '$_base/listaCidades?city=${Uri.encodeComponent(termo)}',
    );
    final raiz = _parsear(await _baixar(uri)).rootElement;
    if (raiz.name.local != 'cidades') throw const RespostaInvalida();

    return [
      for (final elemento in raiz.findElements('cidade')) ?_cidade(elemento),
    ];
  }

  Future<PrevisaoCidade> previsao(int codigo) async {
    final raiz = _parsear(
      await _baixar(Uri.parse('$_base/cidade/$codigo/previsao.xml')),
    ).rootElement;
    if (raiz.name.local != 'cidade') throw const RespostaInvalida();

    return PrevisaoCidade(
      nome: _texto(raiz, 'nome'),
      uf: _texto(raiz, 'uf'),
      atualizacao: DateTime.tryParse(_texto(raiz, 'atualizacao')),
      dias: [
        for (final elemento in raiz.findElements('previsao')) ?_dia(elemento),
      ],
    );
  }

  Future<String> _baixar(Uri uri) async {
    final http.Response resposta;
    try {
      resposta = await _http.get(uri).timeout(_limite);
    } on Exception {
      throw const FalhaConexao();
    }
    if (resposta.statusCode != 200) throw const FalhaConexao();
    try {
      return latin1.decode(resposta.bodyBytes);
    } on FormatException {
      throw const RespostaInvalida();
    }
  }

  XmlDocument _parsear(String xml) {
    try {
      return XmlDocument.parse(xml);
    } on Exception {
      throw const RespostaInvalida();
    }
  }

  Cidade? _cidade(XmlElement elemento) {
    final id = int.tryParse(_texto(elemento, 'id'));
    final nome = _texto(elemento, 'nome');
    if (id == null || nome.isEmpty) return null;
    return Cidade(id: id, nome: nome, uf: _texto(elemento, 'uf'));
  }

  PrevisaoDia? _dia(XmlElement elemento) {
    final dia = DateTime.tryParse(_texto(elemento, 'dia'));
    if (dia == null) return null;
    return PrevisaoDia(
      dia: dia,
      sigla: _texto(elemento, 'tempo'),
      minima: int.tryParse(_texto(elemento, 'minima')),
      maxima: int.tryParse(_texto(elemento, 'maxima')),
      iuv: double.tryParse(_texto(elemento, 'iuv').replaceAll(',', '.')),
    );
  }

  String _texto(XmlElement elemento, String tag) =>
      elemento.getElement(tag)?.innerText.trim() ?? '';
}
