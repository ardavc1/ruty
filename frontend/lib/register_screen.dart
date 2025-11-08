import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordAgainController =
      TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordAgainController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ANDROID emülatörde backend için:
      // 10.0.2.2:8080 = bilgisayarındaki localhost:8080
      final url = Uri.parse('http://10.0.2.2:8080/auth/register');
      // Eğer web/desktop’ta çalıştıracaksan:
      // final url = Uri.parse('http://localhost:8080/auth/register');

      final body = {
        "display_name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kayıt başarılı, giriş yapabilirsiniz.")),
        );

        // İleride Login ekranı eklediğinde buradan oraya yönlendireceğiz
        // Şimdilik sadece Snackbar yeterli olabilir.
      } else {
        String message = "Kayıt başarısız. Lütfen bilgilerinizi kontrol edin.";

        try {
          final data = jsonDecode(response.body);
          if (data is Map && data["message"] is String) {
            message = data["message"];
          }
        } catch (_) {}

        setState(() {
          _errorMessage = message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            "Bir hata oluştu. İnternet/bağlantı ve backend sunucusunu kontrol edin.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "E-posta zorunludur.";
    }
    if (!RegExp(r"^[^@]+@[^@]+\.[^@]+").hasMatch(value.trim())) {
      return "Geçerli bir e-posta girin.";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Şifre zorunludur.";
    }
    if (value.trim().length < 6) {
      return "Şifre en az 6 karakter olmalıdır.";
    }
    return null;
  }

  String? _validatePasswordAgain(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Şifre tekrar zorunludur.";
    }
    if (value.trim() != _passwordController.text.trim()) {
      return "Şifreler eşleşmiyor.";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pets, size: 64),
                const SizedBox(height: 8),
                Text(
                  "Ruty’ye Katıl",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Alışkanlık yolculuğuna hemen başla",
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: "İsim / Görünen ad",
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: "E-posta",
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Şifre",
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordAgainController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Şifre (tekrar)",
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: _validatePasswordAgain,
                          ),
                          const SizedBox(height: 16),
                          if (_errorMessage != null) ...[
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Kayıt Ol",
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Zaten hesabın var mı? "),
                    Text(
                      "Giriş yap", // Şimdilik sadece text, sonra tıklanabilir yaparız
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
