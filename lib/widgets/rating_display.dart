import 'package:flutter/material.dart';
import 'package:rating_service.dart';

class RatingDisplay extends StatelessWidget {
  final String userId;
  final bool showAverage;
  final bool showReviews;
  final int maxReviews;

  const RatingDisplay({
    Key? key,
    required this.userId,
    this.showAverage = true,
    this.showReviews = false,
    this.maxReviews = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ratingService = RatingService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showAverage)
          StreamBuilder<double>(
            stream: ratingService.getUserAverageRating(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final averageRating = snapshot.data ?? 0.0;
              return Row(
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      index < averageRating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        if (showReviews)
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: ratingService.getUserRatings(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final ratings = snapshot.data ?? [];
              if (ratings.isEmpty) {
                return const Text('No reviews yet');
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  ...ratings.take(maxReviews).map((rating) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
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
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rating['review'] as String,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (ratings.length > maxReviews)
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to full reviews page
                      },
                      child: Text(
                        'View all ${ratings.length} reviews',
                        style: const TextStyle(color: Colors.teal),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
} 