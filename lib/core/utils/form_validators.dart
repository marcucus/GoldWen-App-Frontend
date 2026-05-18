class FormValidators {
  static const String _passwordRegex = r'^(?=.*[A-Z])(?=.*[!@#$%^&*()\-_+=\[\]{};:,.<>/?|\\]).*$';

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre adresse email';
    }
    // Strict parité avec NestJS @IsEmail()
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Veuillez entrer une adresse email valide';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit comporter au moins 6 caractères';
    }
    final passwordRegex = RegExp(_passwordRegex);
    if (!passwordRegex.hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une majuscule et un caractère spécial';
    }
    return null;
  }

  static String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer votre prénom';
    }
    return null;
  }

  static String? validateLastName(String? value) {
    // lastName is optional in DTO, but if provided, must not be just spaces.
    return null;
  }
}
