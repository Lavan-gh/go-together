import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/payment_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _amountController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy HH:mm');
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addMoney() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _paymentService.addToWallet(amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Money added successfully')),
        );
        _amountController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add money: $e')),
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
        title: const Text('Wallet'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet Balance Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Current Balance',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<double>(
                      stream: Stream.fromFuture(_paymentService.getWalletBalance()),
                      builder: (context, snapshot) {
                        final balance = snapshot.data ?? 0.0;
                        return Text(
                          '\$${balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Add Money Section
            const Text(
              'Add Money',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addMoney,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Add Money',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            // Transaction History
            const Text(
              'Transaction History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _paymentService.getTransactionHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
                  return const Center(
                    child: Text('No transactions yet'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final isPayment = transaction['type'] == 'ride_payment';
                    final amount = transaction['amount'] as double;
                    final status = transaction['status'] as String;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          isPayment ? Icons.payment : Icons.account_balance_wallet,
                          color: isPayment ? Colors.red : Colors.green,
                        ),
                        title: Text(
                          isPayment ? 'Ride Payment' : 'Wallet Top-up',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          _dateFormat.format(
                            DateTime.fromMillisecondsSinceEpoch(
                              transaction['timestamp'] as int,
                            ),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isPayment ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (status != 'completed')
                              Text(
                                status,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
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
} 