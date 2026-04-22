import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RatingScreen(),
    );
  }
}

class RatingScreen extends StatefulWidget {
  final String? serviceCenterId;

  const RatingScreen({Key? key, this.serviceCenterId}) : super(key: key);

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  final String baseUrl = "http://10.0.2.2:5000/api"; 

  // ================= SUBMIT FEEDBACK =================
  Future<void> _submitFeedback() async {
    final currentUser = await AuthService().getCurrentUser();

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please log in to submit feedback"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_feedbackController.text.isEmpty || _selectedRating == 0) return;

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
        setState(() {
          _selectedRating = 0;
        });

        _showSnackBar();
        setState(() {}); // refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to submit feedback"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error submitting feedback: $e");
    }
  }

  // ================= FETCH FEEDBACKS =================
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
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching feedbacks: $e");
      return [];
    }
  }

  // ================= AVERAGE RATING =================
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
            title: const Text("Submit Review"),
            content: const Text(
              "Are you sure you want to submit your feedback?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _submitFeedback();
                },
                child: const Text("Yes"),
              ),
            ],
          ),
    );
  }

  void _showSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Thank you for your feedback!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 72, 64, 122),
        foregroundColor: Colors.white,
        title: Text(
          widget.serviceCenterId != null
              ? "${widget.serviceCenterId} Reviews"
              : "Reviews",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ⭐ Rating Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    size: 40,
                    color:
                        _selectedRating > index ? Colors.orange : Colors.grey,
                  ),
                  onPressed: () => setState(() => _selectedRating = index + 1),
                );
              }),
            ),

            const SizedBox(height: 20),

            // 📝 Feedback Text
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Add feedback here!",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _showSubmitDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 60, 98),
                minimumSize: const Size(double.infinity, 55),
              ),
              child: const Text("Submit"),
            ),

            const SizedBox(height: 20),

            // ================= FEEDBACK LIST =================
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchFeedbacks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final feedbacks = snapshot.data ?? [];

                  if (feedbacks.isEmpty) {
                    return const Center(child: Text("No feedback available"));
                  }

                  final avg = _calculateAverageRating(feedbacks);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Average Rating: ${avg.toStringAsFixed(1)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text("Total Feedbacks: ${feedbacks.length}"),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: feedbacks.length,
                          itemBuilder: (context, index) {
                            final feedback = feedbacks[index];

                            return Card(
                              child: ListTile(
                                title: Text(feedback['name'] ?? 'Anonymous'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: List.generate(5, (starIndex) {
                                        return Icon(
                                          Icons.star,
                                          size: 18,
                                          color:
                                              starIndex <
                                                      (feedback['rating'] ?? 0)
                                                  ? Colors.orange
                                                  : Colors.grey,
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(feedback['feedback'] ?? ''),
                                  ],
                                ),
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
