import 'package:flutter/material.dart';

import 'previsao/cache.dart';
import 'previsao/cptec.dart';
import 'previsao/tela_busca.dart';

void main() {
  runApp(AppPrevisao());
}

class AppPrevisao extends StatelessWidget {
  AppPrevisao({super.key});

  final _cliente = ClienteCptec();
  final _cache = CacheConsulta();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Previsão do tempo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0B5394)),
      home: TelaBusca(cliente: _cliente, cache: _cache),
    );
  }
}
