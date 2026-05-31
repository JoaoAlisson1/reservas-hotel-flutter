import 'package:flutter/material.dart';
import '../core/authentication/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Dormez Hotel - Login"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 60.0, bottom: 10.0),
                child: Center(
                  child: Icon(Icons.hotel, size: 100, color: Colors.blueGrey),
                ),
              ),
              const Text(
                "Bem-vindo de volta!",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey
                ),
              ),
              const SizedBox(height: 20),

              // Campo de E-mail
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                child: TextFormField(
                  controller: loginController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu e-mail';
                    }
                    final bool emailValido = RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+"
                    ).hasMatch(value);

                    if (!emailValido) {
                      return 'Insira um e-mail válido';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    label: const Text('E-mail'),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                child: TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  validator: (value) => (value == null || value.isEmpty) ? '* Obrigatório' : null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    label: const Text('Senha'),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                width: 250,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final bool success = await AuthService().login(
                        loginController.text,
                        passwordController.text,
                      );

                      if (success) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('E-mail ou senha incorretos!'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white, fontSize: 20)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}