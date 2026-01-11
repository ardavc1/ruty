import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character_model.dart';
import '../services/character_service.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';

class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  CharacterType? selectedCharacter;
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isUpdating = false; // Mevcut karakteri güncelliyor mu?
  CharacterModel? _currentCharacter;

  @override
  void initState() {
    super.initState();
    _loadCurrentCharacter();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentCharacter() async {
    try {
      final character = await CharacterService.getCharacter();
      if (character != null && mounted) {
        setState(() {
          _currentCharacter = character;
          _isUpdating = true;
          selectedCharacter = character.type;
          _nameController.text = character.customName ?? '';
        });
      }
    } catch (e) {
      // Karakter yoksa yeni oluşturma modunda devam et
    }
  }

  void _selectCharacter(CharacterType character) {
    setState(() {
      selectedCharacter = character;
    });
  }

  Future<void> _continueToHome() async {
    if (selectedCharacter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir karakter seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isUpdating && _currentCharacter != null) {
        // Mevcut karakteri güncelle
        await CharacterService.updateCharacter(
          type: selectedCharacter!,
          customName: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
        );
      } else {
        // Yeni karakter oluştur
        await CharacterService.createCharacter(
          type: selectedCharacter!,
          customName: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
        );
      }

      if (!mounted) return;
      
      // Eğer güncelleme modundaysa pop, yoksa home'a git
      if (_isUpdating) {
        Navigator.pop(context, true); // true döndür ki refresh yapılsın
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isUpdating
          ? AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF499BCF)),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: Builder(
        builder: (ctx) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Provider.of<ThemeProvider>(ctx, listen: false).lightColor,
                Provider.of<ThemeProvider>(ctx, listen: false).lightColor.withOpacity(0.8),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Title
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) => Text(
                    _isUpdating ? 'Karakterini Değiştir' : 'Karakterini Seç',
                    style: context.textStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) => Text(
                    _isUpdating
                        ? 'Yeni karakterini seç ve ismini güncelle'
                        : 'Hangi karakter seninle birlikte gelişsin?',
                    style: context.defaultTextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Character Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: CharacterType.values.length,
                  itemBuilder: (context, index) {
                    final character = CharacterType.values[index];
                    final isSelected = selectedCharacter == character;

                    return GestureDetector(
                      onTap: () => _selectCharacter(character),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Provider.of<ThemeProvider>(context, listen: false).primaryColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Provider.of<ThemeProvider>(context, listen: false).primaryColor
                                : Colors.grey[300]!,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? Provider.of<ThemeProvider>(context, listen: false).primaryColor.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.1),
                              blurRadius: isSelected ? 15 : 5,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Character Image
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Consumer<ThemeProvider>(
                                  builder: (context, themeProvider, _) => _getCharacterIcon(context, character, isSelected),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              character.label,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Seçildi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                // Optional Name Input
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Karakterine bir isim ver (Opsiyonel)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Örn: Puffy, Max, Luna...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.edit),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _continueToHome,
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) => Text(
                              _isUpdating ? 'Kaydet' : 'Devam Et',
                              style: context.whiteTextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getCharacterIcon(BuildContext context, CharacterType character, bool isSelected) {
    // Karakter emojileri
    final emojiMap = {
      CharacterType.cat: '🐱',
      CharacterType.dog: '🐶',
      CharacterType.rabbit: '🐰',
      CharacterType.fox: '🦊',
    };

    return Container(
      width: 100,
      height: 100,
      color: Colors.transparent,
      child: Center(
        child: Text(
          emojiMap[character] ?? '🐾',
          style: TextStyle(fontSize: context.scaledFontSize(60)),
        ),
      ),
    );
  }
}

