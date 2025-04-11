import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  final String currentLanguage;
  final Function(String) onLanguageChanged;
  
  const LanguageSelector({
    Key? key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: currentLanguage,
              isExpanded: true,
              dropdownColor: Colors.black87,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              underline: Container(
                height: 1,
                color: Colors.white24,
              ),
              icon: const Icon(Icons.language, color: Colors.white54),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onLanguageChanged(newValue);
                }
              },
              items: <String>[
                'Spanish',
                'French',
                'German',
                'Italian',
                'Japanese',
                'Mandarin',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
