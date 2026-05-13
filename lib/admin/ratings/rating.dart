// lib/admin/ratings/rating.dart
import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class RatingScreen extends StatefulWidget {
  final String? serviceCenterId;

  const RatingScreen({Key? key, this.serviceCenterId}) : super(key: key);

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  final String baseUrl = 'http://10.0.2.2:5000/api';

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final currentUser = await AuthService().getCurrentUser();

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Please log in to submit feedback',
            style: GoogleFonts.jost(color: Colors.white),
          ),
        ),
      );
      return;
    }

    if (_feedbackController.text.isEmpty || _selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Please select a rating and write feedback.',
            style: GoogleFonts.jost(color: Colors.white),
          ),
        ),
      );
      return;
    }

    final feedback = {
      'name': currentUser['name'] ?? 'Anonymous',
      'userId': currentUser['uid'],
      'date': DateTime.now().toIso8601String(),
      'rating': _selectedRating,
      'feedback': _feedbackController.text,
      'serviceCenterId': widget.serviceCenterId,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/feedbacks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(feedback),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _feedbackController.clear();
        setState(() => _selectedRating = 0);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text(
                'Thank you for your feedback!',
                style: GoogleFonts.jost(color: Colors.white),
              ),
            ),
          );
          setState(() {});
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text(
                'Failed to submit feedback.',
                style: GoogleFonts.jost(color: Colors.white),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Error: $e',
              style: GoogleFonts.jost(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFeedbacks() async {
    try {
      final url =
          widget.serviceCenterId != null
              ? '$baseUrl/feedbacks?serviceCenterId=${widget.serviceCenterId}'
              : '$baseUrl/feedbacks';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  double _calculateAverageRating(List<Map<String, dynamic>> feedbacks) {
    if (feedbacks.isEmpty) return 0.0;
    int totalRating = 0;
    for (var feedback in feedbacks) {
      totalRating += (feedback['rating'] ?? 0) as int;
    }
    return totalRating / feedbacks.length;
  }

  void _showSubmitDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.borderGold),
            ),
            title: Text(
              'Submit Review',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            content: Text(
              'Are you sure you want to submit your feedback?',
              style: GoogleFonts.jost(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'No',
                  style: GoogleFonts.jost(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _submitFeedback();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.obsidian,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Yes',
                  style: GoogleFonts.jost(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.richBlack,
      appBar: AppBar(
        backgroundColor: AppColors.obsidian,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.gold),
        title: Text(
          widget.serviceCenterId != null ? 'Reviews' : 'Reviews',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Write a Review ──────────────────────────────────────────
            Text(
              'Write a Review',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            goldDivider(),

            // ── Star Rating ─────────────────────────────────────────────
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final filled = _selectedRating > index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRating = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 44,
                        color: filled ? AppColors.gold : AppColors.textMuted,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                _selectedRating == 0
                    ? 'Tap to rate'
                    : [
                      '',
                      'Poor',
                      'Fair',
                      'Good',
                      'Very Good',
                      'Excellent',
                    ][_selectedRating],
                style: GoogleFonts.jost(
                  fontSize: 13,
                  color:
                      _selectedRating == 0
                          ? AppColors.textMuted
                          : AppColors.gold,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Feedback Text Field ─────────────────────────────────────
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              style: GoogleFonts.jost(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Write your feedback here...',
                hintStyle: GoogleFonts.jost(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGold),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGold),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.gold,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 16),

            // ── Submit Button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showSubmitDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.obsidian,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'SUBMIT REVIEW',
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.obsidian,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Reviews List ────────────────────────────────────────────
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchFeedbacks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    );
                  }

                  final feedbacks = snapshot.data ?? [];

                  if (feedbacks.isEmpty) {
                    return Center(
                      child: Text(
                        'No reviews yet.',
                        style: GoogleFonts.jost(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  final avg = _calculateAverageRating(feedbacks);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Average rating banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.gold.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.gold,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  avg.toStringAsFixed(1),
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gold,
                                  ),
                                ),
                                Text(
                                  '${feedbacks.length} review(s)',
                                  style: GoogleFonts.jost(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Reviews
                      Expanded(
                        child: ListView.builder(
                          itemCount: feedbacks.length,
                          itemBuilder: (context, index) {
                            final feedback = feedbacks[index];
                            final rating = (feedback['rating'] ?? 0) as int;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.borderGold),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            AppColors.surfaceElevated,
                                        child: Text(
                                          (feedback['name'] ?? 'A')
                                              .toString()
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: GoogleFonts.jost(
                                            color: AppColors.gold,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          feedback['name'] ?? 'Anonymous',
                                          style: GoogleFonts.jost(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (i) => Icon(
                                            i < rating
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded,
                                            size: 14,
                                            color:
                                                i < rating
                                                    ? AppColors.gold
                                                    : AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    feedback['feedback'] ?? '',
                                    style: GoogleFonts.jost(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
