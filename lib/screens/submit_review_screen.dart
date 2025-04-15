import 'package:flutter/material.dart';
import '../services/rating_service.dart';

class SubmitReviewScreen extends StatefulWidget {
  final String ratedUserId;
  final String? rideId;

  const SubmitReviewScreen({
    Key? key,
    required this.ratedUserId,
    this.rideId,
  }) : super(key: key);

  @override
  State<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ratingService = RatingService();
  final _reviewController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _ratingService.submitRating(
        ratedUserId: widget.ratedUserId,
        rating: _rating,
        review: _reviewController.text,
        rideId: widget.rideId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Review'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'How was your experience?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: Icon(
                    Icons.star,
                    size: 40,
                    color: index < _rating ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: 'Write your review',
                border: OutlineInputBorder(),
                hintText: 'Share your experience...',
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please write a review';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
} 