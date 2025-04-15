import 'package:flutter/material.dart';
import 'package:rating_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingScreen extends StatefulWidget {
  final String rideId;
  final String ratedUserId;
  final String ratedUserName;

  const RatingScreen({
    Key? key,
    required this.rideId,
    required this.ratedUserId,
    required this.ratedUserName,
  }) : super(key: key);

  @override
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final RatingService _ratingService = RatingService();
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingRating();
  }

  Future<void> _loadExistingRating() async {
    final rating = await _ratingService.getRideRating(widget.rideId);
    if (rating != null) {
      setState(() {
        _rating = (rating['rating'] as num).toDouble();
        _reviewController.text = rating['review'] as String;
      });
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _ratingService.submitRating(
        rideId: widget.rideId,
        ratedUserId: widget.ratedUserId,
        rating: _rating,
        review: _reviewController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting rating: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Ride'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate ${widget.ratedUserName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                    onPressed: () {
                      setState(() => _rating = index + 1.0);
                    },
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Write a Review',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Rating',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Previous Ratings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _ratingService.getUserRatings(widget.ratedUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ratings = snapshot.data ?? [];
                if (ratings.isEmpty) {
                  return const Center(
                    child: Text('No ratings yet'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ratings.length,
                  itemBuilder: (context, index) {
                    final rating = ratings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ...List.generate(
                                  5,
                                  (i) => Icon(
                                    i < (rating['rating'] as num).toDouble()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    (rating['timestamp'] as num).toInt(),
                                  ).toString().split(' ')[0],
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              rating['review'] as String,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
} 