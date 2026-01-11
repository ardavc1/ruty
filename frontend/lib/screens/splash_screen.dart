import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Minimum splash screen süresi
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    // Sadece token kontrolü yap - hızlı ve güvenli
    bool isLoggedIn = false;
    try {
      isLoggedIn = await AuthService.isLoggedIn();
    } catch (e) {
      // Hata olursa giriş yapılmamış say
      isLoggedIn = false;
    }
    
    if (!mounted) return;
    
    // Navigation - basit ve direkt
    final route = isLoggedIn ? '/home' : '/login';
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Provider.of<ThemeProvider>(context, listen: false).lightColor,
                Provider.of<ThemeProvider>(context, listen: false).lightColor.withOpacity(0.8),
                Colors.white,
              ],
            ),
          ),
          child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon - Tilki görseli
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/pets/fox.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Eğer görsel yoksa, tilki emojisi göster
                        return Consumer<ThemeProvider>(
                          builder: (context, themeProvider, _) => Center(
                            child: Text(
                              '🦊',
                              style: TextStyle(
                                fontSize: context.scaledFontSize(70),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // App Name
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) => Text(
                    'Ruty',
                    style: context.textStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Tagline
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) => Text(
                    'Alışkanlıklarını takip et, karakterini geliştir',
                    style: context.defaultTextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 50),
                // Loading Indicator
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) => CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(themeProvider.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

