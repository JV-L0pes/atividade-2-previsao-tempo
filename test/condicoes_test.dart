import 'package:flutter_test/flutter_test.dart';
import 'package:previsao/previsao/condicoes.dart';

void main() {
  test('as 40 siglas documentadas têm descrição', () {
    expect(condicoesCptec, hasLength(40));
    for (final condicao in condicoesCptec.values) {
      expect(condicao.descricao, isNotEmpty);
    }
  });

  test('converte as siglas da documentação do CPTEC/INPE', () {
    expect(condicaoPara('pn').descricao, 'Parcialmente Nublado');
    expect(condicaoPara('cl').descricao, 'Céu Claro');
    expect(condicaoPara('t').descricao, 'Tempestade');
    expect(condicaoPara('nv').descricao, 'Nevoeiro');
    expect(condicaoPara('psc').descricao, 'Possibilidade de Chuva');
    expect(condicaoPara('ne').descricao, 'Neve');
  });

  test('aceita sigla com espaço e maiúsculas', () {
    expect(condicaoPara(' PN ').descricao, 'Parcialmente Nublado');
  });

  test('sigla desconhecida ou ausente vira Não definido', () {
    expect(condicaoPara('zz').descricao, 'Não definido');
    expect(condicaoPara('').descricao, 'Não definido');
  });

  test('a sigla nd usa a condição padrão', () {
    expect(condicaoPara('nd').descricao, 'Não definido');
  });
}
