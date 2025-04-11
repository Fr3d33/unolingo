import 'package:flutter/material.dart';

class LanguageFlag extends StatelessWidget {
  final String language;
  
  const LanguageFlag({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: _getFlagForLanguage(language),
      ),
    );
  }

  Widget _getFlagForLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'spanish':
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: Container(color: Colors.red),
              ),
              Expanded(
                flex: 2,
                child: Container(color: Colors.yellow),
              ),
              Expanded(
                flex: 1,
                child: Container(color: Colors.red),
              ),
            ],
          ),
        );
      case 'french':
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(color: Colors.blue),
              ),
              Expanded(
                flex: 1,
                child: Container(color: Colors.white),
              ),
              Expanded(
                flex: 1,
                child: Container(color: Colors.red),
              ),
            ],
          ),
        );
      case 'german':
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: Container(color: Colors.black),
              ),
              Expanded(
                flex: 1,
                child: Container(color: Colors.red),
              ),
              Expanded(
                flex: 1,
                child: Container(color: Colors.yellow),
              ),
            ],
          ),
        );
      case 'italian':
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(color: Colors.green),
              ),
              Expanded(
                flex: 1,
                child: Container(color: Colors.white),
              ),
              Expanded(
                flex: 1,
                child: Container(color: Colors.red),
              ),
            ],
          ),
        );
      case 'japanese':
        return Container(
          color: Colors.white,
          child: Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case 'mandarin':
        return Container(
          color: Colors.red,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.yellow, size: 10),
                Icon(Icons.star, color: Colors.yellow, size: 6),
                Icon(Icons.star, color: Colors.yellow, size: 6),
                Icon(Icons.star, color: Colors.yellow, size: 6),
                Icon(Icons.star, color: Colors.yellow, size: 6),
              ],
            ),
          ),
        );
      default:
        return const Icon(Icons.language, color: Colors.blue);
    }
  }
}
