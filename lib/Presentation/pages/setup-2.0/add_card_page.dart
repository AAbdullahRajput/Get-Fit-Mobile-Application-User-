import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/widgets/reuseable_button.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:payment_card/payment_card.dart';

class AddCardPage extends StatelessWidget {
  const AddCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: _buildCardForm(context, isEdit: false),
          ),

          // Back button overlay
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                    backgroundColor: Colors.black54,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildCardForm(BuildContext context, {required bool isEdit}) {
  return SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            color: context.textColor,
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
          cardNetwork: CardNetwork.visa,
          backgroundImage: null,
        ),
        const SizedBox(height: 24),
        // Form Fields
        _buildTextField(context, 'Card Holder Name', Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextField(context, 'Card Number', Icons.credit_card),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(context, 'Expiry', Icons.calendar_today),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(context, 'CVC', Icons.lock_outline),
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
              Text(
                'Set as default payment method',
                style: TextStyle(color: context.textColor),
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

Widget _buildTextField(BuildContext context, String label, IconData icon) {
  return Container(
    decoration: BoxDecoration(
      color: context.cardBgColor,
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: TextField(
      style: TextStyle(color: context.textColor),
      decoration: InputDecoration(
        icon: Icon(icon, color: context.subtextColor),
        labelText: label,
        labelStyle: TextStyle(color: context.subtextColor),
        border: InputBorder.none,
      ),
    ),
  );
}