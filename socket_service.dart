import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class SocketService {
  // Singleton pattern to ensure only one instance of SocketService exists
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  Future<dynamic> sendQueryRequest(
      String ip, int port, String query, tlvNo) async {
    //if (ip == "101.53.149.34" && port == 4446) port = 4443;
    final url = Uri.parse('http://$ip:$port/process');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({"query": query, "tlvNo": tlvNo});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          return decoded["reply_buff"] ?? "Error";
        } catch (e) {
          return "Error1"; // Not a valid JSON
        }
      } else {
        return "Error2"; // HTTP status not OK
      }
    } catch (e) {
      return "Error3"; // Network or other exception
    }
  }

  SocketService._internal();

  Future<String> sendMessage(
      String ip, int port, String message, int packetType) async {
    String receivedMessage = '';
    if (true) {
      return await sendQueryRequest(ip, port, message, packetType);
    }
    print("Query:" + message);
    // port = 4447;
    try {
      // Create a socket connection to the given IP and port
      Socket socket =
          await Socket.connect(ip, port).timeout(Duration(seconds: 60));
      socket.setOption(SocketOption.tcpNoDelay, true);
      socket.timeout(Duration(seconds: 30));
      print(
          'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');

      // Prepare the packet
      Uint8List buffer =
          Uint8List(8 + message.length); // 8 bytes for header + message length

      // Write packet type (4 bytes)
      ByteData.view(buffer.buffer).setInt32(0, packetType, Endian.little);

      // Write message length (4 bytes)
      ByteData.view(buffer.buffer).setInt32(4, message.length, Endian.little);

      // Write the message (String to bytes)
      buffer.setRange(8, buffer.lengthInBytes, utf8.encode(message));

      // Send the buffer to the socket
      socket.add(buffer);
      await socket.flush();

      // Receive response
      List<int> responseBuffer = [];
      int responseLength = 0;

      await for (var data in socket) {
        responseBuffer.addAll(data);
        print("Received Data:${responseBuffer.length}");

        // Check if we have at least 8 bytes (type + length)
        if (responseBuffer.length >= 8 && responseLength == 0) {
          // Read the type (first 4 bytes)
          int responseType =
              ByteData.view(Uint8List.fromList(responseBuffer).buffer)
                  .getInt32(0, Endian.little);
          print("responseType: $responseType");

          // Read the length (next 4 bytes)
          responseLength =
              ByteData.view(Uint8List.fromList(responseBuffer).buffer)
                  .getInt32(4, Endian.little);
          print("responseLength: $responseLength");
        }

        // If we have enough data for the full response, break
        if (responseBuffer.length >= responseLength) {
          receivedMessage =
              utf8.decode(responseBuffer.sublist(8, responseLength));
          print("Received Message: $receivedMessage");
          break;
        }
      }

      // Close the socket after receiving the message
      await socket.close();
    } catch (e) {
      print('Error in Socket Service: $e');
      return "Err: Network Error, No internet or Server is down";
    }
    return receivedMessage;
  }
}
