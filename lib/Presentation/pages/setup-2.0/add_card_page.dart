import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _holderController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  bool _isDefault = false;
  bool _isSaving = false;
  String _detectedNetwork = 'Unknown';

  @override
  void dispose() {
    _holderController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  String _detectNetwork(String number) {
    final clean = number.replaceAll(' ', '');
    if (clean.isEmpty) return 'Unknown';
    if (clean.startsWith('4')) return 'Visa';
    if (RegExp(r'^5[1-5]').hasMatch(clean)) return 'Mastercard';
    if (RegExp(r'^2[2-7]').hasMatch(clean)) return 'Mastercard'; // new Mastercard range
    if (RegExp(r'^3[47]').hasMatch(clean)) return 'Amex';
    if (clean.startsWith('6011') || clean.startsWith('65') || clean.startsWith('64')) return 'Discover';
    if (clean.startsWith('36') || clean.startsWith('38')) return 'Diners';
    if (clean.startsWith('35')) return 'JCB';
    return 'Unknown';
  }

  IconData _networkIcon(String network) {
    switch (network) {
      case 'Visa': return Icons.credit_card;
      case 'Mastercard': return Icons.credit_card;
      case 'Amex': return Icons.credit_card;
      default: return Icons.credit_card;
    }
  }

  Color _networkColor(String network) {
    switch (network) {
      case 'Visa': return const Color(0xFF1A1F71);
      case 'Mastercard': return const Color(0xFFEB001B);
      case 'Amex': return const Color(0xFF007BC1);
      default: return Colors.grey;
    }
  }

  List<Color> _cardGradient(String network) {
    switch (network) {
      case 'Visa': return [const Color(0xFFB8860B), const Color(0xFFDAA520)];
      case 'Mastercard': return [const Color(0xFF8B0000), const Color(0xFFEB001B)];
      case 'Amex': return [const Color(0xFF007BC1), const Color(0xFF00BFFF)];
      default: return [const Color(0xFF1a1a2e), const Color(0xFF16213e)];
    }
  }
  Future<void> _save() async {
    final holder = _holderController.text.trim();
    final number = _numberController.text.replaceAll(' ', '');
    final expiry = _expiryController.text.trim();
    final cvc = _cvcController.text.trim();

    if (holder.isEmpty || number.length < 16 || expiry.length < 5 || cvc.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please fill all fields correctly.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await SupabaseService.addUserCard(
        holderName: holder,
        last4: number.substring(number.length - 4),
        expiry: expiry,
        cardNetwork: _detectedNetwork,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Card added successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.pop(context, true); // return true = reload cards
      }
    } catch (e) {
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
    final gradient = _cardGradient(_detectedNetwork);
    final displayNumber = _numberController.text.isEmpty
        ? '•••• •••• •••• ••••'
        : _numberController.text.padRight(19, '•');
    final displayHolder = _holderController.text.isEmpty
        ? 'CARD HOLDER' : _holderController.text.toUpperCase();
    final displayExpiry = _expiryController.text.isEmpty
        ? 'MM/YY' : _expiryController.text;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
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
                      style: TextStyle(color: themeColor, fontSize: 22, fontWeight: FontWeight.bold)),
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
                              _buildNetworkBadge(_detectedNetwork),
                            ],
                          ),
                          Text(
                            displayNumber,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w600),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Name', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                  Text(displayHolder,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Expired Date', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                  Text(displayExpiry,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Holder name
                    _buildLabel('Card Holder Name'),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _holderController,
                      hint: 'John Doe',
                      icon: Icons.person_outline,
                      onChanged: (_) => setState(() {}),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card number
                    _buildLabel('Card Number'),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _numberController,
                      hint: '1234 5678 9012 3456',
                      icon: Icons.credit_card,
                      keyboardType: TextInputType.number,
                      maxLength: 19,
                      onChanged: (val) {
                        setState(() {
                          _detectedNetwork = _detectNetwork(val);
                        });
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _CardNumberFormatter(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Expiry + CVC
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Expiry'),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: _expiryController,
                                hint: 'MM/YY',
                                icon: Icons.calendar_today,
                                keyboardType: TextInputType.number,
                                maxLength: 5,
                                onChanged: (_) => setState(() {}),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  _ExpiryFormatter(),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('CVC'),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: _cvcController,
                                hint: '•••',
                                icon: Icons.lock_outline,
                                keyboardType: TextInputType.number,
                                maxLength: 3,
                                obscure: true,
                                onChanged: (_) {},
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Default toggle
                    Row(
                      children: [
                        Checkbox(
                          value: _isDefault,
                          onChanged: (v) => setState(() => _isDefault = v ?? false),
                          fillColor: MaterialStateProperty.all(themeColor),
                          checkColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        Text('Set as default payment method',
                            style: TextStyle(color: context.textColor, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Save button
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    required List<TextInputFormatter> inputFormatters,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: TextStyle(color: context.textColor, fontSize: 15),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: TextStyle(color: context.subtextColor),
          prefixIcon: Icon(icon, color: context.subtextColor, size: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// Auto-formats card number: 1234 5678 9012 3456
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final result = buffer.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

Widget _buildNetworkBadge(String network) {
    switch (network) {
      case 'Visa':
        return const Text('VISA',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 2));
      case 'Mastercard':
        return Row(
          children: [
            Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFEB001B),
                shape: BoxShape.circle,
              ),
            ),
            Transform.translate(
              offset: const Offset(-8, 0),
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFF79E1B).withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      case 'Amex':
        return const Text('AMEX',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2));
      case 'Discover':
        return const Text('DISCOVER',
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1));
      default:
        return const Icon(Icons.credit_card, color: Colors.white54, size: 22);
    }
  }
// Auto-formats expiry: MM/YY
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length > 4) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final result = buffer.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}