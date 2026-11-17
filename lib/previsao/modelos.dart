/// Modelos da resposta do CPTEC/INPE, com leitura tolerante a campos ausentes.
library;

class Cidade {
  const Cidade({required this.id, required this.nome, required this.uf});

  final int id;
  final String nome;
  final String uf;

  Map<String, Object?> toJson() => {'id': id, 'nome': nome, 'uf': uf};

  static Cidade? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final nome = json['nome'];
    if (id is! num || nome is! String || nome.isEmpty) return null;
    return Cidade(
      id: id.toInt(),
      nome: nome,
      uf: json['uf'] is String ? json['uf'] as String : '',
    );
  }
}

class PrevisaoDia {
  const PrevisaoDia({
    required this.dia,
    required this.sigla,
    this.minima,
    this.maxima,
    this.iuv,
  });

  final DateTime dia;
  final String sigla;
  final int? minima;
  final int? maxima;
  final double? iuv;

  Map<String, Object?> toJson() => {
    'dia': dia.toIso8601String(),
    'sigla': sigla,
    'minima': minima,
    'maxima': maxima,
    'iuv': iuv,
  };

  static PrevisaoDia? fromJson(Object? json) {
    if (json is! Map) return null;
    final dia = DateTime.tryParse(
      json['dia'] is String ? json['dia'] as String : '',
    );
    if (dia == null) return null;
    return PrevisaoDia(
      dia: dia,
      sigla: json['sigla'] is String ? json['sigla'] as String : '',
      minima: _inteiro(json['minima']),
      maxima: _inteiro(json['maxima']),
      iuv: _decimal(json['iuv']),
    );
  }
}

class PrevisaoCidade {
  const PrevisaoCidade({
    required this.nome,
    required this.uf,
    required this.dias,
    this.atualizacao,
  });

  final String nome;
  final String uf;
  final DateTime? atualizacao;
  final List<PrevisaoDia> dias;

  Map<String, Object?> toJson() => {
    'nome': nome,
    'uf': uf,
    'atualizacao': atualizacao?.toIso8601String(),
    'dias': [for (final dia in dias) dia.toJson()],
  };

  static PrevisaoCidade? fromJson(Object? json) {
    if (json is! Map) return null;
    final nome = json['nome'];
    if (nome is! String || nome.isEmpty) return null;
    final diasJson = json['dias'];
    return PrevisaoCidade(
      nome: nome,
      uf: json['uf'] is String ? json['uf'] as String : '',
      atualizacao: DateTime.tryParse(
        json['atualizacao'] is String ? json['atualizacao'] as String : '',
      ),
      dias: [
        if (diasJson is List)
          for (final item in diasJson) ?PrevisaoDia.fromJson(item),
      ],
    );
  }
}

int? _inteiro(Object? valor) =>
    valor is num ? valor.toInt() : int.tryParse('${valor ?? ''}'.trim());

double? _decimal(Object? valor) => valor is num
    ? valor.toDouble()
    : double.tryParse('${valor ?? ''}'.replaceAll(',', '.').trim());
