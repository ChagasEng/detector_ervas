import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import 'connectivity_service.dart';

class ChatbaseService {
  static const _chatbotId = "RmehOVMlMrwNwTufX7KlKo"; // ✅ Seu Chatbot ID
  static const _apiKey = "bf944de1-3404-4b35-8ef8-088b428f5991"; // ✅ Sua API Key
  static const _apiUrl = "https://www.chatbase.co/api/v4/chat"; // ✅ API v4 atual

  /// 🔹 Envia mensagem ao Chatbase (com suporte offline)
  static Future<String> sendMessage(String message) async {
    print("🔵 [CHATBASE] Iniciando sendMessage...");
    print("🔵 [CHATBASE] Mensagem recebida: '$message'");

    final hasNet = await ConnectivityService.hasConnection();
    print("🔵 [CHATBASE] Status da conexão: $hasNet");

    final box = Hive.box('chat_queue');
    print("🔵 [CHATBASE] Box 'chat_queue' aberta, tamanho: ${box.length}");

    if (!hasNet) {
      print("🌐 [CHATBASE] Sem internet - salvando mensagem localmente");
      await box.add(ChatMessage(text: message, pending: true).toMap());
      return "🌐 Sem internet — mensagem salva e será enviada quando estiver online.";
    }

    try {
      final requestBody = {
        "messages": [
          {"role": "user", "content": message}
        ],
        "model": "gpt-3.5-turbo",
        "temperature": 0.7,
        "stream": false
      };

      print("🟡 [CHATBASE] Enviando para API v4...");
      print("🟡 [CHATBASE] RequestBody: ${jsonEncode(requestBody)}");

      final res = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "accept": "application/json",
          "content-type": "application/json",
          "X-Chatbase-Key": _apiKey,
          "X-Chatbase-Chatbot-Id": _chatbotId,
        },
        body: jsonEncode(requestBody),
      );

      print("🟡 [CHATBASE] Resposta recebida - Status: ${res.statusCode}");
      print("🟡 [CHATBASE] Body: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final reply =
            data["choices"]?[0]?["message"]?["content"] ?? "🤖 Sem resposta.";

        print("✅ [CHATBASE] Mensagem enviada: $message");
        print("💬 [CHATBASE] Resposta: $reply");
        return reply;
      } else {
        print("🔴 [CHATBASE] Erro HTTP: ${res.statusCode} - ${res.body}");
        await box.add(ChatMessage(text: message, pending: true).toMap());
        return "⚠️ Erro ${res.statusCode}: mensagem salva para reenvio.";
      }
    } catch (e) {
      print("🔴 [CHATBASE] ERRO CAPTURADO: $e");
      await box.add(ChatMessage(text: message, pending: true).toMap());
      return "⚠️ Erro ao enviar agora. Mensagem salva localmente.";
    }
  }

  /// 🔹 Verifica credenciais iniciais (setup do bot)
  static Future<void> verifySetup() async {
    print("🔐 [SETUP] Verificando configuração do Chatbase...");
    print("🔐 [SETUP] Chatbot ID: $_chatbotId");
    print("🔐 [SETUP] API Key: ${_apiKey.substring(0, 8)}...");
    print("🔐 [SETUP] Testando autenticação na API v4...");

    try {
      final testRes = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "accept": "application/json",
          "content-type": "application/json",
          "X-Chatbase-Key": _apiKey,
          "X-Chatbase-Chatbot-Id": _chatbotId,
        },
        body: jsonEncode({
          "messages": [
            {"role": "user", "content": "Hello, test connection."}
          ],
          "model": "gpt-3.5-turbo",
          "stream": false
        }),
      );

      print("🔍 [CHATBASE] Teste de setup - Status: ${testRes.statusCode}");
      print("🔍 [CHATBASE] Body: ${testRes.body}");

      if (testRes.statusCode == 200) {
        print("✅ [CHATBASE] Conexão com Chatbase verificada com sucesso!");
      } else {
        print("⚠️ [CHATBASE] Falha na verificação: ${testRes.body}");
      }
    } catch (e) {
      print("🔴 [CHATBASE] Erro de verificação: $e");
    }
  }

  /// 🔹 Reenvia mensagens pendentes ao reconectar
  static Future<void> resendPending() async {
    print("🟡 [CHATBASE] Iniciando resendPending...");

    final box = Hive.box('chat_queue');
    final keys = box.keys.toList();
    print("🟡 [CHATBASE] Total de mensagens no box: ${keys.length}");

    if (keys.isEmpty) return;

    print("📡 [CHATBASE] Reconexão detectada: reenviando mensagens...");
    for (final key in keys) {
      try {
        final msgData = box.get(key);
        final msg = ChatMessage.fromMap(Map<String, dynamic>.from(msgData));

        if (msg.pending) {
          print("🟡 [CHATBASE] Reenviando: '${msg.text}'");
          await sendMessage(msg.text);
          await box.delete(key);
        }
      } catch (e) {
        print("🔴 [CHATBASE] Erro ao reenviar: $e");
      }
    }
  }
}
