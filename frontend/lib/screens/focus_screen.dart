import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../models/character_model.dart';
import '../services/character_service.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  CharacterModel? _character;
  bool _isLoading = true;
  int _totalSeconds = 0; // Toplam saniye
  int _remainingSeconds = 0; // Kalan saniye
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  double _rotationAngle = 0.0; // Slider açısı (0-2π)
  final int _totalSegments = 240; // Toplam parça sayısı
  final int _secondsPerSegment = 15; // Her parça 15 saniye

  @override
  void initState() {
    super.initState();
    _loadCharacter();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCharacter() async {
    try {
      final character = await CharacterService.getCharacter()
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _character = character;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateTimeFromAngle(double angle) {
    // Açıyı 0-2π aralığına normalize et
    angle = angle % (2 * math.pi);
    if (angle < 0) angle += 2 * math.pi;
    
    // Açıyı segment numarasına çevir (0-239)
    final segment = (angle / (2 * math.pi) * _totalSegments).round() % _totalSegments;
    
    // Segment'ten toplam saniyeyi hesapla
    final newTotalSeconds = segment * _secondsPerSegment;
    
    // Açıyı segment'e göre güncelle (tam segment pozisyonu)
    final normalizedAngle = (segment / _totalSegments) * 2 * math.pi;
    
    setState(() {
      _totalSeconds = newTotalSeconds;
      _rotationAngle = normalizedAngle;
      if (!_isRunning) {
        _remainingSeconds = _totalSeconds;
      }
    });
  }

  double _angleFromTime(int seconds) {
    // Saniyeyi segment'e çevir
    final segment = (seconds / _secondsPerSegment).round() % _totalSegments;
    // Segment'ten açıya çevir
    return (segment / _totalSegments) * 2 * math.pi;
  }

  int _getActiveSegments() {
    if (_totalSeconds == 0) return 0;
    return (_totalSeconds / _secondsPerSegment).round();
  }

  int _getActiveSegmentsFromRemaining() {
    if (_remainingSeconds == 0) return 0;
    return (_remainingSeconds / _secondsPerSegment).round();
  }

  void _startTimer() {
    if (_totalSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az 15 saniye seçin')),
      );
      return;
    }

    setState(() {
      _remainingSeconds = _totalSeconds;
      _isRunning = true;
      _isPaused = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
          _isPaused = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Süre doldu! 🎉')),
        );
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    if (_remainingSeconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
            _isPaused = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Süre doldu! 🎉')),
          );
        }
      });
      setState(() {
        _isPaused = false;
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
      _isPaused = false;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    if (_totalSeconds == 0) return 0.0;
    return 1.0 - (_remainingSeconds / _totalSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: themeProvider.primaryColor,
                ),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Character Image (Emoji)
                      if (_character != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _getCharacterEmoji(_character!.type),
                              style: const TextStyle(fontSize: 70),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Circular Timer with Rotary Slider
                      Container(
                        width: 320,
                        height: 320,
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        child: GestureDetector(
                          onPanUpdate: !_isRunning ? (details) {
                            // Container'ın merkezini hesapla (320x320 sabit boyut)
                            const containerSize = 320.0;
                            const center = Offset(containerSize / 2, containerSize / 2);
                            
                            // Dokunma pozisyonunu container'a göre ayarla
                            final localPosition = details.localPosition - center;
                            
                            // Açıyı hesapla (atan2 ile -π'den π'ye, sonra normalize et)
                            double angle = math.atan2(localPosition.dy, localPosition.dx);
                            angle += math.pi / 2; // 0'ı üstte başlat
                            if (angle < 0) angle += 2 * math.pi;
                            
                            _updateTimeFromAngle(angle);
                          } : null,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer Rotary Slider Circle (if not running)
                              if (!_isRunning)
                                CustomPaint(
                                  size: const Size(320, 320),
                                  painter: _CircularSliderPainter(
                                    activeSegments: _getActiveSegments(),
                                    totalSegments: _totalSegments,
                                    color: themeProvider.primaryColor,
                                    rotationAngle: _rotationAngle,
                                  ),
                                ),
                              // Progress Circle (if running) - segmented
                              if (_isRunning)
                                CustomPaint(
                                  size: const Size(320, 320),
                                  painter: _CircularSliderPainter(
                                    activeSegments: _getActiveSegmentsFromRemaining(),
                                    totalSegments: _totalSegments,
                                    color: themeProvider.primaryColor,
                                    rotationAngle: _angleFromTime(_remainingSeconds),
                                    showHandle: false, // Timer çalışırken handle gösterme
                                  ),
                                ),
                              // Inner circle background
                              Container(
                                width: 240,
                                height: 240,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              // Time Display
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatTime(_remainingSeconds),
                                    style: context.textStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.primaryColor,
                                    ),
                                  ),
                                  if (!_isRunning && _remainingSeconds == 0) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Çemberi döndürün',
                                      style: context.textStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Controls
                      if (!_isRunning) ...[
                        const SizedBox(height: 20),
                        // Total Time Display
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: themeProvider.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: themeProvider.primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule,
                                color: themeProvider.primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Toplam Süre: ${_formatTime(_totalSeconds)}',
                                style: context.textStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: themeProvider.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Start Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _totalSeconds > 0 ? _startTimer : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                'Başlat',
                                style: context.whiteTextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ] else ...[
                        const SizedBox(height: 20),
                        // Pause/Resume and Stop buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isPaused) ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _resumeTimer,
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Devam Et'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pauseTimer,
                                    icon: const Icon(Icons.pause),
                                    label: const Text('Duraklat'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _stopTimer,
                                  icon: const Icon(Icons.stop),
                                  label: const Text('Durdur'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _getCharacterEmoji(CharacterType type) {
    switch (type) {
      case CharacterType.cat:
        return '🐱';
      case CharacterType.dog:
        return '🐶';
      case CharacterType.rabbit:
        return '🐰';
      case CharacterType.fox:
        return '🦊';
    }
  }
}

// Custom Painter for Circular Slider
class _CircularSliderPainter extends CustomPainter {
  final int activeSegments;
  final int totalSegments;
  final Color color;
  final double rotationAngle;
  final bool showHandle;

  _CircularSliderPainter({
    required this.activeSegments,
    required this.totalSegments,
    required this.color,
    required this.rotationAngle,
    this.showHandle = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Her segment için açı
    final segmentAngle = (2 * math.pi) / totalSegments;

    for (int i = 0; i < totalSegments; i++) {
      final startAngle = i * segmentAngle - math.pi / 2; // Üstten başlat
      final endAngle = startAngle + segmentAngle * 0.8; // Segment'ler arası boşluk

      if (i < activeSegments) {
        // Aktif segmentler - renkli
        paint.color = color;
      } else {
        // Pasif segmentler - gri
        paint.color = Colors.grey[300]!;
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }

    // Slider handle (şu anki pozisyonu gösteren nokta) - sadece gösterilecekse
    if (showHandle && activeSegments > 0) {
      final handleAngle = rotationAngle - math.pi / 2;
      final handleX = center.dx + radius * math.cos(handleAngle);
      final handleY = center.dy + radius * math.sin(handleAngle);

      final handlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(handleX, handleY),
        12,
        handlePaint,
      );

      // Handle iç beyaz nokta
      final innerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(handleX, handleY),
        6,
        innerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularSliderPainter oldDelegate) {
    return oldDelegate.activeSegments != activeSegments ||
        oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.color != color;
  }
}
