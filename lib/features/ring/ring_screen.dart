import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../core/utils/responsive.dart';
import '../../models/device_model.dart';
import '../../services/ble_service.dart';

const Color _blue = Color(0xFF2563EB);
const Color _textDark = Color(0xFF17233B);
const Color _textGrey = Color(0xFF667085);
const Color _softBlue = Color(0xFFF4F8FF);

class RingScreen extends StatefulWidget {
  final DeviceModel device;

  const RingScreen({
    super.key,
    required this.device,
  });

  @override
  State<RingScreen> createState() => _RingScreenState();
}

class _RingScreenState extends State<RingScreen>
    with SingleTickerProviderStateMixin {
  final BleService _bleService = BleService();

  late AnimationController _animationController;

  BluetoothDevice? _bluetoothDevice;

  bool _isFinding = false;
  bool _isStopping = false;

  String _statusText =
      "Connecting to your SmartFinder...";
  String _subtitleText = "Please wait";

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 800,
      ),
    );

    _startFinding();
  }

  // ============================================================
  // START FIND
  // ============================================================

  Future<void> _startFinding() async {
    final bleId = widget.device.bleId;

    if (bleId == null || bleId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _statusText =
            "SmartFinder ID not found";
        _subtitleText =
            "Please add the device again";
      });

      return;
    }

    try {
      if (mounted) {
        setState(() {
          _statusText =
              "Connecting to SmartFinder...";
          _subtitleText =
              "Establishing Bluetooth connection";
        });
      }

      // --------------------------------------------------------
      // USE SAVED BLUETOOTH REMOTE ID
      // --------------------------------------------------------

      final device =
          BluetoothDevice.fromId(bleId);

      _bluetoothDevice = device;

      // --------------------------------------------------------
      // CONNECT
      // --------------------------------------------------------

      final connected =
          await _bleService.connectToDevice(
        device,
      );

      if (!connected) {
        if (!mounted) return;

        setState(() {
          _statusText =
              "Unable to connect";
          _subtitleText =
              "Make sure your SmartFinder is nearby";
        });

        return;
      }

      if (!mounted) return;

      // --------------------------------------------------------
      // CONNECTED
      // --------------------------------------------------------

      setState(() {
        _isFinding = true;
        _statusText =
            "Finding ${widget.device.name}...";
        _subtitleText =
            "Playing sound + red LED on your SmartFinder";
      });

      _animationController.repeat(
        reverse: true,
      );

      // --------------------------------------------------------
      // SEND FIND
      // --------------------------------------------------------

      final sent =
          await _bleService.sendFindCommand(
        device,
      );

      if (!sent) {
        _animationController.stop();

        if (!mounted) return;

        setState(() {
          _isFinding = false;
          _statusText =
              "Unable to start finding";
          _subtitleText =
              "Could not send FIND command";
        });

        // If FIND itself failed, disconnect because
        // the connection is not useful anymore.
        await _bleService.disconnectDevice(
          device,
        );

        _bluetoothDevice = null;
      }
    } catch (e) {
      debugPrint(
        "FIND ERROR: $e",
      );

      _animationController.stop();

      if (!mounted) return;

      setState(() {
        _statusText =
            "Unable to connect";
        _subtitleText =
            "Make sure your SmartFinder is nearby";
      });
    }
  }

  // ============================================================
  // STOP FIND
  //
  // IMPORTANT:
  // STOP ONLY STOPS THE FINDING ACTION.
  //
  // BLE REMAINS CONNECTED.
  // ============================================================

  Future<void> _stopFinding() async {
    final device = _bluetoothDevice;

    if (device == null) {
      if (mounted) {
        Navigator.pop(context);
      }

      return;
    }

    if (mounted) {
      setState(() {
        _isStopping = true;
        _statusText = "Stopping...";
        _subtitleText =
            "Turning off SmartFinder";
      });
    }

    _animationController.stop();

    try {
      final stopped =
          await _bleService.sendStopCommand(
        device,
      );

      if (!mounted) return;

      if (stopped) {
        setState(() {
          _isFinding = false;
          _isStopping = false;
          _statusText =
              "SmartFinder connected";
          _subtitleText =
              "Finding stopped. Device remains connected.";
        });
      } else {
        setState(() {
          _isFinding = false;
          _isStopping = false;
          _statusText =
              "Finding stopped";
          _subtitleText =
              "Bluetooth connection may have been lost.";
        });
      }
    } catch (e) {
      debugPrint(
        "STOP ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        _isFinding = false;
        _isStopping = false;
        _statusText =
            "Finding stopped";
        _subtitleText =
            "Bluetooth connection may have been lost.";
      });
    }
  }

  // ============================================================
  // DISPOSE
  //
  // IMPORTANT:
  // DO NOT DISCONNECT HERE.
  //
  // The BLE connection should remain alive while the app
  // session is active.
  // ============================================================

  @override
  void dispose() {
    _animationController.dispose();

    // DO NOT call disconnectDevice() here.
    //
    // The connection is owned by the active app session.
    // The HomeScreen BLE listener will track its state.

    _bleService.dispose();

    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFCFDFF),

      body: SafeArea(
        child: Column(
          children: [
            // ----------------------------------------------------
            // HEADER
            // ----------------------------------------------------

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal:
                    Responsive.w(
                  context,
                  0.04,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      if (_isFinding &&
                          _bluetoothDevice != null) {
                        await _stopFinding();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(
                      Icons
                          .arrow_back_ios_new_rounded,
                      color: _textDark,
                    ),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(),
                  ),

                  SizedBox(
                    width:
                        Responsive.w(
                      context,
                      0.035,
                    ),
                  ),

                  Text(
                    "Find Device",
                    style: TextStyle(
                      color: _textDark,
                      fontSize:
                          Responsive.font(
                        context,
                        5.0,
                      ),
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // ----------------------------------------------------
            // MAIN CONTENT
            // ----------------------------------------------------

            Expanded(
              child: Center(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal:
                        Responsive.w(
                      context,
                      0.055,
                    ),
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation:
                            _animationController,
                        builder:
                            (context, child) {
                          final scale =
                              1.0 +
                                  (_animationController
                                          .value *
                                      0.12);

                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width:
                                  Responsive.w(
                                context,
                                0.30,
                              ),
                              height:
                                  Responsive.w(
                                context,
                                0.30,
                              ),
                              decoration:
                                  BoxDecoration(
                                shape:
                                    BoxShape.circle,
                                color: _softBlue,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        _blue
                                            .withValues(
                                      alpha: 0.08,
                                    ),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons
                                    .search_rounded,
                                color: _blue,
                                size:
                                    Responsive.w(
                                  context,
                                  0.15,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(
                        height:
                            Responsive.h(
                          context,
                          0.035,
                        ),
                      ),

                      Text(
                        _statusText,
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: _textDark,
                          fontSize:
                              Responsive.font(
                            context,
                            5.2,
                          ),
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      SizedBox(
                        height:
                            Responsive.h(
                          context,
                          0.012,
                        ),
                      ),

                      Text(
                        _subtitleText,
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: _textGrey,
                          fontSize:
                              Responsive.font(
                            context,
                            3.4,
                          ),
                        ),
                      ),

                      SizedBox(
                        height:
                            Responsive.h(
                          context,
                          0.045,
                        ),
                      ),

                      SizedBox(
                        width: double.infinity,
                        height:
                            Responsive.h(
                          context,
                          0.065,
                        ),
                        child:
                            ElevatedButton(
                          onPressed:
                              (_isFinding &&
                                      !_isStopping)
                                  ? _stopFinding
                                  : null,
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                _blue,
                            foregroundColor:
                                Colors.white,
                            disabledBackgroundColor:
                                Colors
                                    .grey
                                    .shade300,
                            disabledForegroundColor:
                                Colors.white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                          ),
                          child: Text(
                            _isStopping
                                ? "Stopping..."
                                : "Stop Finding",
                            style: TextStyle(
                              fontSize:
                                  Responsive.font(
                                context,
                                3.7,
                              ),
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}