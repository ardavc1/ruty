import 'package:flutter/material.dart';

class PetSelectionScreen extends StatefulWidget {
  const PetSelectionScreen({super.key});

  @override
  State<PetSelectionScreen> createState() => _PetSelectionScreenState();
}

class _PetSelectionScreenState extends State<PetSelectionScreen> {
  String? selectedPet;

  final List<Map<String, String>> pets = [
    {"name": "Köpek", "image": "assets/pets/dog.png"},
    {"name": "Kedi", "image": "assets/pets/cat.png"},
    {"name": "Tavşan", "image": "assets/pets/rabbit.png"},
  ];

  void _selectPet(String petName) {
    setState(() {
      selectedPet = petName;
    });
  }

  void _continue() {
    if (selectedPet != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$selectedPet seçildi!')),
      );
      // Navigator.push(context, MaterialPageRoute(builder: (_) => NextScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir hayvan seçin!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(
        title: const Text('Buddy Seçimi'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Yeni alışkanlık yolculuğunda sana eşlik edecek bir dost seç!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),

          // Hayvan kutuları (animasyonlu)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                final isSelected = selectedPet == pet["name"];
                return GestureDetector(
                  onTap: () => _selectPet(pet["name"]!),
                  child: AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0, // 🔹 Hafif büyüme
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.lightGreen[100] : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected ? Colors.green : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            pet["image"]!,
                            height: 80,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            pet["name"]!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.green[800]
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Devam Et butonu
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              onPressed: _continue,
              child: const Text(
                'Devam Et',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
