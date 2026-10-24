import 'package:flutter/material.dart';
import 'dart:ui';

class AuthBackgroound extends StatefulWidget {
  final List<String>? posterUrls;

  final double overlayOpacity;

  final double blurSigma;

  final int animationDurationSeconds;

  const AuthBackgroound({
    super.key,
    this.posterUrls,
    this.overlayOpacity = 0.70,
    this.blurSigma = 6.0,
    this.animationDurationSeconds = 50,
  });

  @override
  State<AuthBackgroound> createState() => _AuthBackgrooundState();
}

class _AuthBackgrooundState extends State<AuthBackgroound>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<String> _defaultPosters = const [
    'https://image.tmdb.org/t/p/w300/q6y0Go1tsGEsmtFryDO23A9A2R.jpg', // The Dark Knight
    'https://image.tmdb.org/t/p/w300/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg', // Fight Club
    'https://image.tmdb.org/t/p/w300/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg', // Inception
    'https://image.tmdb.org/t/p/w300/7WsyChLLEz3pA2T3B8R229A393N.jpg', // Oppenheimer
    'https://image.tmdb.org/t/p/w300/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg', // Interstellar
    'https://image.tmdb.org/t/p/w300/rC24212Ch3ES83P3P1P2g54433.jpg', // Dune: Part Two
    'https://image.tmdb.org/t/p/w300/saA2L361a99Y0LqA539G1Y.jpg', // Pulp Fiction
    'https://image.tmdb.org/t/p/w300/393141123498N3.jpg',
    'https://image.tmdb.org/t/p/w300/6KErcA283B25s2S446.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.animationDurationSeconds),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listToUse = widget.posterUrls ?? _defaultPosters;

    return Stack(
      children: [
        // 1. KATMAN: Çapraz Kayan Poster Grid
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // X ve Y yönünde pürüzsüz kaydırma hesabı
              // Dikişsiz (seamless) geçiş için offset hesaplaması
              double offset = _controller.value * 250.0;
              return Transform.translate(
                offset: Offset(-offset, -offset),
                child: child,
              );
            },
            child: OverflowBox(
              // Ekranın dışına taşan posterlerin görünmesini sağlayarak boşluk oluşmasını engeller
              maxWidth: MediaQuery.of(context).size.width * 2.0,
              maxHeight: MediaQuery.of(context).size.height * 2.0,
              alignment: Alignment.topLeft,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 12, // Ekrandaki sütun sayısı
                  childAspectRatio: 0.67, // Standard 2:3 film poster oranı
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 200, // Matrisi dolduracak kadar eleman
                itemBuilder: (context, index) {
                  final posterUrl = listToUse[index % listToUse.length];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.movie, color: Colors.white24),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // 2. KATMAN: Blur (Bulanıklık) Katmanı
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: widget.blurSigma,
              sigmaY: widget.blurSigma,
            ),
            child: Container(color: Colors.transparent),
          ),
        ),

        // 3. KATMAN: Karartma (Overlay) Katmanı
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(widget.overlayOpacity),
          ),
        ),
      ],
    );
  }
}
