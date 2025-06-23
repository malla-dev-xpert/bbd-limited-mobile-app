import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_controller.dart';
import '../../widgets/rounded_button.dart';
import '../../widgets/responsive_container.dart';
import '../../components/text_input.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1E49),
      body: Stack(
        children: [
          // Fond
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/bg.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Contenu principal scrollable
          SingleChildScrollView(
            padding: const EdgeInsets.all(0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header text centré
                SizedBox(
                  height: size.height * 0.55,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/hero.svg',
                          width: 200,
                          height: 200,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "BIENVENUE",
                          style: TextStyle(
                            fontFamily: 'Pacifico',
                            fontSize: 38,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
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
                          "Connectez-vous pour gérer vos livraisons",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Card blanche
                ResponsiveContainer(
                  child: Container(
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
                          buildTextField(
                            controller: controller.usernameController,
                            label: "Nom d'utilisateur",
                            icon: Icons.person_outline,
                            validator: (v) => v == null || v.isEmpty
                                ? "Veuillez entrer votre nom d'utilisateur"
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: controller.passwordController,
                            obscureText: _obscurePassword,
                            validator: (v) => v == null || v.isEmpty
                                ? "Veuillez entrer votre mot de passe"
                                : null,
                            decoration: InputDecoration(
                              labelText: "Mot de passe",
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Colors.black),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.black,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pushNamed(
                                  context, '/forgot-password'),
                              child: const Text("Mot de passe oublié ?",
                                  style: TextStyle(color: Color(0xFF7F78AF))),
                            ),
                          ),
                          if (controller.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                controller.errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          const SizedBox(height: 8),
                          RoundedButton(
                            text: "Connexion",
                            loading: controller.isLoading,
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final success = await controller.login();
                                if (success && context.mounted) {
                                  Navigator.pushReplacementNamed(
                                      context, '/welcome');
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text("Vous n'avez pas de compte ?",
                              style: TextStyle(color: Colors.black54)),
                          const SizedBox(height: 8),
                          const Text(
                            textAlign: TextAlign.center,
                            'Veuillez contacter l\'administrateur pour toute assistance.',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
