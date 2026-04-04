import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  final String capacity;
  final String price;
  final Color accentColor;

  const BookingScreen({
    super.key,
    required this.capacity,
    required this.price,
    required this.accentColor,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final List<String> timeSlots = [
    "6-8 AM",
    "8-10 AM",
    "10-12 PM",
    "12-2 PM",
    "2-4 PM",
    "4-6 PM",
    "6-8 PM",
    "8-10 PM",
  ];

  final Set<int> bookedSlots = {1, 4, 6};
  int? selectedSlot;

  String get imageName => widget.capacity.replaceAll(' ', '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: widget.accentColor,
        title: const Text("Choose Delivery Slot"),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tanker Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/tanker_$imageName.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/tanker1.png',
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.capacity,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Water Tanker",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.price,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: widget.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Available Today Slots",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          // TIME SLOTS — 100% NO OVERFLOW (EVEN 0.001px)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.15, // ← Final magic number
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: timeSlots.length,
              itemBuilder: (context, index) {
                final isBooked = bookedSlots.contains(index);
                final isSelected = selectedSlot == index;

                return GestureDetector(
                  onTap: isBooked
                      ? null
                      : () => setState(() => selectedSlot = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isBooked
                          ? Colors.red[100]
                          : isSelected
                          ? widget.accentColor
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isBooked
                            ? Colors.red
                            : isSelected
                            ? widget.accentColor
                            : Colors.green,
                        width: 1.6,
                      ),
                    ),
                    child: FittedBox(
                      // ← THIS IS THE ULTIMATE FIX
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(8), // Small safe padding
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isBooked ? Icons.close : Icons.access_time,
                              size: 20,
                              color: isBooked
                                  ? Colors.red[700]
                                  : isSelected
                                  ? Colors.white
                                  : Colors.green[700],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeSlots[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isBooked
                                    ? Colors.red[700]
                                    : isSelected
                                    ? Colors.white
                                    : Colors.green[800],
                              ),
                            ),
                            if (isBooked)
                              const Text(
                                "BOOKED",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: selectedSlot == null
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Confirmed! ${widget.capacity} booked for ${timeSlots[selectedSlot!]}",
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  disabledBackgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  selectedSlot == null ? "Select a Slot" : "Confirm Booking",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
