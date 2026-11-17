import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'condicoes.dart';
import 'modelos.dart';

const _diasDaSemana = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

String dataCurta(DateTime data) =>
    '${_diasDaSemana[data.weekday - 1]}, ${_doisDigitos(data.day)}/${_doisDigitos(data.month)}';

String dataNumerica(DateTime data) =>
    '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}/${data.year}';

String temperatura(int? valor) => valor == null ? '—' : '$valor °C';

String _doisDigitos(int valor) => valor.toString().padLeft(2, '0');

/// Mensagem de estado vazio ou de erro, com ação opcional de tentar de novo.
class Aviso extends StatelessWidget {
  const Aviso({
    super.key,
    required this.icone,
    required this.texto,
    this.aoTentarNovamente,
  });

  final IconData icone;
  final String texto;
  final VoidCallback? aoTentarNovamente;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: esquema.outline),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center),
            if (aoTentarNovamente != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: aoTentarNovamente,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CardDia extends StatelessWidget {
  const CardDia({super.key, required this.dia});

  final PrevisaoDia dia;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final condicao = condicaoPara(dia.sigla);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(condicao.icone, size: 40, color: tema.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dataCurta(dia.dia),
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(condicao.descricao, style: tema.textTheme.bodyMedium),
                  if (dia.iuv != null && dia.iuv! > 0)
                    Text(
                      'IUV ${dia.iuv!.toStringAsFixed(1)}',
                      style: tema.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'máx ${temperatura(dia.maxima)}',
                  style: tema.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange.shade700,
                  ),
                ),
                Text(
                  'mín ${temperatura(dia.minima)}',
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de linhas com mínima e máxima dos dias que têm os dois valores.
class GraficoTemperaturas extends StatelessWidget {
  const GraficoTemperaturas({super.key, required this.dias});

  final List<PrevisaoDia> dias;

  @override
  Widget build(BuildContext context) {
    final validos = [
      for (final dia in dias)
        if (dia.minima != null && dia.maxima != null) dia,
    ];
    if (validos.length < 2) return const SizedBox.shrink();

    final menorBruto =
        validos.map((dia) => dia.minima!).reduce((a, b) => a < b ? a : b) - 1;
    final maiorBruto =
        validos.map((dia) => dia.maxima!).reduce((a, b) => a > b ? a : b) + 1;
    final minimo = (menorBruto / 5).floor() * 5;
    final maximo = maiorBruto <= minimo
        ? minimo + 5
        : (maiorBruto / 5).ceil() * 5;
    final tema = Theme.of(context);
    final estiloEixo = tema.textTheme.labelSmall;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legenda(cor: Colors.deepOrange.shade700, texto: 'máxima'),
                const SizedBox(width: 16),
                _Legenda(cor: Colors.blue.shade700, texto: 'mínima'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (validos.length - 1).toDouble(),
                  minY: minimo.toDouble(),
                  maxY: maximo.toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: tema.colorScheme.outlineVariant),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (pontos) => [
                        for (final ponto in pontos)
                          LineTooltipItem(
                            '${ponto.y.round()} °C',
                            TextStyle(
                              color: ponto.bar.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 5,
                        getTitlesWidget: (valor, _) =>
                            Text('${valor.round()}°', style: estiloEixo),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (valor, meta) {
                          final indice = valor.round();
                          if (indice < 0 || indice >= validos.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              _diasDaSemana[validos[indice].dia.weekday - 1],
                              style: estiloEixo,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < validos.length; i++)
                          FlSpot(i.toDouble(), validos[i].maxima!.toDouble()),
                      ],
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: Colors.deepOrange.shade700,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < validos.length; i++)
                          FlSpot(i.toDouble(), validos[i].minima!.toDouble()),
                      ],
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: Colors.blue.shade700,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.cor, required this.texto});

  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 3, color: cor),
        const SizedBox(width: 6),
        Text(texto, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
