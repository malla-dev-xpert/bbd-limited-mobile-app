import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre email';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenHeight < 600 || screenWidth < 350;
    final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;

    final pageContent = GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/password.svg',
                      width: isSmallScreen ? 100 : 200,
                      height: isSmallScreen ? 100 : 200,
                    ),
                  ),
                  Center(
                    child: Text(
                      'Mot de passe oublié !',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 18 : 24,
                                color: Colors.black87,
                              ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Entrez votre email pour réinitialiser votre mot de passe.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                            fontSize: isSmallScreen ? 12 : 16,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // Formulaire
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 24,
                vertical: isSmallScreen ? 16 : 32,
              ),
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: screenHeight * 0.8,
                maxHeight: screenHeight * 0.8,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1E49),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(34),
                  topRight: Radius.circular(34),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Champ Email
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Votre email',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: const Icon(
                          Icons.mail_outline,
                          color: Colors.black,
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                      validator: _validateEmail,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 40),

                    // Bouton d'envoi
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // TODO: Implémenter la logique de réinitialisation de mot de passe
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7F78AF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Envoyer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isKeyboardVisible
          ? SingleChildScrollView(
              padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
              child: pageContent,
            )
          : pageContent,
    );
  }
}
