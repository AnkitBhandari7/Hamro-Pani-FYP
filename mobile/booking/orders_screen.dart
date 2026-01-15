// lib/views/driver/driver_order_screen.dart
import 'package:flutter/material.dart';

class OrderScreen extends StatefulWidget {
  static const String route = '/orders';
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _DriverOrderScreenState();
}

class _DriverOrderScreenState extends State<OrderScreen> {
  bool workMode = true;
  int selectedIndex = 1; // My Tankers tab

  final List<Map<String, dynamic>> orders = [
    {
      "id": "#100139",
      "status": "On the way",
      "color": Colors.green,
      "time": "08 Sep 2025, 06:00 AM",
      "customer": "TEST USER",
      "amount": "Rs 600",
      "address": "46 46, Nelamangala - Chikkaballapura, 46, Gollahalli, Bangalore Division, Karnataka, 562123, India"
    },
    {
      "id": "#100143",
      "status": "Confirmed",
      "color": Colors.orange,
      "time": "08 Sep 2025, 12:00 PM",
      "customer": "TEST USER",
      "amount": "Rs 600",
      "address": "46 46, Nelamangala - Chikkaballapura, 46, Gollahalli, Bangalore Division, Karnataka, 562123, India"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.blue[50],
            child: Icon(Icons.local_drink, color: Colors.blue[700]),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("LAVA WATER SUPPLY", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("46 , Gollahalli, Karnataka 562123, India",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Work Mode Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Work Mode", style: TextStyle(fontSize: 16)),
                  Switch(
                    value: workMode,
                    activeColor: Colors.green,
                    onChanged: (val) => setState(() => workMode = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Your Earnings
            const Text("Your Earnings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Row(
              children: [
                _earningCard("Daily", "₹ 0", Icons.today),
                const SizedBox(width: 12),
                _earningCard("Weekly", "₹ 1176", Icons.trending_up),
                const SizedBox(width: 12),
                _earningCard("Monthly", "₹ 2158.9", Icons.calendar_month),
              ],
            ),

            const SizedBox(height: 24),

            // Order List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Order List:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  "Total orders for delivery (${orders.length})",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Orders List
            ...orders.map((order) => _buildOrderCard(order)).toList(),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: "My Tankers"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _earningCard(String title, String amount, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[600],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 4),
            Text(amount, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order["id"], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: order["color"].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order["status"],
                    style: TextStyle(color: order["color"], fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _infoRow("Delivery Slot:", order["time"]),
            _infoRow("Customer Name:", order["customer"]),
            _infoRow("Order Amount:", order["amount"]),
            _infoRow("Address:", order["address"], isAddress: true),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isAddress = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isAddress ? Colors.grey[700] : Colors.black87,
                fontSize: isAddress ? 13 : 14,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}