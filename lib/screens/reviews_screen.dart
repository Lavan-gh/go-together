import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_together/theme/app_theme.dart';

class ReviewsScreen extends StatefulWidget {
  @override
  _ReviewsScreenState createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  double _averageRating = 4.5;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (user == null) return;

    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: user!.uid)
          .get();

      if (reviewsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in reviewsSnapshot.docs) {
          totalRating += doc.data()['rating'] ?? 0;
        }
        setState(() {
          _averageRating = totalRating / reviewsSnapshot.docs.length;
          _totalReviews = reviewsSnapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews & Ratings'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRatingSummary(),
            SizedBox(height: 24),
            _buildReviewList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Rating',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$_totalReviews reviews',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('5 stars'),
                Text('80%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: user?.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(
                  Icons.star_border,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No reviews yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final review = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(review['riderName'][0]),
                ),
                title: Row(
                  children: [
                    Text(review['riderName']),
                    SizedBox(width: 8),
                    ...List.generate(
                      5,
                      (i) => Icon(
                        Icons.star,
                        size: 16,
                        color: i < review['rating'] ? Colors.amber : Colors.grey,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['comment'] ?? ''),
                    SizedBox(height: 4),
                    Text(
                      review['timestamp'].toDate().toString().split(' ')[0],
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
} 