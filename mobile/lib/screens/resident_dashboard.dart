import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
<<<<<<< HEAD

class ResidentDashboardScreen extends StatelessWidget {
  const ResidentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
=======
import 'package:intl/intl.dart';
import '../../core/routes/app_navigation.dart';
import '../../core/routes/routes.dart';
import 'package:fyp/profile/profile_screen.dart';
import 'package:fyp/models/notification_model.dart';
import 'package:fyp/notifications/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';



class ResidentDashboardScreen extends StatefulWidget {
  final String userName;
  final String phone;
  final String email;
  final String? ward;

  const ResidentDashboardScreen({
    super.key,
    required this.userName,
    required this.phone,
    required this.email,
    this.ward,
  });

  @override
  State<ResidentDashboardScreen> createState() => _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  List<AppNotification> notifications = [];
  bool loading = true;

  Future<void> subscribeToAllResidents() async {
    //  Global topic for notices sent to all residents
    await FirebaseMessaging.instance.subscribeToTopic("all_residents");
    debugPrint("Subscribed to: all_residents");
  }

  Future<void> subscribeToWard(String ward) async {
    final topic = 'ward_' + ward.toLowerCase().replaceAll(' ', '_');

    await FirebaseMessaging.instance.subscribeToTopic(topic);

    print("Subscribed to: $topic");
  }


  @override
  void initState() {
    super.initState();
    // Subscribe in background
    () async {
      try {
        // request permission
        await FirebaseMessaging.instance.requestPermission();

        await subscribeToAllResidents();

        if (widget.ward != null && widget.ward!.trim().isNotEmpty) {
          await subscribeToWard(widget.ward!.trim());
        }
      } catch (e) {
        debugPrint("FCM subscribe error: $e");
      }
    }();

    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    if (widget.ward == null) return;

    try {
      final data = await NotificationService.getNotifications(ward: widget.ward!);
      if (!mounted) return;
      setState(() {
        notifications = data;
        loading = false;
      });
    } catch (e) {
      debugPrint("Fetch notifications failed: $e");
      if (!mounted) return;
      setState(() => loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    print("Dashboard received ward: ${widget.ward}");
    final now = DateTime.now();
    final currentTime = DateFormat('h:mm a').format(now);
    final currentDate = DateFormat('MMM d, yyyy').format(now);

>>>>>>> main
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
<<<<<<< HEAD
              // Header - Name & Location
=======
              // Header
>>>>>>> main
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
<<<<<<< HEAD
                          "Namaste, Aarya 👋",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
=======
                          "Namaste, ${widget.userName} 👋"
                          ,
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
>>>>>>> main
                        ),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
<<<<<<< HEAD
                              "Kathmandu, Ward 4",
=======
                              widget.ward != null ? "Kathmandu, ${widget.ward}" : "Ward not set",
>>>>>>> main
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
<<<<<<< HEAD
=======
                  // Notification Bell
>>>>>>> main
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, size: 28),
<<<<<<< HEAD
                        onPressed: () {},
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
=======
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (_) => NotificationList(notifications),
                          );
                        },
                      ),
                      if (notifications.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),

>>>>>>> main
                ],
              ),

              const SizedBox(height: 24),

<<<<<<< HEAD
              // Today's Supply Card
              Row(
                children: [
                  Text(
                    "Today's Supply",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "On Schedule",
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.green[800]),
                    ),
=======
              // Today's Supply
              Row(
                children: [
                  Text("Today's Supply", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(20)),
                    child: Text("On Schedule", style: GoogleFonts.poppins(fontSize: 12, color: Colors.green[800])),
>>>>>>> main
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Next Supply Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
<<<<<<< HEAD
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
=======
                  gradient: const LinearGradient(colors: [Colors.blue, Colors.blueAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
>>>>>>> main
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
<<<<<<< HEAD
                        Text(
                          "Next Supply",
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
=======
                        Text("Next Supply", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70)),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
>>>>>>> main
                          child: const Icon(Icons.water_drop, color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
<<<<<<< HEAD
                    Text(
                      "4:00 PM",
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Expected duration: 2 hours",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                    ),
=======
                    Text(currentTime, style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("Expected duration: 2 hours", style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
>>>>>>> main
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
<<<<<<< HEAD
                        Text(
                          "Sep 12, 2023",
                          style: GoogleFonts.poppins(color: Colors.white70),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Normal Flow",
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                          ),
=======
                        Text(currentDate, style: GoogleFonts.poppins(color: Colors.white70)),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                          child: Text("Normal Flow", style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
>>>>>>> main
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.local_shipping_outlined,
                      label: "Book Tanker",
<<<<<<< HEAD
                      onTap: () {},
=======
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Opening Book Tanker...")),
                        );
                      },
>>>>>>> main
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.warning_amber_outlined,
                      label: "Report Issue",
                      color: Colors.orange[100],
                      iconColor: Colors.orange,
<<<<<<< HEAD
                      onTap: () {},
=======
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Opening Report Issue...")),
                        );
                      },
>>>>>>> main
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

<<<<<<< HEAD
              // Nearby Tankers Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Nearby Tankers",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "View All",
                      style: GoogleFonts.poppins(color: Colors.blue),
                    ),
                  ),
=======
              // Nearby Tankers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Nearby Tankers", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  TextButton(onPressed: () {}, child: Text("View All", style: GoogleFonts.poppins(color: Colors.blue))),
>>>>>>> main
                ],
              ),

              const SizedBox(height: 16),

<<<<<<< HEAD
              // Tanker Cards
=======
              // Tanker Cards —
>>>>>>> main
              Row(
                children: [
                  Expanded(
                    child: _buildTankerCard(
                      name: "Kathmandu Water",
                      rating: 4.8,
                      reviews: 120,
                      capacity: "12,000 Ltr",
                      price: "Rs. 3,500",
<<<<<<< HEAD
=======
                      onBook: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Booking Kathmandu Water...")),
                        );
                      },
>>>>>>> main
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTankerCard(
                      name: "Pure Drop",
                      rating: 4.5,
                      reviews: 89,
                      capacity: "7,000 Ltr",
                      price: "Rs. 2,200",
                      isFaded: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

<<<<<<< HEAD
              // Your Reports Header
              Text(
                "Your Reports",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

              // Report Card
=======
              // Your Reports
              Text("Your Reports", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
>>>>>>> main
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
<<<<<<< HEAD
                  // Fixed: Removed 'const' from Offset
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
=======
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
>>>>>>> main
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
<<<<<<< HEAD
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        shape: BoxShape.circle,
                      ),
=======
                      decoration: BoxDecoration(color: Colors.yellow[100], shape: BoxShape.circle),
>>>>>>> main
                      child: const Icon(Icons.waves, color: Colors.orange, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
<<<<<<< HEAD
                          Text(
                            "Missed Delivery",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "Ticket #4521 • Yesterday",
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                          ),
=======
                          Text("Missed Delivery", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          Text("Ticket #4521 • Yesterday", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
>>>>>>> main
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
<<<<<<< HEAD
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "In Review",
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue),
                      ),
=======
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
                      child: Text("In Review", style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue)),
>>>>>>> main
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

<<<<<<< HEAD
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          currentIndex: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Bookings"),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Reports"),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
=======
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
            // Already on Home
              break;
            case 1:
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening Bookings...")));
              break;
            case 2:
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening Reports...")));
              break;
            case 3:
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening History...")));
              break;
            case 4:
              AppNavigation.push(
                context,
                AppRoutes.profile,
                arguments: {
                  'userName': widget.userName,
                  'phone': widget.phone,
                  'email': widget.email,
                  'ward': widget.ward,
                },

              );
              break;
          }
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
>>>>>>> main
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    Color? color,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color ?? Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
<<<<<<< HEAD
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4)),
          ],
=======
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
>>>>>>> main
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: iconColor ?? Colors.blue),
            const SizedBox(height: 12),
<<<<<<< HEAD
            Text(
              label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
=======
            Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
>>>>>>> main
          ],
        ),
      ),
    );
  }

  Widget _buildTankerCard({
    required String name,
    required double rating,
    required int reviews,
    required String capacity,
    required String price,
    bool isFaded = false,
<<<<<<< HEAD
=======
    VoidCallback? onBook,
>>>>>>> main
  }) {
    return Opacity(
      opacity: isFaded ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
<<<<<<< HEAD
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4)),
          ],
=======
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
>>>>>>> main
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
<<<<<<< HEAD
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.local_drink, color: Colors.grey[600]),
                ),
=======
                CircleAvatar(radius: 20, backgroundColor: Colors.grey[300], child: Icon(Icons.local_drink, color: Colors.grey[600])),
>>>>>>> main
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
<<<<<<< HEAD
                      Text(
                        name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          Text(
                            "$rating ($reviews reviews)",
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
=======
                      Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "$rating ($reviews reviews)",
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
>>>>>>> main
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
<<<<<<< HEAD
            Text(
              capacity,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.w600),
            ),
=======
            Text(capacity, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(price, style: GoogleFonts.poppins(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.w600)),
>>>>>>> main
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
<<<<<<< HEAD
                onPressed: isFaded ? null : () {},
=======
                onPressed: isFaded ? null : onBook,
>>>>>>> main
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
<<<<<<< HEAD
                child: Text(
                  "Book Now",
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
=======
                child: Text("Book Now", style: GoogleFonts.poppins(color: Colors.white)),
>>>>>>> main
              ),
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
=======
}

// Notification UI
Widget NotificationList(List<AppNotification> notifications) {
  return Container(
    padding: const EdgeInsets.all(16),
    height: 400,
    child: notifications.isEmpty
        ? const Center(child: Text("No notifications"))
        : ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final n = notifications[index];
        return ListTile(
          leading: const Icon(Icons.water_drop, color: Colors.blue),
          title: Text(n.title),
          subtitle: Text(n.message),
          trailing: Text(DateFormat('hh:mm a').format(n.createdAt),
              style: const TextStyle(fontSize: 12)),
        );
      },
    ),
  );
>>>>>>> main
}