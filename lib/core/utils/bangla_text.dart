/// Display helpers for Bangla text.
class BanglaText {
  BanglaText._();

  // A Bangla combining sign (ঁ ং ঃ, nukta, vowel signs, hasanta, au length
  // mark, vocalic signs) with no Bangla letter in front of it — e.g. the "ং, ঃ"
  // in "অভিধানে ং, ঃ, ঁ — …". Text shapers draw these with a dotted circle (◌).
  static final RegExp _standaloneSign = RegExp(
    r'(^|[^ঀ-৿‌‍])'
    r'([ঁ-ঃ়া-ৄেৈো-্ৗৢৣ])',
  );

  /// Gives each standalone sign a no-break space as its base, which the shaper
  /// accepts as a placeholder, so the sign renders on its own without the
  /// dotted circle. The text is otherwise unchanged; use for display only.
  static String forDisplay(String text) {
    return text.replaceAllMapped(_standaloneSign, (m) => '${m[1]} ${m[2]}');
  }
}
