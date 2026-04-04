import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:fyp/l10n/app_localizations.dart';
import '../services/tanker_service.dart';

// controller that manages the find tankers screen state
// handles fetching, searching, filtering vendors
class FindTankersController extends ChangeNotifier {
  static const String filterAll = 'All';
  static const String filterAvailableNow = 'Available Now';
  static const String filterLowStock = 'Low Stock';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // error message to show when fetch fails
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> _tankers = [];
  List<Map<String, dynamic>> get tankers => _tankers;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedFilter = filterAll;
  String get selectedFilter => _selectedFilter;

  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  FindTankersController() {
    // listen to search text changes and debounce the api call
    searchController.addListener(() {
      _searchQuery = searchController.text.trim();
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), fetchTankers);
    });

    fetchTankers();
  }

  // get firebase auth token for api calls
  Future<String> _requireToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not authenticated");

    final String? token = await user.getIdToken(true);
    if (token == null || token.trim().isEmpty) {
      throw Exception("Failed to get Firebase token");
    }
    return token;
  }

  // convert filter label to api query param
  String _filterToApi(String f) {
    final x = f.toLowerCase().trim();
    if (x == "all") return "all";
    if (x == "available now") return "available_now";
    if (x == "busy") return "busy";
    if (x == "low stock") return "low_stock";
    return "all";
  }

  // fetch tanker list from backend
  Future<void> fetchTankers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _requireToken();

      _tankers = await TankerService.getNearbyTankers(
        token: token,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        filter: _filterToApi(_selectedFilter),
      );
    } catch (e) {
      _tankers = [];
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // update the selected filter chip and reload
  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
    fetchTankers();
  }

  // book a specific slot with payment method
  Future<void> bookSlot(int slotId, {required String paymentMethod}) async {
    final token = await _requireToken();

    await TankerService.bookTankerSlot(
      token: token,
      slotId: slotId,
      paymentMethod: paymentMethod,
    );

    await fetchTankers();
  }

  // show demand message only when available now filter is active
  String getDemandMessage(AppLocalizations t) {
    if (_selectedFilter == filterAvailableNow) {
      return t.demandMessageAvailableNow;
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