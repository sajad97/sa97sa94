import 'package:eshop/Provider/CartProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Helper/cart_var.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/PaymentSelectionSection.dart';
import '../ui/widgets/SimBtn.dart';
import '../ui/widgets/SimpleAppBar.dart';
import '../utils/blured_router.dart';

class Payment extends StatefulWidget {
  final Function update;
  final String? msg;

  static route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return Payment(
          arguments?['update'],
          arguments?['msg'],
        );
      },
    );
  }

  const Payment(this.update, this.msg, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StatePayment();
  }
}

class StatePayment extends State<Payment> {
  @override
  void initState() {
    super.initState();
    if (widget.msg != '') {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => setSnackbar(widget.msg!, context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getSimpleAppBar(
          getTranslated(context, 'PAYMENT_METHOD_LBL')!, context),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: PaymentSelectionSection(
                  onChanged: () {
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ),
            SimBtn(
              width: 0.8,
              height: 35,
              title: getTranslated(context, 'DONE'),
              onBtnSelected: () {
                if (paymentMethod == null || paymentMethod!.isEmpty) {
                  setSnackbar(getTranslated(context, 'payWarning')!, context);
                } else if (context
                            .read<CartProvider>()
                            .cartList[0]
                            .productList![0]
                            .productType !=
                        'digital_product' &&
                    isTimeSlot! &&
                    (isLocalDelCharge == null || isLocalDelCharge!) &&
                    int.parse(allowDay!) > 0 &&
                    (selDate == null || selDate!.isEmpty) &&
                    IS_LOCAL_ON != '0') {
                  setSnackbar(getTranslated(context, 'dateWarning')!, context);
                } else if (context
                            .read<CartProvider>()
                            .cartList[0]
                            .productList![0]
                            .productType !=
                        'digital_product' &&
                    isTimeSlot! &&
                    (isLocalDelCharge == null || isLocalDelCharge!) &&
                    timeSlotList.isNotEmpty &&
                    (selTime == null || selTime!.isEmpty) &&
                    IS_LOCAL_ON != '0') {
                  setSnackbar(getTranslated(context, 'timeWarning')!, context);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
