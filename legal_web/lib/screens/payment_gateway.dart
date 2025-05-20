import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class PaymentGatewayScreen extends StatefulWidget {
  final Map<String, dynamic> bookingDetails;

  const PaymentGatewayScreen({Key? key, required this.bookingDetails}) : super(key: key);

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  bool _isProcessing = false;
  bool _showCardForm = true;
  CardType _cardType = CardType.other;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.bookingDetails['amount']?.toStringAsFixed(2) ?? '0.00';
    
    return Scaffold(
      backgroundColor: const Color(0xFF353E55),
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF353E55),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD0A554)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Summary
            Card(
              color: const Color(0xFF3D4559),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Summary',
                      style: TextStyle(
                        color: Color(0xFFD0A554),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildDetailRow(Icons.person, 'Lawyer:', widget.bookingDetails['lawyer'] ?? 'N/A'),
                    _buildDetailRow(Icons.calendar_today, 'Date:', widget.bookingDetails['date'] ?? 'N/A'),
                    _buildDetailRow(Icons.access_time, 'Time:', widget.bookingDetails['time'] ?? 'N/A'),
                    _buildDetailRow(Icons.phone, 'Type:', widget.bookingDetails['type'] ?? 'N/A'),
                    const SizedBox(height: 10),
                    const Divider(color: Color(0xFFD0A554)),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.money, 'Amount:', 'LKR $amount'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Card Payment Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Card Details',
                    style: TextStyle(
                      color: Color(0xFFD0A554),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  _buildCardInput(
                    controller: _cardNumberController,
                    label: 'Card Number',
                    hint: '4242 4242 4242 4242',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter card number';
                      }
                      final cleaned = value.replaceAll(RegExp(r'\s+\b|\b\s'), '');
                      if (!RegExp(r'^[0-9]{13,19}$').hasMatch(cleaned)) {
                        return 'Enter valid card number';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(19),
                      CardNumberFormatter(),
                    ],
                    prefixIcon: _buildCardTypeIcon(),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: _buildCardInput(
                          controller: _expiryController,
                          label: 'Expiry Date',
                          hint: 'MM/YY',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter expiry date';
                            }
                            if (!RegExp(r'^(0[1-9]|1[0-2])\/?([0-9]{2})$').hasMatch(value)) {
                              return 'MM/YY format';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            CardExpiryFormatter(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      
                      Expanded(
                        child: _buildCardInput(
                          controller: _cvvController,
                          label: 'CVV',
                          hint: _cardType == CardType.amex ? '4 digits' : '3 digits',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter CVV';
                            }
                            if (_cardType == CardType.amex && value.length != 4) {
                              return '4 digit code';
                            }
                            if (_cardType != CardType.amex && value.length != 3) {
                              return '3 digit code';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(
                              _cardType == CardType.amex ? 4 : 3),
                          ],
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  _buildCardInput(
                    controller: _cardHolderController,
                    label: 'Card Holder Name',
                    hint: 'John Doe',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter card holder name';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD0A554),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isProcessing ? null : _processPayment,
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Color(0xFF353E55))
                    : const Text(
                        'PAY NOW',
                        style: TextStyle(
                          color: Color(0xFF353E55),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD0A554), size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD0A554),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? prefixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFD0A554),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFF3D4559),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: prefixIcon,
          ),
          style: const TextStyle(color: Colors.white),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          validator: validator,
          onChanged: (value) {
            if (controller == _cardNumberController) {
              _detectCardType(value.replaceAll(' ', ''));
            }
          },
          textCapitalization: textCapitalization,
        ),
      ],
    );
  }

  Widget _buildCardTypeIcon() {
    // For actual implementation, you would use actual card icons
    // This is a simplified version using Icons
    switch (_cardType) {
      case CardType.visa:
        return const Icon(Icons.credit_card, color: Colors.blue);
      case CardType.mastercard:
        return const Icon(Icons.credit_card, color: Colors.red);
      case CardType.amex:
        return const Icon(Icons.credit_card, color: Colors.green);
      case CardType.discover:
        return const Icon(Icons.credit_card, color: Colors.orange);
      default:
        return const Icon(Icons.credit_card, color: Color(0xFFD0A554));
    }
  }

  void _detectCardType(String cardNumber) {
    if (cardNumber.isEmpty) {
      setState(() => _cardType = CardType.other);
      return;
    }

    if (cardNumber.startsWith('4')) {
      setState(() => _cardType = CardType.visa);
    } else if (cardNumber.startsWith(RegExp(r'5[1-5]'))) {
      setState(() => _cardType = CardType.mastercard);
    } else if (cardNumber.startsWith(RegExp(r'3[47]'))) {
      setState(() => _cardType = CardType.amex);
    } else if (cardNumber.startsWith('6')) {
      setState(() => _cardType = CardType.discover);
    } else {
      setState(() => _cardType = CardType.other);
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isProcessing = false);

    final amount = widget.bookingDetails['amount']?.toStringAsFixed(2) ?? '0.00';
    
    // Show success dialog
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3D4559),
        title: const Text(
          'Payment Successful',
          style: TextStyle(color: Color(0xFFD0A554)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            Text(
              'Your payment of LKR $amount was successful!',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Transaction ID: ${_generateTransactionId()}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/user-home');
            },
            child: const Text(
              'BACK TO HOME',
              style: TextStyle(color: Color(0xFFD0A554)),
            ),
          ),
        ],
      ),
    );
  }

  String _generateTransactionId() {
    return 'TXN${DateTime.now().millisecondsSinceEpoch}'.substring(0, 12);
  }
}

enum CardType {
  visa,
  mastercard,
  amex,
  discover,
  other,
}

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(' ', '');
    
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write(' ');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll('/', '');

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && i != text.length - 1) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}