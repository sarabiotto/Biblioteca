import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.170:8000';

  static Future<String?> baixarBinauralDestress({int duracao = 60}) async {
    return await _baixarAudio(
      endpoint: '/binaural/destress?duracao=$duracao',
      nomeArquivo: 'destress_dynamic.wav',
    );
  }

  static Future<String?> baixarBinauralFoco({int duracao = 60}) async {
    return await _baixarAudio(
      endpoint: '/binaural/foco?duracao=$duracao',
      nomeArquivo: 'foco_dynamic.wav',
    );
  }

  static Future<bool> verificarServidor() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/saude'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Servidor offline: $e');
      return false;
    }
  }

  static Future<String?> _baixarAudio({
    required String endpoint,
    required String nomeArquivo,
  }) async {
    try {
      debugPrint('Baixando áudio: $baseUrl$endpoint');
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final arquivo = File('${dir.path}/$nomeArquivo');
        await arquivo.writeAsBytes(response.bodyBytes);
        debugPrint('Áudio salvo em: ${arquivo.path}');
        return arquivo.path;
      } else {
        debugPrint('Erro ao baixar áudio: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Erro de conexão: $e');
      return null;
    }
  }
}
