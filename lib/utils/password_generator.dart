import 'dart:math';

class PasswordGenerator {
  static String generatePassword({
    int length = 12,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
  }) {
    const String uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const String numbers = '0123456789';
    const String symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (includeUppercase) chars += uppercase;
    if (includeLowercase) chars += lowercase;
    if (includeNumbers) chars += numbers;
    if (includeSymbols) chars += symbols;

    if (chars.isEmpty) {
      chars = lowercase + numbers;
    }

    final random = Random.secure();
    String password = '';

    // Assurer qu'on a au moins un caractère de chaque type demandé
    if (includeUppercase)
      password += uppercase[random.nextInt(uppercase.length)];
    if (includeLowercase)
      password += lowercase[random.nextInt(lowercase.length)];
    if (includeNumbers) password += numbers[random.nextInt(numbers.length)];
    if (includeSymbols) password += symbols[random.nextInt(symbols.length)];

    // Remplir le reste avec des caractères aléatoires
    for (int i = password.length; i < length; i++) {
      password += chars[random.nextInt(chars.length)];
    }

    // Mélanger le mot de passe
    List<String> passwordList = password.split('');
    passwordList.shuffle(random);
    return passwordList.join();
  }

  static String generateSimplePassword({int length = 8}) {
    return generatePassword(
      length: length,
      includeUppercase: true,
      includeLowercase: true,
      includeNumbers: true,
      includeSymbols: false,
    );
  }
}
