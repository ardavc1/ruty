import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class HabitNewAddPage extends StatefulWidget { 
  const HabitNewAddPage({super.key});

  @override
  State<HabitNewAddPage> createState() => _HabitNewAddPageState();
}

class _HabitNewAddPageState extends State<HabitNewAddPage> {
  String selectedEmoji = "☕";
  Color selectedColor = const Color(0xFF499BCF);
  bool reminder = false;
  TimeOfDay? selectedTime;

  // Kullanıcının yazdığı alışkanlık tanımı
  String habitTitle = "";

  String? selectedCategory;
  String? selectedPeriod;
  String? selectedGoal;

  final List<String> categories = ["Sağlık", "Verimlilik", "Kişisel Gelişim", "Spor", "Diğer"];
  final List<String> periods = ["Günlük", "Haftalık", "Aylık"];
  final List<String> goals = ["1 kez", "2 kez", "3 kez", "5 kez", "10 kez"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 🌈 Arka plan geçişli
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFAECEE6), // üst açık mavi
              Color(0xFFFFFFFF), // alt beyaz
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Üst başlık
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "KENDİ ALIŞKANLIĞINI OLUŞTUR",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 🔹 Emoji ve Tanım
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showEmojiPicker(context),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: selectedColor.withValues(alpha: 0.2),
                          child: Text(selectedEmoji, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => habitTitle = val),
                          decoration: const InputDecoration(
                            hintText: "Alışkanlık tanımı",
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 🔹 Renk
                _buildCard(
                  title: "Renk",
                  trailing: GestureDetector(
                    onTap: () => _showColorPicker(context),
                    child: CircleAvatar(backgroundColor: selectedColor, radius: 14),
                  ),
                ),

                // 🔹 Kategori
                _buildCard(
                  title: "Kategori (opsiyonel)",
                  trailing: Text(selectedCategory ?? "Seç", style: const TextStyle(color: Colors.grey)),
                  onTap: () => _showSelectionDialog(
                    title: "Kategori Seç",
                    options: categories,
                    onSelected: (v) => setState(() => selectedCategory = v),
                  ),
                ),

                // 🔹 Periyot
                _buildCard(
                  title: "Periyot (günlük, haftalık)",
                  trailing: Text(selectedPeriod ?? "Seç", style: const TextStyle(color: Colors.grey)),
                  onTap: () => _showSelectionDialog(
                    title: "Periyot Seç",
                    options: periods,
                    onSelected: (v) => setState(() => selectedPeriod = v),
                  ),
                ),

                // 🔹 Hedef
                _buildCard(
                  title: "Hedef",
                  trailing: Text(selectedGoal ?? "Seç", style: const TextStyle(color: Colors.grey)),
                  onTap: () => _showSelectionDialog(
                    title: "Hedef Seç",
                    options: goals,
                    onSelected: (v) => setState(() => selectedGoal = v),
                  ),
                ),

                // 🔹 Hatırlatma
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Hatırlatma", style: TextStyle(fontSize: 16)),
                          Switch(
                            value: reminder,
                            onChanged: (val) => setState(() => reminder = val),
                            activeTrackColor: const Color(0xFF499BCF),
                            activeThumbColor: Colors.white,
                          ),
                        ],
                      ),
                      if (reminder)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedTime == null
                                  ? "Saat seçilmedi"
                                  : "Saat: ${selectedTime!.format(context)}",
                              style: const TextStyle(color: Colors.black54),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Color(0xFF499BCF)),
                              onPressed: _pickTime,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 🔹 Kaydet butonu
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (habitTitle.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Lütfen alışkanlık tanımını girin")),
                        );
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Kaydedildi: $habitTitle | ${selectedCategory ?? '-'} | ${selectedPeriod ?? '-'} | ${selectedGoal ?? '-'}",
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF499BCF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                    ),
                    child: const Text(
                      "Kaydet",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 📦 Ortak kart stili
  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      );

  Widget _buildCard({required String title, Widget? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: _cardDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ✅ Custom Emoji Picker (paketsiz)
  void _showEmojiPicker(BuildContext context) {
    final emojis = ["☕", "💧", "📖", "🏃‍♀️", "🧘", "🎧", "🌿", "🔥", "⭐", "💤", "🍎", "💻"];
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 260,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: emojis.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () {
              setState(() => selectedEmoji = emojis[i]);
              Navigator.pop(context);
            },
            child: Center(
              child: Text(emojis[i], style: const TextStyle(fontSize: 26)),
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 Renk seçici
  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Renk Seç"),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: (color) => setState(() => selectedColor = color),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tamam")),
        ],
      ),
    );
  }

  // 🔽 Liste seçici dialog
  void _showSelectionDialog({
    required String title,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(options[i]),
                  onTap: () {
                    onSelected(options[i]);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ⏰ Saat seçici
  Future<void> _pickTime() async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => selectedTime = picked);
  }
}
