class FidelLetter {
  final String base;              // Base Fidel (e.g., ሀ)
  final List<FidelForm> forms;    // 7 orders/forms (ha, hu, hi...)

  FidelLetter({
    required this.base,
    required this.forms,
  });
}

class FidelForm {
  final String fidel;             // Actual character (e.g., ሁ)
  final String phonetic;          // Pronunciation in English (e.g., "hu")

  FidelForm({
    required this.fidel,
    required this.phonetic,
  });
}
