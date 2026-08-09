import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp_autofill/otp_autofill.dart';

class PinInputBoxes extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;
  final bool obscureText;

  const PinInputBoxes({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.obscureText = false,
  });

  @override
  State<PinInputBoxes> createState() => _PinInputBoxesState();
}

class _PinInputBoxesState extends State<PinInputBoxes> {
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;
  late OTPTextEditController otpController;
  late OTPInteractor otpInteractor;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(widget.length, (_) => TextEditingController());
    focusNodes = List.generate(widget.length, (_) => FocusNode());
    otpInteractor = OTPInteractor();
    otpController =
        OTPTextEditController(
          codeLength: widget.length,
          onCodeReceive: (code) {
            _fillOTP(code);
          },
        )..startListenUserConsent((code) {
          final exp = RegExp(r'(\d{4})');
          return exp.stringMatch(code ?? '') ?? '';
        });
  }

  void _fillOTP(String code) {
    for (int i = 0; i < code.length && i < widget.length; i++) {
      controllers[i].text = code[i];
    }
    setState(() {});
    if (code.length == widget.length) {
      widget.onCompleted(code);
    }
  }

  @override
  void dispose() {
    otpController.stopListen();
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        return Container(
          width: 60,
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: controllers[index].text.isNotEmpty
                  ? const Color(0xff0B3A70)
                  : const Color(0xffD1D5DB),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            obscureText: widget.obscureText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xff0B3A70),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
            ),
            onChanged: (value) {
              setState(() {});
              if (value.isNotEmpty && index < widget.length - 1) {
                focusNodes[index + 1].requestFocus();
              }
              if (value.isEmpty && index > 0) {
                focusNodes[index - 1].requestFocus();
              }

              final pin = controllers.map((c) => c.text).join();
              if (pin.length == widget.length) {
                widget.onCompleted(pin);
              }
            },
          ),
        );
      }),
    );
  }
}
