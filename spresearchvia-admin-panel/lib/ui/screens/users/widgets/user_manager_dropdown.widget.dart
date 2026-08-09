import 'package:flutter/material.dart';

class UserManagerDropdown extends StatelessWidget {
  final String manager;
  final int flex;

  const UserManagerDropdown(this.manager, {super.key, required this.flex});

  @override
  Widget build(BuildContext context) {
    final managers = [
      'Rohit Sharma',
      'Kavya Singh',
      'Aman Verma',
      'Rohit Shar',
      'Priya Mehta',
    ];
    final validManager = managers.contains(manager) ? manager : managers.first;

    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: validManager,
            isExpanded: true,
            items: managers
                .map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(m, style: TextStyle(fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: (value) {},
          ),
        ),
      ),
    );
  }
}
