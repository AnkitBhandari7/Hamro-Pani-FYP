import 'package:flutter/material.dart';
import '../../core/routes/app_navigation.dart';
import '../../core/routes/routes.dart';
import '../screens/booking_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String route = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userLocation = "Kathmandu, Nepal";
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 1:
        AppNavigation.to(context, AppRoutes.orders);
        break;
      case 2:
        AppNavigation.to(context, AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF007BFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Notifications coming soon!")),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your Location", style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(userLocation, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.location_on, color: Colors.white), onPressed: () {})],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: [Color(0xFF007BFF), Color(0xFF0056D2)]),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome to", style: TextStyle(color: Colors.white, fontSize: 18)),
                    Text("TANKER TAP", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("Pure water delivery in 60 minutes!", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Text("Choose Tanker Size", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Tanker Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.78,
                children: const [
                  _TankerCard(capacity: "4000 LTR", price: "Rs. 1,200", image: "4000 LTR", color: Colors.orange),
                  _TankerCard(capacity: "5000 LTR", price: "Rs. 1,500", image: "5000 LTR", color: Colors.blue),
                  _TankerCard(capacity: "6000 LTR", price: "Rs. 1,800", image: "6000 LTR", color: Colors.green),
                  _TankerCard(capacity: "11000 LTR", price: "Rs. 3,300", image: "11000 LTR", color: Colors.purple),
                ],
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF007BFF),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// Updated Tanker Card with Navigation to BookingScreen
class _TankerCard extends StatelessWidget {
  final String capacity;
  final String price;
  final String image;
  final Color color;

  const _TankerCard({
    required this.capacity,
    required this.price,
    required this.image,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          // Image Section
          Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.25), color.withOpacity(0.05)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/tanker_$image.png',
                height: 82,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset('assets/images/tanker1.png', height: 82, fit: BoxFit.contain),
              ),
            ),
          ),

          // Info + Button Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      FittedBox(
                        child: Text(capacity, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        child: Text(price, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                      ),
                    ],
                  ),

                  // BOOK NOW BUTTON → Opens Slot Booking Screen
                  SizedBox(
                    height: 38,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingScreen(
                              capacity: capacity,
                              price: price,
                              accentColor: color,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.zero,
                      ),
                      child: const FittedBox(
                        child: Text(
                          "BOOK NOW",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}