// ignore_for_file: must_be_immutable

import 'package:eschool/data/models/paymentOptions.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/uiUtils.dart';
import 'package:flutter/material.dart';

class PaymentSelectionBottomSheet extends StatefulWidget {
  PaymentOptions enabledPayments;

  PaymentSelectionBottomSheet({super.key, required this.enabledPayments});

  @override
  PaymentSelectionBottomSheetStateState createState() =>
      PaymentSelectionBottomSheetStateState();
}

class PaymentSelectionBottomSheetStateState
    extends State<PaymentSelectionBottomSheet> {
  // List of items
  List<String> options = [];
  //'razorpay', 'stripe', 'paystack', 'flutterwave'

  String? selectedPaymentOption;

  @override
  void initState() {
    if (widget.enabledPayments.razorpay != null) options.add('razorpay');
    if (widget.enabledPayments.stripe != null) options.add('stripe');
    if (widget.enabledPayments.paystack != null) options.add('paystack');
    if (widget.enabledPayments.flutterwave != null) options.add('flutterwave');

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(UiUtils.getTranslatedLabel(context, paymentOptionsKey),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          ListView.builder(
            shrinkWrap:
                true, // Important to allow the list to fit in the BottomSheet
            itemCount: options.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(options[index].toCapitalized()),
                selected: selectedPaymentOption == options[index],
                onTap: () {
                  setState(() => selectedPaymentOption = options[index]);
                  // Close BottomSheet after selection
                  Navigator.pop(context, selectedPaymentOption);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
