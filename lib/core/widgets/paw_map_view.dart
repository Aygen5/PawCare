import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Reusable OpenStreetMap widget for PawCare.
/// Renders dynamic GPS routes, sitter & dog markers, and interactive map controls.
class PawMapView extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final List<LatLng> routePoints;
  final LatLng? currentPosition;
  final LatLng? startPoint;
  final String? walkerName;
  final String? petName;
  final String? avatarAsset;
  final bool showControls;
  final bool isInteractive;
  final VoidCallback? onRecenter;

  const PawMapView({
    super.key,
    this.initialCenter = const LatLng(40.9632, 29.0621), // Caddebostan Sahil default
    this.initialZoom = 15.5,
    this.routePoints = const [],
    this.currentPosition,
    this.startPoint,
    this.walkerName,
    this.petName,
    this.avatarAsset,
    this.showControls = true,
    this.isInteractive = true,
    this.onRecenter,
  });

  @override
  State<PawMapView> createState() => _PawMapViewState();
}

class _PawMapViewState extends State<PawMapView> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant PawMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-center if current position moved and user hasn't explicitly disabled it
    if (widget.currentPosition != null &&
        widget.currentPosition != oldWidget.currentPosition) {
      try {
        _mapController.move(widget.currentPosition!, _mapController.camera.zoom);
      } catch (_) {
        // Map controller might not be attached yet
      }
    }
  }

  void _recenter() {
    final target = widget.currentPosition ??
        (widget.routePoints.isNotEmpty
            ? widget.routePoints.last
            : widget.initialCenter);
    _mapController.move(target, 16.0);
    widget.onRecenter?.call();
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activePosition = widget.currentPosition ??
        (widget.routePoints.isNotEmpty
            ? widget.routePoints.last
            : widget.initialCenter);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: widget.initialZoom,
              minZoom: 3.0,
              maxZoom: 19.0,
              interactionOptions: InteractionOptions(
                flags: widget.isInteractive
                    ? InteractiveFlag.all
                    : InteractiveFlag.none,
              ),
            ),
            children: [
              // OpenStreetMap Tile Layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pawcare.app',
                maxZoom: 19,
              ),

              // Polyline Rota Katmanı
              if (widget.routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    // Arka plan kontrast gölgesi
                    Polyline(
                      points: widget.routePoints,
                      strokeWidth: 6.0,
                      color: AppColors.primary.withValues(alpha: 0.35),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                    // Ana dinamik rota çizgisi
                    Polyline(
                      points: widget.routePoints,
                      strokeWidth: 4.0,
                      color: AppColors.primary,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),

              // Marker Katmanı
              MarkerLayer(
                markers: [
                  // Başlangıç Noktası Markeri
                  if (widget.startPoint != null)
                    Marker(
                      point: widget.startPoint!,
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                  // Canlı Konum / Gezdirici & Köpek Markeri
                  Marker(
                    point: activePosition,
                    width: 72,
                    height: 80,
                    child: _buildWalkerMarker(context, isDark),
                  ),
                ],
              ),
            ],
          ),

          // Harita Kontrol Butonları (Zoom & Recenter)
          if (widget.showControls)
            Positioned(
              right: 12,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapButton(
                    icon: Icons.my_location_rounded,
                    tooltip: 'Konuma Odaklan',
                    onPressed: _recenter,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildMapButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Yakınlaştır',
                    onPressed: _zoomIn,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 4),
                  _buildMapButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'Uzaklaştır',
                    onPressed: _zoomOut,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWalkerMarker(BuildContext context, bool isDark) {
    final label = widget.walkerName != null
        ? (widget.petName != null
            ? '${widget.walkerName} & ${widget.petName}'
            : widget.walkerName!)
        : 'Canlı Konum';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sitter avatar ve pulse halkası
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: widget.avatarAsset != null
                  ? ClipOval(
                      child: Image.asset(
                        widget.avatarAsset!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.pets_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.pets_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Küçük isim etiketi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            label,
            style: AppTypography.labelTag.copyWith(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
        ),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}
