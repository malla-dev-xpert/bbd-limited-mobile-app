import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/rounded_button.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

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
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Fond image en opacité sur toute la page
        Positioned.fill(
          child: Opacity(
            opacity: 0.15,
            child: Image.asset(
              'assets/images/bg.jpeg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent, // AppBar transparente
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header centré
                SizedBox(
                  height: size.height * 0.45,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/password.svg',
                          width: 160,
                          height: 160,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Mot de passe oublié",
                          style: TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Entrez votre email pour réinitialiser votre mot de passe.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                // Card blanche
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        height: size.height * 0.55 - 150,
                        padding: const EdgeInsets.symmetric(
                            vertical: 32, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Votre email',
                                  prefixIcon: const Icon(Icons.mail_outline,
                                      color: Colors.black),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(32),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 24),
                              RoundedButton(
                                text: "Envoyer",
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    // TODO: Implémenter la logique de réinitialisation de mot de passe
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Vous allez recevoir un email de réinitialisation si l'adresse est valide.",
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
