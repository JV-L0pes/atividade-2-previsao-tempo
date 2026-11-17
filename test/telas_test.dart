import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:previsao/previsao/cache.dart';
import 'package:previsao/previsao/cptec.dart';
import 'package:previsao/previsao/modelos.dart';
import 'package:previsao/previsao/tela_busca.dart';
import 'package:previsao/previsao/tela_previsao.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _xml = "<?xml version='1.0' encoding='ISO-8859-1'?>";

const _busca =
    '$_xml<cidades>'
    '<cidade><nome>São Paulo</nome><uf>SP</uf><id>244</id></cidade>'
    '</cidades>';

const _previsao =
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

const _cidade = Cidade(id: 244, nome: 'São Paulo', uf: 'SP');

ClienteCptec _clienteOk() => ClienteCptec(
  httpClient: MockClient(
    (requisicao) async => http.Response.bytes(
      latin1.encode(
        requisicao.url.path.contains('listaCidades') ? _busca : _previsao,
      ),
      200,
    ),
  ),
);

ClienteCptec _clienteSemRede() => ClienteCptec(
  httpClient: MockClient((_) async => throw http.ClientException('sem rede')),
);

Future<void> _celular(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2280);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('mostra os 4 dias, gráfico, IUV e fonte', (tester) async {
    await _celular(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: TelaPrevisao(
          cidade: _cidade,
          cliente: _clienteOk(),
          cache: CacheConsulta(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.textContaining('máx 28 °C'), findsOneWidget);
    expect(find.textContaining('máx 31 °C'), findsOneWidget);
    expect(find.text('Parcialmente Nublado'), findsOneWidget);
    expect(find.text('Tempestade'), findsOneWidget);
    expect(find.text('IUV 6.0'), findsOneWidget);
    expect(find.text('IUV 0.0'), findsNothing);

    await tester.scrollUntilVisible(
      find.textContaining('Fonte: CPTEC/INPE'),
      200,
    );
    expect(find.textContaining('atualizado em 17/11/2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem rede e sem cache mostra erro com tentar novamente', (
    tester,
  ) async {
    await _celular(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: TelaPrevisao(
          cidade: _cidade,
          cliente: _clienteSemRede(),
          cache: CacheConsulta(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sem conexão com o CPTEC/INPE.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('sem rede mostra a previsão salva com aviso de cache', (
    tester,
  ) async {
    final cache = CacheConsulta();
    await cache.salvar(
      _cidade,
      PrevisaoCidade(
        nome: 'São Paulo',
        uf: 'SP',
        atualizacao: DateTime(2026, 11, 17),
        dias: [
          PrevisaoDia(
            dia: DateTime(2026, 11, 18),
            sigla: 'c',
            minima: 19,
            maxima: 29,
            iuv: 6.5,
          ),
        ],
      ),
    );

    await _celular(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: TelaPrevisao(
          cidade: _cidade,
          cliente: _clienteSemRede(),
          cache: cache,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sem conexão'), findsOneWidget);
    expect(
      find.textContaining('Exibindo dados atualizados em 17/11/2026'),
      findsOneWidget,
    );
    expect(find.textContaining('máx 29 °C'), findsOneWidget);
  });

  testWidgets('busca lista cidade e abre a previsão', (tester) async {
    await _celular(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: TelaBusca(cliente: _clienteOk(), cache: CacheConsulta()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'sao paulo');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('São Paulo'), findsOneWidget);
    expect(find.text('SP'), findsOneWidget);

    await tester.tap(find.text('São Paulo'));
    await tester.pumpAndSettle();

    expect(find.text('São Paulo — SP'), findsOneWidget);
    expect(find.textContaining('máx 28 °C'), findsOneWidget);
  });

  testWidgets('busca sem resultado avisa a cidade pesquisada', (tester) async {
    await _celular(tester);
    final cliente = ClienteCptec(
      httpClient: MockClient(
        (_) async => http.Response.bytes(latin1.encode('$_xml<cidades/>'), 200),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TelaBusca(cliente: cliente, cache: CacheConsulta()),
      ),
    );

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma cidade encontrada para «xyz».'), findsOneWidget);
  });
}
