import 'package:flutter/material.dart';

class FilterTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const FilterTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xff11416B),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xffE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xffADAEBC),
              ),
              prefixIcon: Icon(icon, size: 20, color: Color(0xffADAEBC)),
              border: InputBorder.none,
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
