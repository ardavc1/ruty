import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';

class EmojiPickerWidget extends StatefulWidget {
  final String? initialEmoji;
  final Function(String) onEmojiSelected;

  const EmojiPickerWidget({
    super.key,
    this.initialEmoji,
    required this.onEmojiSelected,
  });

  @override
  State<EmojiPickerWidget> createState() => _EmojiPickerWidgetState();
}

class _EmojiPickerWidgetState extends State<EmojiPickerWidget> {
  String? _selectedEmoji;

  // Jenerik emoji kategorileri
  static const List<Map<String, dynamic>> emojiCategories = [
    {
      'title': 'Aktiviteler',
      'emojis': ['🏃', '🚴', '💪', '🧘', '🏋️', '⚽', '🏀', '🎾', '🏊', '🚶'],
    },
    {
      'title': 'Sağlık',
      'emojis': ['💊', '🥗', '🥛', '🍎', '🧘', '💤', '🦷', '🧴', '🌿', '💚'],
    },
    {
      'title': 'Eğitim',
      'emojis': ['📚', '✏️', '📝', '📖', '🎓', '💡', '📊', '🔬', '📐', '🎯'],
    },
    {
      'title': 'Günlük Rutinler',
      'emojis': ['☕', '🧹', '🛏️', '🚿', '🍳', '🧺', '📱', '💼', '🛒', '🏠'],
    },
    {
      'title': 'Eğlence',
      'emojis': ['🎮', '🎬', '🎵', '🎨', '📸', '🎪', '🎭', '🎤', '🎸', '🎹'],
    },
    {
      'title': 'Sosyal',
      'emojis': ['👥', '💬', '📞', '📧', '🎉', '🎁', '🤝', '❤️', '💕', '🌟'],
    },
    {
      'title': 'Doğa',
      'emojis': ['🌱', '🌳', '🌿', '🌸', '🌺', '🦋', '🐦', '🌞', '🌙', '⭐'],
    },
    {
      'title': 'Yemek',
      'emojis': ['🍎', '🥗', '🥑', '🥝', '🍓', '🥕', '🥦', '🍌', '🍇', '🥥'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.initialEmoji;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeProvider.lightColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Emoji Seç',
                    style: context.textStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: themeProvider.primaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Selected Emoji Preview
            if (_selectedEmoji != null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: themeProvider.lightColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _selectedEmoji!,
                        style: TextStyle(fontSize: context.scaledFontSize(50)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Seçili Emoji',
                      style: context.defaultTextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            // Emoji Categories
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                shrinkWrap: true,
                itemCount: emojiCategories.length,
                itemBuilder: (context, categoryIndex) {
                  final category = emojiCategories[categoryIndex];
                  final title = category['title'] as String;
                  final emojis = category['emojis'] as List<String>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          title,
                          style: context.textStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: emojis.map((emoji) {
                          final isSelected = _selectedEmoji == emoji;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedEmoji = emoji;
                              });
                              // Emoji seçildiğinde otomatik olarak callback'i çağır ve dialog'u kapat
                              widget.onEmojiSelected(emoji);
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? themeProvider.primaryColor
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? themeProvider.primaryColor
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: TextStyle(
                                    fontSize: context.scaledFontSize(24),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 15),
                    ],
                  );
                },
              ),
            ),
            // Confirm Button
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedEmoji != null
                      ? () {
                          if (_selectedEmoji != null) {
                            widget.onEmojiSelected(_selectedEmoji!);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.primaryColor,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Seç',
                    style: context.whiteTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

