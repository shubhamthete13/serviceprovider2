import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EarningsPayoutPage extends StatefulWidget {
  const EarningsPayoutPage({super.key});

  @override
  _EarningsPayoutPageState createState() => _EarningsPayoutPageState();
}

class _EarningsPayoutPageState extends State<EarningsPayoutPage> {
  String? providerPhone;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProviderPhone();
  }

  Future<void> _fetchProviderPhone() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to view earnings.')),
      );
      Navigator.pushReplacementNamed(context, '/signin');
      return;
    }

    setState(() {
      providerPhone = user.phoneNumber!.replaceFirst('+91', '');
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & Payouts'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .where('provider_id', isEqualTo: providerPhone)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No earnings data available.'));
          }

          double totalEarnings = 0.0;
          double pendingAmount = 0.0;
          double completedAmount = 0.0;
          Map<String, double> paymentTypeMap = {};

          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            double amount = data['amount']?.toDouble() ?? 0.0;
            totalEarnings += amount;
            paymentTypeMap.update(data['payment_method'], (val) => val + amount,
                ifAbsent: () => amount);

            if (data['status'] == 'completed') {
              completedAmount += amount;
            } else {
              pendingAmount += amount;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard('Total Earnings', totalEarnings, Colors.blue),
                _buildSummaryCard(
                    'Pending Payouts', pendingAmount, Colors.orange),
                _buildSummaryCard(
                    'Completed Payouts', completedAmount, Colors.green),
                const SizedBox(height: 20),
                const Text('Earnings by Payment Method:',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView(
                    children: paymentTypeMap.entries.map((entry) {
                      return ListTile(
                        title: Text(entry.key.toUpperCase()),
                        trailing: Text('₹${entry.value.toStringAsFixed(2)}'),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        trailing: Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
