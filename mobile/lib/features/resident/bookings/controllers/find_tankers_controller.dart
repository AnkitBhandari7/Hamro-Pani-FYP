import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/tanker_service.dart';

class FindTankersController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _tankers = [];
  List<Map<String, dynamic>> get tankers => _tankers;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedFilter = 'All';
  String get selectedFilter => _selectedFilter;

  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  FindTankersController() {
    searchController.addListener(() {
      _searchQuery = searchController.text.trim();
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), fetchTankers);
    });

    fetchTankers();
  }

  Future<String> _requireToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not authenticated");

    final String? token = await user.getIdToken(true);
    if (token == null || token.trim().isEmpty) {
      throw Exception("Failed to get Firebase token");
    }
    return token;
  }

  String _filterToApi(String f) {
    final x = f.toLowerCase().trim();
    if (x == "all") return "all";
    if (x == "available now") return "available_now";
    if (x == "busy") return "busy";
    if (x == "low stock") return "low_stock";
    return "all";
  }

  Future<void> fetchTankers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _requireToken();

      _tankers = await TankerService.getNearbyTankers(
        token: token,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        filter: _filterToApi(_selectedFilter),
      );
    } catch (_) {
      _tankers = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
    fetchTankers();
  }

  // accept payment method
  Future<void> bookSlot(int slotId, {required String paymentMethod}) async {
    final token = await _requireToken();

    await TankerService.bookTankerSlot(
      token: token,
      slotId: slotId,
      paymentMethod: paymentMethod,
    );

    await fetchTankers();
  }

  String getDemandMessage() {
    if (_selectedFilter == "Available Now") {
      return "Many residents are booking now.\nReserve your slot early.";
    }
    return "";
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
