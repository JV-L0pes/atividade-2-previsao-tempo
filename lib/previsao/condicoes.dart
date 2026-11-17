import 'package:flutter/material.dart';

/// Condição do tempo conforme a tabela oficial de siglas do CPTEC/INPE.
class Condicao {
  const Condicao(this.descricao, this.icone);

  final String descricao;
  final IconData icone;
}

const Condicao condicaoPadrao = Condicao('Não definido', Icons.help_outline);

/// As 39 siglas documentadas em http://servicos.cptec.inpe.br/XML/#condicoes-tempo.
const Map<String, Condicao> condicoesCptec = {
  'ec': Condicao('Encoberto com Chuvas Isoladas', Icons.grain),
  'ci': Condicao('Chuvas Isoladas', Icons.grain),
  'c': Condicao('Chuva', Icons.water_drop),
  'in': Condicao('Instável', Icons.cloud),
  'pp': Condicao('Poss. de Pancadas de Chuva', Icons.grain),
  'cm': Condicao('Chuva pela Manhã', Icons.grain),
  'cn': Condicao('Chuva a Noite', Icons.grain),
  'pt': Condicao('Pancadas de Chuva a Tarde', Icons.grain),
  'pm': Condicao('Pancadas de Chuva pela Manhã', Icons.grain),
  'np': Condicao('Nublado e Pancadas de Chuva', Icons.thunderstorm),
  'pc': Condicao('Pancadas de Chuva', Icons.grain),
  'pn': Condicao('Parcialmente Nublado', Icons.wb_cloudy),
  'cv': Condicao('Chuvisco', Icons.grain),
  'ch': Condicao('Chuvoso', Icons.water_drop),
  't': Condicao('Tempestade', Icons.thunderstorm),
  'ps': Condicao('Predomínio de Sol', Icons.wb_sunny),
  'e': Condicao('Encoberto', Icons.cloud),
  'n': Condicao('Nublado', Icons.cloud),
  'cl': Condicao('Céu Claro', Icons.wb_sunny),
  'nv': Condicao('Nevoeiro', Icons.blur_on),
  'g': Condicao('Geada', Icons.ac_unit),
  'ne': Condicao('Neve', Icons.ac_unit),
  'nd': condicaoPadrao,
  'pnt': Condicao('Pancadas de Chuva a Noite', Icons.grain),
  'psc': Condicao('Possibilidade de Chuva', Icons.grain),
  'pcm': Condicao('Possibilidade de Chuva pela Manhã', Icons.grain),
  'pct': Condicao('Possibilidade de Chuva a Tarde', Icons.grain),
  'pcn': Condicao('Possibilidade de Chuva a Noite', Icons.grain),
  'npt': Condicao('Nublado com Pancadas a Tarde', Icons.thunderstorm),
  'npn': Condicao('Nublado com Pancadas a Noite', Icons.thunderstorm),
  'ncn': Condicao('Nublado com Poss. de Chuva a Noite', Icons.grain),
  'nct': Condicao('Nublado com Poss. de Chuva a Tarde', Icons.grain),
  'ncm': Condicao('Nubl. c/ Poss. de Chuva pela Manhã', Icons.grain),
  'npm': Condicao('Nublado com Pancadas pela Manhã', Icons.grain),
  'npp': Condicao('Nublado com Possibilidade de Chuva', Icons.grain),
  'vn': Condicao('Variação de Nebulosidade', Icons.wb_cloudy),
  'ct': Condicao('Chuva a Tarde', Icons.water_drop),
  'ppn': Condicao('Poss. de Panc. de Chuva a Noite', Icons.grain),
  'ppt': Condicao('Poss. de Panc. de Chuva a Tarde', Icons.grain),
  'ppm': Condicao('Poss. de Panc. de Chuva pela Manhã', Icons.grain),
};

Condicao condicaoPara(String sigla) =>
    condicoesCptec[sigla.trim().toLowerCase()] ?? condicaoPadrao;
