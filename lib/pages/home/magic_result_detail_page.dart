import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MagicResultDetailPage extends StatefulWidget {
  final String title;
  final String beforeImg;
  final String afterImg;

  const MagicResultDetailPage({
    super.key,
    required this.title,
    required this.beforeImg,
    required this.afterImg,
  });

  @override
  State<MagicResultDetailPage> createState() => _MagicResultDetailPageState();
}

class _MagicResultDetailPageState extends State<MagicResultDetailPage> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _sliderValue += details.delta.dx / constraints.maxWidth;
                      _sliderValue = _sliderValue.clamp(0.0, 1.0);
                    });
                  },
                  child: Stack(
                    children: [
                      // Background: After Image (Clean)
                      Image.network(
                        widget.afterImg,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      // Foreground: Before Image (Dirty) - Clipped
                      ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: _sliderValue,
                          child: Image.network(
                            widget.beforeImg,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Slider Handle
                      Positioned(
                        left: constraints.maxWidth * _sliderValue - 2, // Center the line
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        left: constraints.maxWidth * _sliderValue - 15,
                        top: constraints.maxHeight / 2 - 15,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: const Icon(Icons.compare_arrows, size: 20, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Drag the slider to compare before and after.",
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
