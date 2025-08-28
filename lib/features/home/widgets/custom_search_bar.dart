// 11. lib/widgets/custom_search_bar.dart
import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(String, String, DateTime?) onSearch;

  const CustomSearchBar({super.key, required this.onSearch});

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final sourceController = TextEditingController();
  final destinationController = TextEditingController();
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: sourceController,
              decoration: InputDecoration(
                labelText: "Source",
                prefixIcon: const Icon(
                  Icons.location_on,
                  color: Colors.redAccent,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: destinationController,
              decoration: InputDecoration(
                labelText: "Destination",
                prefixIcon: const Icon(Icons.flag, color: Colors.redAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Text(
                      selectedDate == null
                          ? "Select Date"
                          : selectedDate!.toLocal().toString().split(' ')[0],
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final source = sourceController.text.trim();
                final dest = destinationController.text.trim();
                if (source.isNotEmpty &&
                    dest.isNotEmpty &&
                    selectedDate != null) {
                  widget.onSearch(source, dest, selectedDate);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Fill all fields")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                "Search Buses",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
