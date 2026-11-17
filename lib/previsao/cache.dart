import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'modelos.dart';

/// Última cidade consultada e a previsão que o serviço devolveu para ela.
class ConsultaSalva {
  const ConsultaSalva({required this.cidade, required this.previsao});

  final Cidade cidade;
  final PrevisaoCidade previsao;
}

/// Cache da última consulta, em SharedPreferences, para abrir o app sem rede.
class CacheConsulta {
  static const _chave = 'ultima_consulta';

  Future<ConsultaSalva?> ler() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chave);
    if (texto == null) return null;

    try {
      final json = jsonDecode(texto);
      if (json is! Map) return null;
      final cidade = Cidade.fromJson(json['cidade']);
      final previsao = PrevisaoCidade.fromJson(json['previsao']);
      if (cidade == null || previsao == null || previsao.dias.isEmpty) {
        return null;
      }
      return ConsultaSalva(cidade: cidade, previsao: previsao);
    } on FormatException {
      return null;
    }
  }

  Future<void> salvar(Cidade cidade, PrevisaoCidade previsao) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chave,
      jsonEncode({'cidade': cidade.toJson(), 'previsao': previsao.toJson()}),
    );
  }
}
