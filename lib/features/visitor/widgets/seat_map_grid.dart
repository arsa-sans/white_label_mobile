import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

// ─── Seat Model ───────────────────────────────────────────────────────────────

enum SeatStatus { available, taken, selected, locked }

class SeatData {
  final String id;
  final String label;      // e.g. "A1", "B12"
  final String zone;       // e.g. "VIP", "Regular", "Floor"
  final int price;
  SeatStatus status;

  SeatData({
    required this.id,
    required this.label,
    required this.zone,
    required this.price,
    this.status = SeatStatus.available,
  });
}

// ─── SeatMapGrid Widget ───────────────────────────────────────────────────────

/// An interactive seat-selection grid.
///
/// [seats] is a 2-D list (rows × columns) of [SeatData].
/// Null entries render as aisles/gaps.
/// [onSeatTapped] is called whenever the user toggles a seat.
/// [maxSelectable] limits how many seats can be selected at once (default 4).
class SeatMapGrid extends StatefulWidget {
  final List<List<SeatData?>> seats;
  final void Function(List<SeatData> selected) onSeatTapped;
  final int maxSelectable;

  const SeatMapGrid({
    super.key,
    required this.seats,
    required this.onSeatTapped,
    this.maxSelectable = 4,
  });

  @override
  State<SeatMapGrid> createState() => _SeatMapGridState();
}

class _SeatMapGridState extends State<SeatMapGrid> {
  final Set<String> _selected = {};

  Color _colorFor(SeatStatus status, bool isSelected) {
    if (isSelected) return AppTheme.primaryColor;
    switch (status) {
      case SeatStatus.available:
        return AppTheme.cardDark;
      case SeatStatus.taken:
        return const Color(0xFF1A0A0A);
      case SeatStatus.locked:
        return const Color(0xFF1A1400);
      case SeatStatus.selected:
        return AppTheme.primaryColor;
    }
  }

  Color _borderFor(SeatStatus status, bool isSelected) {
    if (isSelected) return AppTheme.primaryColor;
    switch (status) {
      case SeatStatus.available:
        return AppTheme.cardBorder;
      case SeatStatus.taken:
        return AppTheme.dangerColor.withValues(alpha: 0.4);
      case SeatStatus.locked:
        return AppTheme.warningColor.withValues(alpha: 0.4);
      case SeatStatus.selected:
        return AppTheme.primaryColor;
    }
  }

  Color _textFor(SeatStatus status, bool isSelected) {
    if (isSelected) return Colors.white;
    switch (status) {
      case SeatStatus.available:
        return AppTheme.slate300;
      case SeatStatus.taken:
        return AppTheme.dangerColor.withValues(alpha: 0.5);
      case SeatStatus.locked:
        return AppTheme.warningColor.withValues(alpha: 0.6);
      case SeatStatus.selected:
        return Colors.white;
    }
  }

  void _onTap(SeatData seat) {
    if (seat.status == SeatStatus.taken || seat.status == SeatStatus.locked) {
      HapticFeedback.lightImpact();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(seat.id)) {
        _selected.remove(seat.id);
      } else {
        if (_selected.length >= widget.maxSelectable) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maksimal ${widget.maxSelectable} kursi per transaksi.'),
              duration: const Duration(seconds: 2),
              backgroundColor: AppTheme.warningColor,
            ),
          );
          return;
        }
        _selected.add(seat.id);
      }
    });

    // Collect all selected seat objects across all rows.
    final selectedSeats = widget.seats
        .expand((row) => row)
        .whereType<SeatData>()
        .where((s) => _selected.contains(s.id))
        .toList();
    widget.onSeatTapped(selectedSeats);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Stage banner ────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.3),
                AppTheme.secondaryColor.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
          ),
          child: const Center(
            child: Text(
              '🎤  PANGGUNG / STAGE  🎤',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppTheme.slate300,
                letterSpacing: 2,
              ),
            ),
          ),
        ),

        // ── Seat grid ────────────────────────────────────────────────────────
        ...widget.seats.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((seat) {
                if (seat == null) {
                  // Aisle gap
                  return const SizedBox(width: 32, height: 32);
                }
                final isSelected = _selected.contains(seat.id);
                return GestureDetector(
                  onTap: () => _onTap(seat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 34,
                    height: 30,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _colorFor(seat.status, isSelected),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _borderFor(seat.status, isSelected),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        seat.label,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: _textFor(seat.status, isSelected),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),

        const SizedBox(height: 16),

        // ── Legend ───────────────────────────────────────────────────────────
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: const [
            _LegendItem(color: AppTheme.cardDark, border: AppTheme.cardBorder, label: 'Tersedia'),
            _LegendItem(color: AppTheme.primaryColor, border: AppTheme.primaryColor, label: 'Dipilih'),
            _LegendItem(color: Color(0xFF1A0A0A), border: Color(0xFF7F1D1D), label: 'Terisi'),
            _LegendItem(color: Color(0xFF1A1400), border: Color(0xFF78350F), label: 'Terkunci'),
          ],
        ),

        const SizedBox(height: 12),

        // ── Selection Summary ─────────────────────────────────────────────────
        if (_selected.isNotEmpty)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_seat, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  '${_selected.length} kursi dipilih',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                _TotalPrice(
                  seats: widget.seats
                      .expand((r) => r)
                      .whereType<SeatData>()
                      .where((s) => _selected.contains(s.id))
                      .toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color border;
  final String label;

  const _LegendItem({
    required this.color,
    required this.border,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: AppTheme.slate400, fontSize: 11)),
      ],
    );
  }
}

class _TotalPrice extends StatelessWidget {
  final List<SeatData> seats;

  const _TotalPrice({required this.seats});

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );

  @override
  Widget build(BuildContext context) {
    final total = seats.fold<int>(0, (sum, s) => sum + s.price);
    return Text(
      'Rp ${_fmt(total)}',
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        color: AppTheme.accentColor,
        fontSize: 14,
      ),
    );
  }
}
