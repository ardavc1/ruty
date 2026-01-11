import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Ayarlar',
          style: TextStyle(
            color: themeProvider.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: themeProvider.primaryColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Görünüm Bölümü
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Görünüm',
                    style: context.textStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tema Rengi',
                        style: context.defaultTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: ThemeProvider.availableColors.asMap().entries.map((entry) {
                          final index = entry.key;
                          final themeColor = entry.value;
                          final isSelected = themeProvider.selectedColorIndex == index;

                          return GestureDetector(
                            onTap: () {
                              themeProvider.setPrimaryColorIndex(index);
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: themeColor.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.grey[300]!,
                                  width: isSelected ? 3 : 2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: themeColor.color.withOpacity(0.4),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 30,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yazı Boyutu',
                        style: context.defaultTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ThemeProvider.availableFontSizes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final fontSizeLabel = entry.value;
                          final isSelected = themeProvider.selectedFontSizeIndex == index;

                          return GestureDetector(
                            onTap: () {
                              themeProvider.setFontSizeIndex(index);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? themeProvider.primaryColor
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? themeProvider.primaryColor
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                fontSizeLabel,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Bildirimler Bölümü
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Bildirimler',
                    style: context.textStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.notifications,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  title: const Text('Bildirimleri Aç'),
                  subtitle: const Text('Alışkanlık hatırlatmalarını al'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    // TODO: Bildirim ayarlarını kaydet
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.vibration,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  title: const Text('Titreşim'),
                  subtitle: const Text('Bildirimlerde titreşim kullan'),
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _vibrationEnabled = value;
                    });
                    // TODO: Titreşim ayarlarını kaydet
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Genel Bölüm
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Genel',
                    style: context.textStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  title: const Text('Hakkında'),
                  subtitle: const Text('Uygulama bilgileri'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Ruty',
                      applicationVersion: '1.0.0',
                      applicationIcon: Icon(
                        Icons.pets,
                        size: 48,
                        color: themeProvider.primaryColor,
                      ),
                      children: [
                        const Text('Alışkanlıklarını takip et, karakterini geliştir!'),
                      ],
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.privacy_tip,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  title: const Text('Gizlilik Politikası'),
                  subtitle: const Text('Gizlilik politikası ve şartlar'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Gizlilik politikası ekranı
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Yakında eklenecek')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

