import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';

class ConsultationViewScreen extends StatefulWidget {
  final int serviceRequestId;
  final bool isVeterinarian;

  const ConsultationViewScreen({
    Key? key,
    required this.serviceRequestId,
    this.isVeterinarian = false,
  }) : super(key: key);

  @override
  State<ConsultationViewScreen> createState() => _ConsultationViewScreenState();
}

class _ConsultationViewScreenState extends State<ConsultationViewScreen> {
  bool _isLoading = true;
  List<dynamic> _consultations = [];

  static const Color _primaryColor = Colors.brown;

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    setState(() => _isLoading = true);

    try {
      // Note: This would require adding a method to get consultations
      // For now, we'll implement the UI and assume data is passed
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        foregroundColor: textColor,
        title: const Text(
          'Consultations',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              )
            : _consultations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune consultation pour le moment',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _consultations.length,
                    itemBuilder: (context, index) {
                      final consultation = _consultations[index];
                      return ConsultationCard(
                        consultation: consultation,
                        isVeterinarian: widget.isVeterinarian,
                      );
                    },
                  ),
      ),
    );
  }
}

class ConsultationCard extends StatefulWidget {
  final dynamic consultation;
  final bool isVeterinarian;

  const ConsultationCard({
    Key? key,
    required this.consultation,
    required this.isVeterinarian,
  }) : super(key: key);

  @override
  State<ConsultationCard> createState() => _ConsultationCardState();
}

class _ConsultationCardState extends State<ConsultationCard> {
  int? _rating;
  final _feedbackController = TextEditingController();
  bool _isSubmittingRating = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez une note')),
      );
      return;
    }

    setState(() => _isSubmittingRating = true);

    try {
      // Note: This would need the actual request ID
      // For now we'll just show the success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci pour votre avis!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingRating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    final consultationType = widget.consultation['consultation_type'] ?? 'conseil_écrit';
    final typeLabel = _getConsultationTypeLabel(consultationType);
    final hasRating = widget.consultation['farmer_rating'] != null;

    return Card(
      color: bgCard,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFFE8E2D8).withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(widget.consultation['created_at']),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                if (widget.consultation['cost'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.consultation['cost']} XAF',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Advice
            Text(
              'Conseil professionnel',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.consultation['advice'] ?? 'Aucun conseil fourni',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            // Recommendations
            if (widget.consultation['recommendations'] != null) ...[
              Text(
                'Recommandations',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue[100]!,
                  ),
                ),
                child: Text(
                  widget.consultation['recommendations'],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[900],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Schedule
            if (widget.consultation['scheduling'] != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.brown,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.consultation['scheduling'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.brown,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Rating Section (for farmers)
            if (!widget.isVeterinarian && !hasRating) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Votre avis',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[900],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () => setState(() => _rating = index + 1),
                          icon: Icon(
                            _rating != null && _rating! > index
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 2,
                      style: TextStyle(color: Colors.amber[900]),
                      decoration: InputDecoration(
                        hintText: 'Commentaire (optionnel)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: Colors.amber[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: Colors.amber[400]!,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmittingRating
                            ? null
                            : _submitRating,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmittingRating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Soumettre l\'avis'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (hasRating) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Note: ${widget.consultation['farmer_rating']}/5',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (widget.consultation['farmer_feedback'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.consultation['farmer_feedback'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getConsultationTypeLabel(String type) {
    switch (type) {
      case 'written_advice':
        return '📝 Conseil écrit';
      case 'whatsapp_call':
        return '💬 Appel WhatsApp';
      case 'video_call':
        return '📹 Appel vidéo';
      case 'on_site_visit':
        return '🏥 Visite sur site';
      default:
        return 'Consultation';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
