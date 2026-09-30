import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../models/device_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../locate/locate_screen.dart';
import '../ring/ring_screen.dart';
import '../device_information/device_information_screen.dart';

const Color _blue = Color(0xFF2563EB);
const Color _lightBlue = Color(0xFFEAF2FF);
const Color _textDark = Color(0xFF17233B);
const Color _textGrey = Color(0xFF667085);

const Color _cardBlueStart = Color(0xFFFCFDFF);
const Color _cardBlueEnd = Color(0xFFF8FAFF);
const Color _cardBlueSoft = Color(0xFFF8FAFF);

class DeviceOverviewScreen extends StatefulWidget {
  final DeviceModel device;
  final VoidCallback? onDelete;
  final Function(String newName)? onRename;

  const DeviceOverviewScreen({
    super.key,
    required this.device,
    this.onDelete,
    this.onRename,
  });

  @override
  State<DeviceOverviewScreen> createState() =>
      _DeviceOverviewScreenState();
}

class _DeviceOverviewScreenState
    extends State<DeviceOverviewScreen> {
  // ============================================================
  // LIVE BLE CONNECTION STATE
  // ============================================================

  StreamSubscription<BluetoothConnectionState>?
      _connectionSubscription;

  bool _isConnected = false;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  @override
  void initState() {
    super.initState();
    _setupConnectionListener();
  }

  Future<void> _setupConnectionListener() async {
    final bleId = widget.device.bleId;

    // No saved BLE ID
    if (bleId == null || bleId.isEmpty) {
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
      }
      return;
    }

    try {
      // Recreate the BLE device from the saved ID.
      final device = BluetoothDevice.fromId(bleId);

      // Check the current connection state immediately.
      if (mounted) {
        setState(() {
          _isConnected = device.isConnected;
        });
      }

      // Listen for future connection/disconnection changes.
      _connectionSubscription =
          device.connectionState.listen((state) {
        if (!mounted) return;

        setState(() {
          _isConnected =
              state == BluetoothConnectionState.connected;
        });
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
      }
    }
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // DEVICE ICON
  // ============================================================

  IconData getDeviceIcon(String name) {
    final lower = name.toLowerCase();

    if (lower.contains("backpack")) {
      return Icons.backpack;
    }

    if (lower.contains("wallet")) {
      return Icons.wallet;
    }

    if (lower.contains("key")) {
      return Icons.key;
    }

    if (lower.contains("laptop")) {
      return Icons.laptop_mac;
    }

    if (lower.contains("ear")) {
      return Icons.headphones;
    }

    return Icons.backpack;
  }

  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget actionCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.w(context, 0.025),
          vertical: Responsive.h(context, 0.018),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFCFDFF),
              Color(0xFFF8FAFF),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE6EDF8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.018),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: Responsive.w(context, 0.085),
              height: Responsive.w(context, 0.085),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F5FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: _blue,
                size: Responsive.w(context, 0.045),
              ),
            ),

            SizedBox(
              width: Responsive.w(context, 0.022),
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textDark,
                      fontSize:
                          Responsive.font(context, 3.5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(
                    height: Responsive.h(context, 0.003),
                  ),

                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textGrey,
                      fontSize:
                          Responsive.font(context, 2.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFF98A2B3),
              size: Responsive.w(context, 0.055),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARD GRADIENT
  // ============================================================

  LinearGradient _cardGradient({
    bool stronger = false,
  }) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: stronger
          ? const [
              _cardBlueStart,
              _cardBlueEnd,
            ]
          : const [
              Colors.white,
              _cardBlueSoft,
            ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: Text(
          widget.device.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "rename") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _RenameDeviceScreen(
                      currentName: widget.device.name,
                      onSave: widget.onRename,
                    ),
                  ),
                );
              }

              if (value == "delete") {
                if (widget.onDelete != null) {
                  widget.onDelete!();
                  Navigator.pop(context);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: "rename",
                child: Text("Rename"),
              ),
              PopupMenuItem(
                value: "delete",
                child: Text("Delete Device"),
              ),
            ],
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(
          Responsive.w(context, 0.05),
        ),
        child: Column(
          children: [

            // ==================================================
            // DEVICE HEADER
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [

                // ----------------------------------------------
                // DEVICE IMAGE
                // ----------------------------------------------

                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: Responsive.w(context, 0.31),
                      height: Responsive.w(context, 0.31),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                _blue.withValues(alpha: 0.10),
                            blurRadius: 22,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: Responsive.w(context, 0.27),
                      height: Responsive.w(context, 0.27),
                      padding: EdgeInsets.all(
                        Responsive.w(context, 0.012),
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: _isConnected
                              ? const Color(0xFF35B96B)
                              : const Color(0xFFD1D5DB),
                          width:
                              Responsive.w(context, 0.009),
                        ),
                      ),
                      child: ClipOval(
                        child:
                            widget.device.imagePath != null &&
                                    widget.device.imagePath!
                                        .isNotEmpty
                                ? Image.file(
                                    File(widget
                                        .device.imagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: _lightBlue,
                                    child: Icon(
                                      getDeviceIcon(
                                        widget.device.name,
                                      ),
                                      color: _blue,
                                      size: Responsive.w(
                                          context, 0.10),
                                    ),
                                  ),
                      ),
                    ),
                  ],
                ),

                // ----------------------------------------------
                // SPACE
                // ----------------------------------------------

                SizedBox(
                  width: Responsive.w(context, 0.065),
                ),

                // ----------------------------------------------
                // DEVICE INFORMATION
                // ----------------------------------------------

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [

                      Text(
                        widget.device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _textDark,
                          fontSize:
                              Responsive.font(context, 5.0),
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      SizedBox(
                        height:
                            Responsive.h(context, 0.012),
                      ),

                      // ----------------------------------------
                      // CONNECTION BADGE
                      // ----------------------------------------

                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              Responsive.w(context, 0.028),
                          vertical:
                              Responsive.h(context, 0.007),
                        ),
                        decoration: BoxDecoration(
                          color: _isConnected
                              ? const Color(0xFFE4F7EA)
                              : const Color(0xFFFEECEC),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [

                            Container(
                              width:
                                  Responsive.w(context, 0.018),
                              height:
                                  Responsive.w(context, 0.018),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isConnected
                                    ? const Color(0xFF2DB55D)
                                    : const Color(0xFFEF4444),
                              ),
                            ),

                            SizedBox(
                              width:
                                  Responsive.w(context, 0.018),
                            ),

                            Text(
                              _isConnected
                                  ? "Connected"
                                  : "Disconnected",
                              style: TextStyle(
                                color: _isConnected
                                    ? const Color(0xFF239447)
                                    : const Color(0xFFDC2626),
                                fontSize:
                                    Responsive.font(
                                        context, 3.2),
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ==================================================
            // SPACING
            // ==================================================

            SizedBox(
              height: Responsive.h(context, 0.025),
            ),

            SizedBox(
              height: Responsive.h(context, 0.055),
            ),

            // ==================================================
            // QUICK ACTIONS TITLE
            // ==================================================

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Quick Actions",
                style: TextStyle(
                  color: Color(0xFF17233B),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            SizedBox(
              height: Responsive.h(context, 0.012),
            ),

            // ==================================================
            // QUICK ACTIONS
            // ==================================================

            Row(
              children: [

                // ----------------------------------------------
                // FIND
                // ----------------------------------------------

                Expanded(
                  child: actionCard(
                    context: context,
                    icon: Icons.search_rounded,
                    color: _blue,
                    title: "Find",
                    subtitle: "Find device",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RingScreen(
                            device: widget.device,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(
                  width: Responsive.w(context, 0.025),
                ),

                // ----------------------------------------------
                // LOCATE
                // ----------------------------------------------

                Expanded(
                  child: actionCard(
                    context: context,
                    icon: Icons.location_on_rounded,
                    color: _blue,
                    title: "Locate",
                    subtitle: "Find device",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocateScreen(
                            device: widget.device,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            SizedBox(
              height: Responsive.h(context, 0.03),
            ),

            // ==================================================
            // BATTERY
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                gradient: _cardGradient(),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE9EEF7),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: 0.018),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [

                      const Text(
                        "Battery",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      Text(
                        "${widget.device.battery}%",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value:
                          widget.device.battery / 100,
                      minHeight: 5,
                      backgroundColor:
                          const Color(0xFFE5E7EB),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: Responsive.h(context, 0.018),
            ),

            // ==================================================
            // STATUS
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                gradient: _cardGradient(),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE9EEF7),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: 0.018),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Status",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // --------------------------------------------
                  // CONNECTION STATUS
                  // --------------------------------------------

                  _StatusRow(
                    icon: Icons.bluetooth,
                    label: "Connection",
                    value: _isConnected
                        ? "Connected"
                        : "Disconnected",
                  ),

                  const Divider(height: 14),

                  // --------------------------------------------
                  // BLE SIGNAL
                  // --------------------------------------------

                  _StatusRow(
                    icon: Icons.network_wifi,
                    label: "BLE Signal",
                    value: widget.device.signal,
                  ),

                  const Divider(height: 14),

                  // --------------------------------------------
                  // LAST SEEN
                  // --------------------------------------------

                  _StatusRow(
                    icon: Icons.location_on_outlined,
                    label: "Last Seen",
                    value: widget.device.lastSeen,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // MORE
            // ==================================================

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "More",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // DEVICE INFORMATION
            // ==================================================

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DeviceInformationScreen(
                      device: widget.device,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 17,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Color(0xFFF7FAFF),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE9EEF7),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(
                        alpha: 0.018,
                      ),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [

                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Text(
                            "Device Information",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Color(0xFF1F2937),
                            ),
                          ),

                          SizedBox(height: 3),

                          Text(
                            "View tracker details",
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(
              height: Responsive.h(context, 0.05),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// STATUS ROW
// ==================================================================

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Icon(
          icon,
          size: 19,
          color: Colors.blue,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// RENAME DEVICE SCREEN
// ==================================================================

class _RenameDeviceScreen extends StatefulWidget {
  final String currentName;
  final Function(String newName)? onSave;

  const _RenameDeviceScreen({
    required this.currentName,
    required this.onSave,
  });

  @override
  State<_RenameDeviceScreen> createState() =>
      _RenameDeviceScreenState();
}

class _RenameDeviceScreenState
    extends State<_RenameDeviceScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.currentName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();

    if (name.isEmpty) return;

    widget.onSave?.call(name);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Rename Device"),
      ),

      body: Padding(
        padding: EdgeInsets.all(
          Responsive.w(context, 0.06),
        ),
        child: Column(
          children: [

            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization:
                  TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: "Device name",
                hintText: "Enter device name",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(
              height: Responsive.h(context, 0.03),
            ),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}