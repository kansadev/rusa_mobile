import 'package:flutter/material.dart';
import 'package:rusa/widgets/welcome.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _sliderPosition = 0.0;
  bool _isDragging = false;

  late AnimationController _arrowAnimationController;
  late Animation<double> _arrowAnimation;

  @override
  void initState() {
    super.initState();
    _arrowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _arrowAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _arrowAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Démarrer l'animation en boucle
    _arrowAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _arrowAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Carrousel d'images
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [_buildSlide1(), _buildSlide2()],
                ),
              ),
              const SizedBox(height: 16),
              // Indicateurs de pagination
              _buildPageIndicator(),
              const SizedBox(height: 16),
              // Bouton de navigation
              _buildNavigationButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset('assets/images/img1.png', fit: BoxFit.fitWidth),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
          Text(
            'Voyagez Mieux\nArrivez Plus Sûr',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Rusa Travel. Une touche. Zéro tracas.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSlide2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Image.asset('assets/images/img2.png', fit: BoxFit.cover),
        ),
        const SizedBox(height: 20),
        const Spacer(),
        Text(
          'Votre Voyage\nCommence Ici',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Réservez votre billet en quelques secondes.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: _currentPage == 0 ? 30 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: _currentPage == 0 ? const Color(0xFF00E676) : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: _currentPage == 1 ? 30 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: _currentPage == 1 ? const Color(0xFF00E676) : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButton() {
    if (_currentPage == 0) {
      // Premier slide: bouton "Continuer" simple
      return GestureDetector(
        onTap: () {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white10),
          ),
          child: const Center(
            child: Text(
              'Continuer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    } else {
      // Deuxième slide: slider draggable "Glissez..."
      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white10),
        ),
        child: Stack(
          children: [
            // Texte "Glissez..." par défaut (visible quand on ne glisse pas)
            Positioned.fill(
              child: Opacity(
                opacity: (1.0 - (_sliderPosition / 200)).clamp(0.0, 1.0),
                child: const Center(
                  child: Text(
                    'Glissez votre doigt vers la droite',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Texte "Allons-y" qui apparaît progressivement (visible quand on glisse)
            Positioned.fill(
              child: Opacity(
                opacity: (_sliderPosition / 200).clamp(0.0, 1.0),
                child: const Center(
                  child: Text(
                    'Allons-y',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Slider draggable
            Positioned(
              left: 6 + _sliderPosition,
              top: 6,
              child: GestureDetector(
                onPanStart: (_) {
                  setState(() {
                    _isDragging = true;
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _sliderPosition = (details.globalPosition.dx - 30).clamp(
                      0.0,
                      200.0,
                    );
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _isDragging = false;
                  });

                  // Si le slider a été glissé suffisamment loin, naviguer
                  if (_sliderPosition > 150) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WelcomeScreen(),
                      ),
                    );
                  } else {
                    // Revenir à la position initiale avec animation
                    setState(() {
                      _sliderPosition = 0.0;
                    });
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00E676),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Flèche indicatrice à droite avec animation de va-et-vient
            if (_sliderPosition < 50)
              AnimatedBuilder(
                animation: _arrowAnimation,
                builder: (context, child) {
                  return Positioned(
                    right: 20 - _arrowAnimation.value,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Icon(
                        Icons.keyboard_double_arrow_right,
                        color: Colors.white38,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    }
  }
}
