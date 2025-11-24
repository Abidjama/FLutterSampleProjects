

import 'dart:io';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

typedef OnMessageReceived = void Function(String message);

class NearbyReceiverService {
  final Strategy strategy = Strategy.P2P_STAR;
  final OnMessageReceived onMessageReceived;

  NearbyReceiverService({required this.onMessageReceived});

  void initialize() async {
    bool granted = await _requestPermissions();
    if (!granted) {
      print("Required permissions not granted. Cannot start advertising.");
      return;
    }

    bool isAdvertising = await Nearby().startAdvertising(
      'MasjidTV',
      strategy,
      onConnectionInitiated: (id, info) {
        Nearby().acceptConnection(
          id,
          onPayLoadRecieved: (endpointId, payload) async {
            if (payload.type == PayloadType.BYTES) {
              final message = String.fromCharCodes(payload.bytes!);
              onMessageReceived(message);
            } else if (payload.type == PayloadType.FILE) {
              final filePath = payload.filePath!;
              onMessageReceived('FILE_RECEIVED:$filePath');
            }
          },
          onPayloadTransferUpdate: (endpointId, update) {},
        );
      },
      onConnectionResult: (id, status) {},
      onDisconnected: (id) {},
    );

    if (!isAdvertising) {
      print("Failed to start advertising.");
    } else {
      print("Advertising started.");
    }
  }

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  void stop() {
    Nearby().stopAdvertising();
    Nearby().stopAllEndpoints();
  }
}
