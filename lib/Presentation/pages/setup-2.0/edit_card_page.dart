import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class EditCardPage extends StatefulWidget {
  final Map<String, dynamic> card;

  const EditCardPage({super.key, required this.card});

  @override
  State<EditCardPage> createState() => _EditCardPageState();
}

class _EditCardPageState extends State<EditCardPage> {
  late TextEditingController _holderController;
  late TextEditingController _expiryController;
  final _cvcController = TextEditingController();
  bool _isSaving = false;
  bool _isDeleting = false;
  late String _detectedNetwork;

  @override
  void initState() {
    super.initState();
    _holderController = TextEditingController(text: widget.card['holder_name'] ?? '');
    _expiryController = TextEditingController(text: widget.card['expiry'] ?? '');
    _detectedNetwork = widget.card['card_network'] ?? 'Unknown';
  }

  @override
  void dispose() {
    _holderController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  List<Color> _cardGradient(String network) {
    switch (network) {
      case 'Visa': return [const Color(0xFF1a6bb5), const Color(0xFF3d8ef0)];
      case 'Mastercard': return [const Color(0xFF8B0000), const Color(0xFFEB001B)];
      case 'Amex': return [const Color(0xFF007BC1), const Color(0xFF00BFFF)];
      case 'Discover': return [const Color(0xFFe65c00), const Color(0xFFf9d423)];
      default: return [const Color(0xFF1a1a2e), const Color(0xFF16213e)];
    }
  }

  Widget _buildNetworkBadge(String network) {
    switch (network) {
      case 'Visa':
        return const Text('VISA',
            style: TextStyle(color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 2));
      case 'Mastercard':
        return Row(children: [
          Container(width: 22, height: 22,
              decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle)),
          Transform.translate(offset: const Offset(-8, 0),
            child: Container(width: 22, height: 22,
                decoration: BoxDecoration(
                    color: const Color(0xFFF79E1B).withOpacity(0.9),
                    shape: BoxShape.circle)),
          ),
        ]);
      case 'Amex':
        return const Text('AMEX',
            style: TextStyle(color: Colors.white, fontSize: 14,
                fontWeight: FontWeight.bold, letterSpacing: 2));
      default:
        return const Icon(Icons.credit_card, color: Colors.white54, size: 22);
    }
  }

  Future<void> _save() async {
    final holder = _holderController.text.trim();
    final expiry = _expiryController.text.trim();
    final cvc = _cvcController.text.trim();

    if (holder.isEmpty || expiry.length < 5 || cvc.length < 3) {
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
      await SupabaseService.updateUserCard(
        cardId: widget.card['id'],
        holderName: holder,
        expiry: expiry,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Card updated!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to update card.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Card?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Remove •••• •••• •••• ${widget.card['last4']} from your account?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isDeleting = true);
    try {
      await SupabaseService.deleteUserCard(widget.card['id']);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to delete card.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Widget _buildUnderlineField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter> inputFormatters = const [],
    int? maxLength,
    bool obscure = false,
    Function(String)? onChanged,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: context.textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          obscureText: obscure,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: TextStyle(color: context.subtextColor, fontSize: 15),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: TextStyle(color: context.subtextColor.withOpacity(0.4)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.isDark ? Colors.white24 : Colors.grey.shade300),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: themeColor),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _cardGradient(_detectedNetwork);
    final displayHolder = _holderController.text.isEmpty
        ? 'CARD HOLDER' : _holderController.text.toUpperCase();
    final displayExpiry = _expiryController.text.isEmpty
        ? 'MM/YY' : _expiryController.text;
    final last4 = widget.card['last4'] ?? '••••';

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
                  Text('Edit Card',
                      style: TextStyle(color: themeColor, fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section label
                    Text('Payment Method',
                        style: TextStyle(color: context.textColor,
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),

                    // Card preview
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
                          Text('•••• •••• •••• $last4',
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 18, letterSpacing: 3, fontWeight: FontWeight.w600)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('Name', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                Text(displayHolder,
                                    style: const TextStyle(color: Colors.white,
                                        fontSize: 13, fontWeight: FontWeight.w600)),
                              ]),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                const Text('Expired Date',
                                    style: TextStyle(color: Colors.white54, fontSize: 10)),
                                Text(displayExpiry,
                                    style: const TextStyle(color: Colors.white,
                                        fontSize: 13, fontWeight: FontWeight.w600)),
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Card Holder Name
                    _buildUnderlineField(
                      label: 'Card Holder Name',
                      controller: _holderController,
                      hint: 'Julietta Moonwalk',
                      onChanged: (_) => setState(() {}),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Card Number (read-only)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Card Number',
                            style: TextStyle(color: context.textColor,
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('•••• •••• •••• $last4',
                            style: TextStyle(color: context.subtextColor, fontSize: 15, letterSpacing: 2)),
                        Divider(color: context.isDark ? Colors.white24 : Colors.grey.shade300),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Expiry + CVC side by side
                    Row(
                      children: [
                        Expanded(
                          child: _buildUnderlineField(
                            label: 'Expiry(MM/YY)',
                            controller: _expiryController,
                            hint: '01-23',
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                            onChanged: (_) => setState(() {}),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _ExpiryFormatter(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: _buildUnderlineField(
                            label: 'CVC',
                            controller: _cvcController,
                            hint: '•••',
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                            obscure: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Delete Card — plain text like Figma
                    GestureDetector(
                      onTap: _isDeleting ? null : _delete,
                      child: _isDeleting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.redAccent))
                          : const Text('Delete Card',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500)),
                    ),
                    Divider(
                        color: context.isDark ? Colors.white12 : Colors.grey.shade300,
                        height: 32),

                    const SizedBox(height: 16),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          disabledBackgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.black))
                            : const Text('Save',
                                style: TextStyle(color: Colors.black,
                                    fontSize: 16, fontWeight: FontWeight.bold)),
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
}

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