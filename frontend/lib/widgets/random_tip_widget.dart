import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';

/// RandomTipWidget
/// Fetches short tips from backend via `ApiService.getTips()` and
/// falls back to provided `fallbackTips` when offline.
class RandomTipWidget extends StatefulWidget {
  final List<String>? fallbackTips;
  final bool compact;

  const RandomTipWidget({super.key, this.fallbackTips, this.compact = false});

  @override
  State<RandomTipWidget> createState() => _RandomTipWidgetState();
}

class _RandomTipWidgetState extends State<RandomTipWidget> {
  List<String> _tips = [];
  String _current = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  Future<void> _loadTips() async {
    setState(() { _loading = true; });
    try {
      final fetched = await ApiService.getTips();
      if (fetched.isNotEmpty) {
        _tips = fetched;
      } else if (widget.fallbackTips != null && widget.fallbackTips!.isNotEmpty) {
        _tips = widget.fallbackTips!;
      }
    } catch (_) {
      if (widget.fallbackTips != null && widget.fallbackTips!.isNotEmpty) {
        _tips = widget.fallbackTips!;
      }
    }

    if (_tips.isEmpty) {
      _tips = [
        'Pensez à alterner vos cultures pour préserver la fertilité du sol.',
        'Irriguez tôt le matin pour limiter l\'évaporation.',
      ];
    }

    setState(() {
      _current = _tips[Random().nextInt(_tips.length)];
      _loading = false;
    });
  }

  void _refresh() {
    if (_tips.isEmpty) return;
    setState(() { _current = _tips[Random().nextInt(_tips.length)]; });
    HapticFeedback.selectionClick();
  }

  void _copy() {
    if (_current.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _current));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Astuce copiée')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF12210D).withOpacity(0.9) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Color(0xFF6B8E23), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: _loading
                ? const SizedBox(height: 18, child: LinearProgressIndicator())
                : Text(
                    _current,
                    style: TextStyle(
                      fontSize: widget.compact ? 12 : 13,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade200 : const Color(0xFF2D5016),
                    ),
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6B8E23)),
            onPressed: _loading ? null : _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Color(0xFF6B8E23)),
            onPressed: _loading ? null : _copy,
          ),
        ],
      ),
    );
  }
}
