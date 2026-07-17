import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

Color _accent(BuildContext context) {
  return context.isDark ? themeColor : const Color(0xFF6B7A00);
}

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _holderController = TextEditingController();
  CardFieldInputDetails? _cardDetails;
  bool _isSaving = false;

  @override
  void dispose() {
    _holderController.dispose();
    super.dispose();
  }

  List<Color> _cardGradient(String? brand) {
    switch (brand) {
      case 'Visa': return [const Color(0xFFB8860B), const Color(0xFFDAA520)];
      case 'MasterCard': return [const Color(0xFF8B0000), const Color(0xFFEB001B)];
      case 'AmericanExpress': return [const Color(0xFF007BC1), const Color(0xFF00BFFF)];
      default: return [const Color(0xFF1a1a2e), const Color(0xFF16213e)];
    }
  }

  Future<void> _save() async {
    final holder = _holderController.text.trim();

    if (holder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please enter the card holder name.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    if (_cardDetails == null || !_cardDetails!.complete) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please enter complete card details.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(name: holder),
          ),
        ),
      );

      await SupabaseService.attachPaymentMethod(paymentMethod.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Card added successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('\x1B[31m[STRIPE] ERROR | AddCardPage._save | $e\x1B[0m');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to save card.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _cardGradient(_cardDetails?.brand);
    final displayHolder = _holderController.text.isEmpty
        ? 'CARD HOLDER' : _holderController.text.toUpperCase();
    final last4 = _cardDetails?.last4 ?? '';

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(10),
                      backgroundColor: Colors.black54,
                      elevation: 0,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text('Add Card',
                      style: TextStyle(color: _accent(context), fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live card preview
                    Container(
                      width: double.infinity,
                      height: 190,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.sim_card, color: Colors.amber, size: 28),
                              Text(_cardDetails?.brand ?? '',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text(
                            last4.isEmpty ? '•••• •••• •••• ••••' : '•••• •••• •••• $last4',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18, letterSpacing: 3, fontWeight: FontWeight.w600),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Name', style: TextStyle(color: Colors.white54, fontSize: 10)),
                              Text(displayHolder,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    _buildLabel('Card Holder Name'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: context.cardBgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _holderController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: context.textColor, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'John Doe',
                          hintStyle: TextStyle(color: context.subtextColor),
                          prefixIcon: Icon(Icons.person_outline, color: context.subtextColor, size: 20),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Card Details'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: context.cardBgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: CardField(
                        onCardChanged: (details) => setState(() => _cardDetails = details),
                        style: TextStyle(color: context.textColor, fontSize: 15),
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          disabledBackgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                            : const Text('Add Card',
                                style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: TextStyle(color: context.subtextColor, fontSize: 13, fontWeight: FontWeight.w600));
}