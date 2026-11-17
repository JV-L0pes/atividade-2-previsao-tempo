import 'package:flutter_test/flutter_test.dart';
import 'package:previsao/previsao/cache.dart';
import 'package:previsao/previsao/modelos.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cidade = Cidade(id: 244, nome: 'São Paulo', uf: 'SP');
  final previsao = PrevisaoCidade(
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
      PrevisaoDia(dia: DateTime(2026, 11, 19), sigla: 'pn'),
    ],
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sem consulta salva devolve null', () async {
    expect(await CacheConsulta().ler(), isNull);
  });

  test('salva e lê cidade e previsão com campos opcionais', () async {
    final cache = CacheConsulta();
    await cache.salvar(cidade, previsao);

    final salva = await cache.ler();

    expect(salva, isNotNull);
    expect(salva!.cidade.id, 244);
    expect(salva.cidade.nome, 'São Paulo');
    expect(salva.cidade.uf, 'SP');
    expect(salva.previsao.atualizacao, DateTime(2026, 11, 17));
    expect(salva.previsao.dias, hasLength(2));
    expect(salva.previsao.dias.first.dia, DateTime(2026, 11, 18));
    expect(salva.previsao.dias.first.minima, 19);
    expect(salva.previsao.dias.first.maxima, 29);
    expect(salva.previsao.dias.first.iuv, 6.5);
    expect(salva.previsao.dias.last.maxima, isNull);
    expect(salva.previsao.dias.last.iuv, isNull);
  });

  test('sobrescreve a consulta anterior', () async {
    final cache = CacheConsulta();
    await cache.salvar(cidade, previsao);
    await cache.salvar(
      const Cidade(id: 227, nome: 'Curitiba', uf: 'PR'),
      PrevisaoCidade(
        nome: 'Curitiba',
        uf: 'PR',
        dias: [PrevisaoDia(dia: DateTime(2026, 11, 18), sigla: 'n')],
      ),
    );

    final salva = await cache.ler();

    expect(salva!.cidade.id, 227);
    expect(salva.previsao.dias.single.sigla, 'n');
  });

  test('JSON corrompido devolve null em vez de estourar', () async {
    SharedPreferences.setMockInitialValues({'ultima_consulta': '{quebrado'});

    expect(await CacheConsulta().ler(), isNull);
  });

  test('consulta salva sem dias é descartada', () async {
    SharedPreferences.setMockInitialValues({
      'ultima_consulta':
          '{"cidade":{"id":244,"nome":"São Paulo","uf":"SP"},'
          '"previsao":{"nome":"São Paulo","uf":"SP","dias":[]}}',
    });

    expect(await CacheConsulta().ler(), isNull);
  });
}
