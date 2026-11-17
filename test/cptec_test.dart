import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:previsao/previsao/cptec.dart';

const _xml = "<?xml version='1.0' encoding='ISO-8859-1'?>";

const _buscaSaoPaulo =
    '$_xml<cidades>'
    '<cidade><nome>São Paulo</nome><uf>SP</uf><id>244</id></cidade>'
    '<cidade><nome>São Paulo do Potengi</nome><uf>RN</uf><id>5021</id></cidade>'
    '</cidades>';

const _previsaoSaoPaulo =
    '$_xml<cidade>'
    '<nome>São Paulo</nome><uf>SP</uf><atualizacao>2026-11-17</atualizacao>'
    '<previsao><dia>2026-11-17</dia><tempo>pn</tempo><maxima>28</maxima>'
    '<minima>19</minima><iuv>6.0</iuv></previsao>'
    '<previsao><dia>2026-11-18</dia><tempo>c</tempo><maxima>29</maxima>'
    '<minima>19</minima><iuv>5.5</iuv></previsao>'
    '<previsao><dia>2026-11-19</dia><tempo>t</tempo><maxima>31</maxima>'
    '<minima>23</minima><iuv>0.0</iuv></previsao>'
    '<previsao><dia>2026-11-20</dia><tempo>ps</tempo><maxima>30</maxima>'
    '<minima>22</minima><iuv>7.5</iuv></previsao>'
    '</cidade>';

ClienteCptec _cliente(
  String corpo, {
  int status = 200,
  void Function(http.Request)? aoReceber,
}) => ClienteCptec(
  httpClient: MockClient((requisicao) async {
    aoReceber?.call(requisicao);
    return http.Response.bytes(latin1.encode(corpo), status);
  }),
);

ClienteCptec _clienteQueFalha(Object erro) =>
    ClienteCptec(httpClient: MockClient((_) async => throw erro));

void main() {
  group('buscarCidades', () {
    test('lê nome, UF e id decodificando ISO-8859-1', () async {
      final cidades = await _cliente(_buscaSaoPaulo).buscarCidades('sao paulo');

      expect(cidades, hasLength(2));
      expect(cidades.first.id, 244);
      expect(cidades.first.nome, 'São Paulo');
      expect(cidades.first.uf, 'SP');
      expect(cidades.last.nome, 'São Paulo do Potengi');
    });

    test('devolve lista vazia quando o serviço não encontra nada', () async {
      final cidades = await _cliente('$_xml<cidades></cidades>')
          .buscarCidades('cidade inexistente');

      expect(cidades, isEmpty);
    });

    test(
      'envia o termo com espaço codificado e descarta cidade sem id',
      () async {
        late Uri enviada;
        final cidades = await _cliente(
          '$_xml<cidades>'
          '<cidade><nome>Campinas</nome><uf>SP</uf><id>1182</id></cidade>'
          '<cidade><nome>Sem Id</nome><uf>SP</uf></cidade>'
          '</cidades>',
          aoReceber: (requisicao) => enviada = requisicao.url,
        ).buscarCidades('campinas');

        expect(enviada.query, 'city=campinas');
        expect(cidades, hasLength(1));
        expect(cidades.single.nome, 'Campinas');
      },
    );

    test('rejeita raiz diferente de cidades', () async {
      await expectLater(
        _cliente('$_xml<outra/>').buscarCidades('rio'),
        throwsA(isA<RespostaInvalida>()),
      );
    });
  });

  group('previsao', () {
    test('lê os quatro dias com data de atualização', () async {
      final previsao = await _cliente(_previsaoSaoPaulo).previsao(244);

      expect(previsao.nome, 'São Paulo');
      expect(previsao.uf, 'SP');
      expect(previsao.atualizacao, DateTime(2026, 11, 17));
      expect(previsao.dias, hasLength(4));

      final primeiro = previsao.dias.first;
      expect(primeiro.dia, DateTime(2026, 11, 17));
      expect(primeiro.sigla, 'pn');
      expect(primeiro.maxima, 28);
      expect(primeiro.minima, 19);
      expect(primeiro.iuv, 6.0);
      expect(previsao.dias[2].sigla, 't');
    });

    test('tolera IUV, temperaturas e data ausentes ou inválidas', () async {
      final previsao = await _cliente(
        '$_xml<cidade><nome>Curitiba</nome><uf>PR</uf>'
        '<previsao><dia>2026-11-18</dia><tempo>n</tempo></previsao>'
        '<previsao><dia>data-ruim</dia><tempo>c</tempo>'
        '<maxima>25</maxima><minima>14</minima></previsao>'
        '<previsao><dia>2026-11-19</dia><tempo>c</tempo>'
        '<maxima>25</maxima><minima>14</minima>'
        '<iuv>7,5</iuv></previsao>'
        '</cidade>',
      ).previsao(227);

      expect(previsao.dias, hasLength(2));
      expect(previsao.dias.first.maxima, isNull);
      expect(previsao.dias.first.minima, isNull);
      expect(previsao.dias.first.iuv, isNull);
      expect(previsao.dias.last.iuv, 7.5);
      expect(previsao.atualizacao, isNull);
    });

    test(
      'devolve previsão sem dias quando o serviço manda só a cidade',
      () async {
        final previsao = await _cliente(
          '$_xml<cidade><nome>Rio de Janeiro</nome><uf>RJ</uf></cidade>',
        ).previsao(241);

        expect(previsao.dias, isEmpty);
      },
    );

    test('rejeita raiz diferente de cidade', () async {
      await expectLater(
        _cliente('$_xml<cidades></cidades>').previsao(244),
        throwsA(isA<RespostaInvalida>()),
      );
    });
  });

  group('falhas', () {
    test('status diferente de 200 é falha de conexão', () async {
      await expectLater(
        _cliente('indisponível', status: 500).buscarCidades('campinas'),
        throwsA(isA<FalhaConexao>()),
      );
    });

    test('exceção de rede é falha de conexão', () async {
      await expectLater(
        _clienteQueFalha(http.ClientException('sem rede')).previsao(244),
        throwsA(isA<FalhaConexao>()),
      );
    });

    test('timeout é falha de conexão', () async {
      await expectLater(
        _clienteQueFalha(TimeoutException('lento')).buscarCidades('campinas'),
        throwsA(isA<FalhaConexao>()),
      );
    });

    test('XML truncado é resposta inválida', () async {
      await expectLater(
        _cliente('$_xml<cidade><nome>São Paulo').previsao(244),
        throwsA(isA<RespostaInvalida>()),
      );
    });

    test('corpo vazio é resposta inválida', () async {
      await expectLater(
        _cliente('').buscarCidades('campinas'),
        throwsA(isA<RespostaInvalida>()),
      );
    });
  });
}
