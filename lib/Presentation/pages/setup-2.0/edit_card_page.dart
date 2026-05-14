import 'package:flutter/material.dart';
import 'package:payment_card/payment_card.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/widgets/reuseable_button.dart';

class EditCardPage extends StatelessWidget {
  final PaymentCard card;
  
  const EditCardPage({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff232323),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Edit Card',
          style: TextStyle(
            color: themeColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xff232323),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              // Show delete confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xff414141),
                  title: const Text('Delete Card?', 
                    style: TextStyle(color: Colors.white)),
                  content: const Text('Are you sure you want to delete this card?',
                    style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      child: const Text('Cancel',
                        style: TextStyle(color: Colors.white70)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        // Handle delete
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _buildCardForm(context, isEdit: true),
    );
  }
}

Widget _buildCardForm(BuildContext context, {required bool isEdit}) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Card Preview
        const PaymentCard(
          cardIssuerIcon: CardIcon(icon: Icons.credit_card),
          backgroundColor: Colors.blue,
          backgroundGradient: LinearGradient(
            colors: [Colors.purple, Colors.indigo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          currency: Text('USD'),
          cardNumber: '•••• •••• •••• ••••',
          validity: 'MM/YY',
          holder: 'CARD HOLDER',
          isStrict: false,
          cardNetwork: CardNetwork.visa, backgroundImage: null, 
        ),
        const SizedBox(height: 24),
        // Form Fields
        _buildTextField('Card Holder Name', Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextField('Card Number', Icons.credit_card),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField('Expiry', Icons.calendar_today),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField('CVC', Icons.lock_outline),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (!isEdit) ...[
          Row(
            children: [
              Checkbox(
                value: false,
                onChanged: (value) {},
                fillColor: MaterialStateProperty.all(themeColor),
              ),
              const Text(
                'Set as default payment method',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        ReuseableButton(
          title: isEdit ? 'Save Changes' : 'Done',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

Widget _buildTextField(String label, IconData icon) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xff414141),
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        icon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
    ),
  );
}