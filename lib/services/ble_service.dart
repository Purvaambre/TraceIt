import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  static final Guid serviceUuid =
      Guid("12345678-1234-1234-1234-123456789abc");

  static final Guid characteristicUuid =
      Guid("abcdefab-1234-1234-1234-abcdefabcdef");

  // ============================================================
  // CONNECTION STATE
  // ============================================================
  //
  // This exposes the REAL Bluetooth connection state of the
  // SmartFinder.
  //
  // The UI can listen to this stream and automatically change:
  //
  // Connected -> Disconnected
  //
  // when the ESP32 goes out of range or disconnects.
  //
  // IMPORTANT:
  // This does NOT automatically reconnect.
  // ============================================================

  Stream<BluetoothConnectionState> connectionStateStream(
    BluetoothDevice device,
  ) {
    return device.connectionState;
  }

  // ============================================================
  // CHECK CURRENT CONNECTION
  // ============================================================

  bool isConnected(
    BluetoothDevice device,
  ) {
    return device.isConnected;
  }

  // ============================================================
  // PERMISSIONS
  // ============================================================

  Future<bool> requestPermissions() async {
    final bluetoothScan =
        await Permission.bluetoothScan.request();

    final bluetoothConnect =
        await Permission.bluetoothConnect.request();

    if (!bluetoothScan.isGranted ||
        !bluetoothConnect.isGranted) {
      return false;
    }

    return true;
  }

  // ============================================================
  // SCAN
  // ============================================================

  Stream<List<ScanResult>> scanForDevices({
    Duration timeout = const Duration(seconds: 5),
  }) {
    final controller =
        StreamController<List<ScanResult>>();

    final results = <String, ScanResult>{};

    _scanSubscription?.cancel();

    _scanSubscription =
        FlutterBluePlus.onScanResults.listen(
      (scanResults) {
        for (final result in scanResults) {
          results[result.device.remoteId.str] =
              result;
        }

        if (!controller.isClosed) {
          controller.add(
            results.values.toList(),
          );
        }
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    FlutterBluePlus.startScan(
      timeout: timeout,
    ).catchError(
      (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    Future.delayed(timeout, () async {
      await _scanSubscription?.cancel();
      _scanSubscription = null;

      if (!controller.isClosed) {
        await controller.close();
      }
    });

    return controller.stream;
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print(
        "BLE stop scan error: $e",
      );
    }

    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  // ============================================================
  // CONNECT
  // ============================================================

  Future<bool> connectToDevice(
    BluetoothDevice device,
  ) async {
    try {
      print("");
      print("================================");
      print("BLE CONNECTION START");
      print("================================");

      print(
        "Device ID: ${device.remoteId.str}",
      );

      await stopScan();

      // --------------------------------------------------------
      // ALREADY CONNECTED
      // --------------------------------------------------------

      if (device.isConnected) {
        print(
          "Device already connected.",
        );

        final valid =
            await _verifySmartFinderServices(
          device,
        );

        if (valid) {
          print(
            "SmartFinder already connected.",
          );

          return true;
        }

        try {
          await device.disconnect();
        } catch (_) {}

        return false;
      }

      // --------------------------------------------------------
      // CONNECT
      // --------------------------------------------------------

      print(
        "Attempting Bluetooth connection...",
      );

      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
        license: License.free,
      );

      print(
        "Bluetooth connection established.",
      );

      if (!device.isConnected) {
        print(
          "Device is not connected after connect().",
        );

        return false;
      }

      // --------------------------------------------------------
      // VERIFY SMARTFINDER SERVICE
      // --------------------------------------------------------

      final valid =
          await _verifySmartFinderServices(
        device,
      );

      if (!valid) {
        print(
          "SmartFinder service not found.",
        );

        try {
          await device.disconnect();
        } catch (_) {}

        return false;
      }

      print(
        "SmartFinder connection successful.",
      );

      return true;
    } catch (e, stackTrace) {
      print("");
      print("================================");
      print("BLE CONNECTION FAILED");
      print("================================");
      print("Error: $e");
      print(stackTrace);
      print("================================");

      try {
        if (device.isConnected) {
          await device.disconnect();
        }
      } catch (_) {}

      return false;
    }
  }

  // ============================================================
  // VERIFY SMARTFINDER SERVICE
  // ============================================================

  Future<bool> _verifySmartFinderServices(
    BluetoothDevice device,
  ) async {
    try {
      final services =
          await device.discoverServices();

      for (final service in services) {
        if (service.uuid == serviceUuid) {
          for (final characteristic
              in service.characteristics) {
            if (characteristic.uuid ==
                characteristicUuid) {
              return true;
            }
          }
        }
      }

      return false;
    } catch (e) {
      print(
        "Service discovery failed: $e",
      );

      return false;
    }
  }

  // ============================================================
  // FIND
  // ============================================================

  Future<bool> sendFindCommand(
    BluetoothDevice device,
  ) async {
    try {
      if (!device.isConnected) {
        print(
          "Cannot send FIND: not connected.",
        );

        return false;
      }

      final services =
          await device.discoverServices();

      for (final service in services) {
        if (service.uuid == serviceUuid) {
          for (final characteristic
              in service.characteristics) {
            if (characteristic.uuid ==
                characteristicUuid) {
              await characteristic.write(
                Uint8List.fromList(
                  "FIND".codeUnits,
                ),
                withoutResponse: false,
              );

              print(
                "FIND command sent.",
              );

              return true;
            }
          }
        }
      }

      return false;
    } catch (e) {
      print(
        "FIND command failed: $e",
      );

      return false;
    }
  }

  // ============================================================
  // STOP
  //
  // IMPORTANT:
  // STOP DOES NOT DISCONNECT BLE.
  // ============================================================

  Future<bool> sendStopCommand(
    BluetoothDevice device,
  ) async {
    try {
      if (!device.isConnected) {
        print(
          "Cannot send STOP: not connected.",
        );

        return false;
      }

      final services =
          await device.discoverServices();

      for (final service in services) {
        if (service.uuid == serviceUuid) {
          for (final characteristic
              in service.characteristics) {
            if (characteristic.uuid ==
                characteristicUuid) {
              await characteristic.write(
                Uint8List.fromList(
                  "STOP".codeUnits,
                ),
                withoutResponse: false,
              );

              print(
                "STOP command sent.",
              );

              // IMPORTANT:
              // Do NOT disconnect here.
              //
              // SmartFinder remains connected.

              return true;
            }
          }
        }
      }

      return false;
    } catch (e) {
      print(
        "STOP command failed: $e",
      );

      return false;
    }
  }

  // ============================================================
  // DISCONNECT
  //
  // Used when:
  // - App goes to background
  // - App closes
  // - User/session explicitly disconnects
  //
  // NOT used by STOP.
  // ============================================================

  Future<void> disconnectDevice(
    BluetoothDevice device,
  ) async {
    try {
      if (device.isConnected) {
        print(
          "Disconnecting SmartFinder: "
          "${device.remoteId.str}",
        );

        await device.disconnect();

        print(
          "SmartFinder disconnect requested.",
        );
      }
    } catch (e) {
      print(
        "Disconnect error: $e",
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await stopScan();
  }
}