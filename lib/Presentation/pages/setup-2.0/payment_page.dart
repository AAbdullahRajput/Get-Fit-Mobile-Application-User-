import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/add_card_page.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/edit_card_page.dart';
import 'package:get_fit/Presentation/widgets/reuseable_button.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:payment_card/payment_card.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Payment Method',
                    style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      buildAddPaymentCard(context),
                      const SizedBox(width: 16),
                      buildPaymentCardExample2(context),
                      const SizedBox(width: 16),
                      buildPaymentCardExample1(),
                      const SizedBox(width: 16),
                      buildPaymentCardExample3(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Details',
                        style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Divider(
                          color: context.isDark
                              ? Colors.grey
                              : Colors.grey.shade300,
                          thickness: 1),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: themeColor,
                          child: const Icon(Icons.person, color: Colors.black),
                        ),
                        title: Text(
                          "Trainer Name",
                          style: TextStyle(color: context.textColor),
                        ),
                        subtitle: Text(
                          "High intensity training",
                          style: TextStyle(color: context.subtextColor),
                        ),
                      ),
                      Divider(
                          color: context.isDark
                              ? Colors.grey
                              : Colors.grey.shade300,
                          thickness: 1),
                      Text("Date",
                          style: TextStyle(color: context.textColor)),
                      const SizedBox(height: 8),
                      Text("Time",
                          style: TextStyle(color: context.textColor)),
                      Divider(
                          color: context.isDark
                              ? Colors.grey
                              : Colors.grey.shade300,
                          thickness: 1),
                      ListTile(
                        title: Text(
                          "Estimated Cost",
                          style: TextStyle(color: context.subtextColor),
                        ),
                        trailing: Text(
                          "\$50.00",
                          style: TextStyle(
                              color: context.textColor, fontSize: 18),
                        ),
                      ),
                      Divider(
                          color: context.isDark
                              ? Colors.grey
                              : Colors.grey.shade300,
                          thickness: 1),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ReuseableButton(
                    title: "Confirm",
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment Confirmed')),
                      );
                    },
                  ),
                ),
              ],
            ),
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

  Widget buildAddPaymentCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddCardPage()));
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xffD9D9D9),
          borderRadius: BorderRadius.circular(10),
        ),
        width: 70,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget buildPaymentCardExample1() {
    return const PaymentCard(
      cardIssuerIcon: CardIcon(icon: Icons.credit_card),
      backgroundColor: Colors.blue,
      backgroundGradient: LinearGradient(
        colors: [Colors.purple, Colors.indigo],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      currency: Text('EUR'),
      cardNumber: '1234567890123456',
      validity: '10/24',
      holder: 'Jane Doe',
      isStrict: false,
      cardNetwork: CardNetwork.visa,
      cardTypeTextStyle:
          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      cardNumberStyles: CardNumberStyles.darkStyle4,
      backgroundImage: null,
    );
  }

  Widget buildPaymentCardExample2(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => EditCardPage(
            card: PaymentCard(
              cardIssuerIcon: const CardIcon(icon: Icons.credit_card),
              currency: const Text('GBP'),
              cardNumber: '1234567890123456',
              isStrict: false,
              validity: '08/23',
              holder: 'John Smith',
              cardNetwork: CardNetwork.mastercard,
              cardTypeTextStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              cardNumberStyles: CardNumberStyles.lightStyle2,
              backgroundImage: null,
              backgroundColor: Colors.grey,
            ),
          ),
        ));
      },
      child: const PaymentCard(
        cardIssuerIcon: CardIcon(icon: Icons.credit_card),
        currency: Text('GBP'),
        cardNumber: '1234567890123456',
        isStrict: false,
        validity: '08/23',
        holder: 'John Smith',
        cardNetwork: CardNetwork.mastercard,
        cardTypeTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white),
        cardNumberStyles: CardNumberStyles.lightStyle2,
        backgroundImage: null,
        backgroundColor: Colors.grey,
      ),
    );
  }

  Widget buildPaymentCardExample3() {
    return const PaymentCard(
      cardIssuerIcon: CardIcon(icon: Icons.credit_card),
      backgroundColor: Colors.green,
      backgroundImage: null,
      currency: Text('USD'),
      cardNumber: '1234567890123456',
      validity: '06/22',
      holder: 'Alice Johnson',
      isStrict: false,
      cardNetwork: CardNetwork.americanExpress,
      cardTypeTextStyle:
          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      cardNumberStyles: CardNumberStyles.lightStyle3,
    );
  }
}