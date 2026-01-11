enum CharacterType {
  cat('cat', 'Kedi', 'assets/pets/cat.png'),
  dog('dog', 'Köpek', 'assets/pets/dog.png'),
  rabbit('rabbit', 'Tavşan', 'assets/pets/rabbit.png'),
  fox('fox', 'Tilki', 'assets/pets/fox.png');

  final String value;
  final String label;
  final String imagePath;

  const CharacterType(this.value, this.label, this.imagePath);
}

class CharacterModel {
  final CharacterType type;
  final int level;
  final int energy; // 0-100
  final int happiness; // 0-100
  final int totalXp;
  final String? customName;

  CharacterModel({
    required this.type,
    this.level = 1,
    this.energy = 50,
    this.happiness = 50,
    this.totalXp = 0,
    this.customName,
  });

  // XP'ye göre seviye hesaplama (starts at 100, increases by 50 each level)
  int get calculatedLevel {
    if (totalXp < 100) return 1;
    int currentLevel = 1;
    int requiredXp = 100;
    int totalRequiredXp = 0;
    
    while (totalXp >= totalRequiredXp + requiredXp) {
      totalRequiredXp += requiredXp;
      currentLevel++;
      requiredXp += 50; // Each level needs 50 more XP than previous
    }
    
    return currentLevel;
  }

  // Bir sonraki seviye için gereken XP (level 1->2: 100, level 2->3: 150, etc.)
  int get xpForNextLevel {
    if (level < 1) return 100;
    // Level 1 needs 100 XP, level 2 needs 150 XP, level 3 needs 200 XP, etc.
    return 100 + (level - 1) * 50;
  }

  // Mevcut seviye için başlangıç XP (previous levels' total XP)
  int get _xpForCurrentLevel {
    if (level <= 1) return 0;
    int totalRequiredXp = 0;
    int requiredXp = 100;
    for (int i = 1; i < level; i++) {
      totalRequiredXp += requiredXp;
      requiredXp += 50;
    }
    return totalRequiredXp;
  }

  // Mevcut seviye için XP progress (current level'da kazanılan XP)
  int get currentLevelXp {
    return totalXp - _xpForCurrentLevel;
  }

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      type: CharacterType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => CharacterType.cat,
      ),
      level: json['level'] as int? ?? 1,
      energy: json['energy'] as int? ?? 50,
      happiness: json['happiness'] as int? ?? 50,
      totalXp: json['total_xp'] as int? ?? 0,
      customName: json['custom_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'level': level,
      'energy': energy,
      'happiness': happiness,
      'total_xp': totalXp,
      'custom_name': customName,
    };
  }

  CharacterModel copyWith({
    CharacterType? type,
    int? level,
    int? energy,
    int? happiness,
    int? totalXp,
    String? customName,
  }) {
    return CharacterModel(
      type: type ?? this.type,
      level: level ?? this.level,
      energy: energy ?? this.energy,
      happiness: happiness ?? this.happiness,
      totalXp: totalXp ?? this.totalXp,
      customName: customName ?? this.customName,
    );
  }
}

