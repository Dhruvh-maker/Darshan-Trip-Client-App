import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/onboarding_viewmodel.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();
    final PageController controller = PageController();
    final screenHeight = MediaQuery.of(context).size.height;

    final List<Map<String, dynamic>> pages = [
      {
        "title": "Welcome to Darshan Trip",
        "desc":
            "Plan your sacred journeys with ease. Explore trusted travel options and start your pilgrimage hassle-free.",
        "lottie": "assets/lottie/HiGirl.json",
        "bgColor": const Color(0xFFFFF8E1), // Light orange
        "accentColor": Colors.orange.shade600,
        "isLottie": true, // Changed from false to true
      },
      {
        "title": "Safe & Secure Payments",
        "desc":
            "Pay confidently with UPI, cards, wallets, or net banking. Your transactions are encrypted and secure.",
        "lottie": "assets/lottie/PayNow.json",
        "bgColor": const Color(0xFFE3F2FD), // Light blue
        "accentColor": Colors.blue.shade600,
        "isLottie": true,
      },
      {
        "title": "Your Tickets, Your Control",
        "desc":
            "Instant access to your tickets. Manage bookings, cancel, or reschedule — all in one place.",
        "lottie": "assets/lottie/BusTicket.json",
        "bgColor": const Color(0xFFE8F5E8), // Light green
        "accentColor": Colors.green.shade600,
        "isLottie": true,
      },
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [pages[viewModel.currentPage]["bgColor"], Colors.white],
                stops: const [0.0, 0.7],
              ),
            ),
          ),

          // Skip button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: pages[viewModel.currentPage]["accentColor"],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Back button (only show from second page)
          if (viewModel.currentPage > 0)
            Positioned(
              top: 50,
              left: 20,
              child: IconButton(
                onPressed: () {
                  controller.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: pages[viewModel.currentPage]["accentColor"],
                ),
              ),
            ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // PageView content
                Expanded(
                  child: PageView.builder(
                    controller: controller,
                    itemCount: pages.length,
                    onPageChanged: (index) => viewModel.changePage(index),
                    itemBuilder: (_, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            const Spacer(flex: 1),

                            // Lottie animation container
                            Container(
                              height: screenHeight * 0.35,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: pages[index]["accentColor"]
                                        .withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment.center,
                                      radius: 1.0,
                                      colors: [
                                        Colors.white.withOpacity(0.8),
                                        pages[index]["bgColor"].withOpacity(
                                          0.3,
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: Hero(
                                    tag: pages[index]["title"]!,
                                    child: Lottie.asset(
                                      pages[index]["lottie"]!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const Spacer(flex: 1),

                            // Title
                            Text(
                              pages[index]["title"]!,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2B1B15),
                                letterSpacing: 0.5,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 20),

                            // Description
                            Text(
                              pages[index]["desc"]!,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const Spacer(flex: 1),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom section with dots and button
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                  child: Column(
                    children: [
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: viewModel.currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: viewModel.currentPage == index
                                  ? pages[viewModel.currentPage]["accentColor"]
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Action button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              pages[viewModel.currentPage]["accentColor"],
                              pages[viewModel.currentPage]["accentColor"]
                                  .withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: pages[viewModel.currentPage]["accentColor"]
                                  .withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 0,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (viewModel.currentPage < pages.length - 1) {
                              controller.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                viewModel.currentPage == pages.length - 1
                                    ? 'Get Started'
                                    : 'Next',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
