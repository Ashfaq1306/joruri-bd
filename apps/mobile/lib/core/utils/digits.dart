/// Shows numbers with Bangla digits when the app is in Bangla.
/// Only for display: numbers that are dialled or sent stay ASCII.
String localizedDigits(String input, String languageCode) {
  if (languageCode != 'bn') return input;
  const bangla = '০১২৩৪৫৬৭৮৯';
  return input.replaceAllMapped(RegExp(r'\d'), (m) => bangla[int.parse(m[0]!)]);
}
