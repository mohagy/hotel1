/// POS Terminal Screen
/// 
/// Multi-mode POS terminal (Retail, Restaurant, Reservation)
/// Matches PHP POS terminal layout exactly

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../models/reservation_model.dart';
import '../../services/pos_service.dart';
import '../../services/reservation_service.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/formatters.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class POSTerminalScreen extends StatefulWidget {
  final String? initialMode;
  final int? initialReservationId;
  
  const POSTerminalScreen({super.key, this.initialMode, this.initialReservationId});

  @override
  State<POSTerminalScreen> createState() => _POSTerminalScreenState();
}

class _POSTerminalScreenState extends State<POSTerminalScreen> {
  final POSService _posService = POSService();
  final ReservationService _reservationService = ReservationService();
  
  late String _currentMode;
  String _viewType = 'grid'; // 'grid', 'list', 'compact', 'summary'
  
  List<ProductModel> _products = [];
  List<ReservationModel> _reservations = [];
  List<OrderItemModel> _cart = [];
  ReservationModel? _selectedReservation;
  
  // Categories
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId; // 'all' or category ID
  
  bool _isLoading = false;
  String? _error;
  
  // Customer/User info
  String? _currentCustomerName;
  String? _currentCustomerPhone;
  String? _tableNo;
  String? _waiterName;
  
  // Discount
  double _discountTotal = 0.0;
  double _subTotalDiscount = 0.0;
  
  // Order note
  String? _orderNote;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode ?? AppConfig.posModeRetail;
    _selectedCategoryId = 'all';
    _currentCustomerName = 'Walk-in Customer';
    _loadData();
  }
  
  void _filterByCategory(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    // Reload products with category filter
    _loadData();
  }
  
  List<ProductModel> get _filteredProducts {
    if (_selectedCategoryId == null || _selectedCategoryId == 'all') {
      return _products;
    }
    return _products.where((p) => p.categoryId?.toString() == _selectedCategoryId).toList();
  }
  
  int _getCategoryCount(String? categoryId) {
    if (categoryId == null || categoryId == 'all') {
      return _products.length;
    }
    return _products.where((p) => p.categoryId?.toString() == categoryId).length;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_currentMode == AppConfig.posModeReservation) {
        final reservations = await _reservationService.getReservationsForPayment();
        setState(() {
          _reservations = reservations;
          _isLoading = false;
        });
        
        // If initialReservationId is provided, select it
        if (widget.initialReservationId != null) {
          final reservation = _reservations.firstWhere(
            (r) => r.reservationId == widget.initialReservationId,
            orElse: () => _reservations.first,
          );
          if (reservation.reservationId != null) {
            _selectReservation(reservation);
          }
        }
      } else {
        // Load categories and products
        final categories = await _posService.getCategories(mode: _currentMode);
        List<ProductModel> products;
        if (_currentMode == AppConfig.posModeRetail) {
          products = await _posService.getRetailProducts();
        } else if (_currentMode == AppConfig.posModeRestaurant) {
          products = await _posService.getRestaurantMenuItems();
        } else {
          products = [];
        }

        setState(() {
          _categories = categories;
          _products = products;
          _selectedCategoryId = 'all';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectReservation(ReservationModel reservation) {
    setState(() {
      _selectedReservation = reservation;
      _currentCustomerName = reservation.guestName ?? 'Unknown';
      _currentCustomerPhone = reservation.guestPhone;
      _tableNo = reservation.roomNumber;
      
      // Clear cart and add reservation as single item
      _cart = [];
      final balanceDue = reservation.balanceDue ?? reservation.totalPrice ?? 0.0;
      
      _cart.add(OrderItemModel(
        orderId: 0,
        productName: 'Reservation Payment - ${reservation.reservationNumber ?? reservation.roomNumber ?? 'N/A'}',
        quantity: 1,
        price: balanceDue,
        totalAmount: balanceDue,
        isRestaurantItem: false,
        isReservation: true,
      ));
    });
    
    // Show notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: ${reservation.reservationNumber ?? reservation.roomNumber ?? 'N/A'} - Balance: ${Formatters.currency(reservation.balanceDue ?? reservation.totalPrice ?? 0.0)}'),
        backgroundColor: AppColors.statusSuccess,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _addToCart(ProductModel product) {
    setState(() {
      final existingIndex = _cart.indexWhere(
        (item) => item.productId == product.id || item.menuId == product.id,
      );

      if (existingIndex >= 0) {
        final item = _cart[existingIndex];
        _cart[existingIndex] = item.copyWith(
          quantity: item.quantity + 1,
          totalAmount: (item.quantity + 1) * item.price,
        );
      } else {
        _cart.add(OrderItemModel(
          orderId: 0,
          productId: product.id,
          menuId: _currentMode == AppConfig.posModeRestaurant ? product.id : null,
          productName: product.name,
          quantity: 1,
          price: product.price,
          totalAmount: product.price,
          isRestaurantItem: _currentMode == AppConfig.posModeRestaurant,
          isReservation: false,
        ));
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _removeFromCart(index);
      return;
    }

    setState(() {
      final item = _cart[index];
      _cart[index] = item.copyWith(
        quantity: quantity,
        totalAmount: quantity * item.price,
      );
    });
  }

  void _clearCart() {
    setState(() {
      _cart = [];
      _selectedReservation = null;
      _discountTotal = 0.0;
      _subTotalDiscount = 0.0;
      _orderNote = null;
    });
  }

  void _deleteLine(int index) {
    _removeFromCart(index);
  }

  double get _subtotal {
    final cartTotal = _cart.fold(0.0, (sum, item) => sum + item.totalAmount);
    return cartTotal - _discountTotal;
  }

  double get _total {
    return _subtotal - _subTotalDiscount;
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty'),
          backgroundColor: AppColors.statusError,
        ),
      );
      return;
    }

    // In reservation mode, process payment
    if (_currentMode == AppConfig.posModeReservation && _selectedReservation != null) {
      try {
        final success = await _reservationService.processPayment(
          _selectedReservation!.reservationId!,
          {
            'amount': _total,
            'payment_method': 'cash',
          },
        );
        
        if (success && mounted) {
          setState(() {
            _cart = [];
            _selectedReservation = null;
            _orderNote = null;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment processed successfully'),
                backgroundColor: AppColors.statusSuccess,
              ),
            );
            _loadData(); // Refresh reservations
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.statusError,
            ),
          );
        }
      }
      return;
    }

    // Show payment dialog for retail/restaurant mode
    final paymentResult = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PaymentDialog(total: _total),
    );

    if (paymentResult == null) return;

    final paymentMethod = paymentResult['payment_method'] as String? ?? 'cash';
    
    // Regular order processing
    final order = OrderModel(
      subtotal: _subtotal,
      discountTotal: _discountTotal + _subTotalDiscount,
      total: _total,
      status: 'completed',
      paymentMethod: paymentMethod,
      businessMode: _currentMode,
      items: _cart,
      tableNo: _tableNo,
      waiterName: _waiterName,
      comment: _orderNote,
    );

    try {
      final success = await _posService.saveOrder(order);
      if (success && mounted) {
        setState(() {
          _cart = [];
          _discountTotal = 0.0;
          _subTotalDiscount = 0.0;
          _orderNote = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order saved successfully'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    }
  }

  void _applyLineDiscount() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty'),
          backgroundColor: AppColors.statusError,
        ),
      );
      return;
    }

    // Show dialog to select line item and discount
    showDialog(
      context: context,
      builder: (context) => _LineDiscountDialog(
        cart: _cart,
        onDiscountApplied: (index, discountAmount) {
          setState(() {
            final item = _cart[index];
            final newDiscountAmount = discountAmount;
            final newTotalAmount = (item.price * item.quantity) - newDiscountAmount;
            _cart[index] = item.copyWith(
              discountAmount: newDiscountAmount,
              totalAmount: newTotalAmount,
            );
          });
        },
      ),
    );
  }

  Future<void> _holdOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty'),
          backgroundColor: AppColors.statusError,
        ),
      );
      return;
    }

    // Create hold order
    final order = OrderModel(
      subtotal: _subtotal,
      discountTotal: _discountTotal + _subTotalDiscount,
      total: _total,
      status: 'hold',
      paymentMethod: 'cash',
      businessMode: _currentMode,
      items: _cart,
      tableNo: _tableNo,
      waiterName: _waiterName,
      comment: _orderNote,
    );

    try {
      final success = await _posService.saveOrder(order);
      if (success && mounted) {
        setState(() {
          _cart = [];
          _discountTotal = 0.0;
          _subTotalDiscount = 0.0;
          _orderNote = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order held successfully'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    }
  }

  void _applySubTotalDiscount() {
    showDialog(
      context: context,
      builder: (context) => _SubTotalDiscountDialog(
        subtotal: _subtotal,
        currentDiscount: _subTotalDiscount,
        onDiscountApplied: (discount) {
          setState(() {
            _subTotalDiscount = discount;
          });
        },
      ),
    );
  }

  void _showPriceCheck() {
    if (_cart.isEmpty && _products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products available'),
          backgroundColor: AppColors.statusError,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _PriceCheckDialog(products: _products),
    );
  }

  void _showOrderNote() {
    final noteController = TextEditingController(text: _orderNote);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentMode == AppConfig.posModeRestaurant ? 'Kitchen Note' : 'Order Note'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Enter order note...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _orderNote = noteController.text.trim().isEmpty ? null : noteController.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _printHoldBill() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print functionality will be implemented with printer integration'),
        backgroundColor: AppColors.statusInfo,
      ),
    );
  }

  void _switchMode(String mode) {
    if (_cart.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Switch Mode'),
          content: const Text('You have items in the cart. Clear cart and switch mode?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _cart = [];
                  _currentMode = mode;
                });
                // Update URL to reflect new mode
                context.go('/pos/terminal?mode=$mode');
                _loadData();
              },
              child: const Text('Clear & Switch'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _currentMode = mode;
      });
      // Update URL to reflect new mode
      context.go('/pos/terminal?mode=$mode');
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFf0f0f0),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Top Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: const Color(0xFF333333),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3498db),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'POS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Store Name (POS Selling)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Menu Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFfbbf24), Color(0xFFf59e0b)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFfbbf24).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                _MenuButton(
                  label: 'Exit',
                  onPressed: () => context.go('/pos'),
                  color: Colors.white,
                ),
                _MenuButton(
                  label: 'Logout',
                  onPressed: () {
                    authProvider.signOut();
                    context.go('/login');
                  },
                  color: Colors.red,
                ),
                _MenuButton(
                  label: 'Switch',
                  onPressed: () => _showModeSwitchDialog(),
                  color: Colors.red,
                ),
                if (_currentMode != AppConfig.posModeRestaurant)
                  _MenuButton(
                    label: 'Register',
                    onPressed: () {},
                    color: Colors.white,
                  ),
                if (_currentMode == AppConfig.posModeReservation)
                  _MenuButton(
                    label: 'Reservation',
                    onPressed: () {},
                    color: Colors.white,
                  ),
                if (_currentMode != AppConfig.posModeRestaurant)
                  _MenuButton(
                    label: 'Customer',
                    onPressed: () {},
                    color: Colors.white,
                  ),
                if (_currentMode != AppConfig.posModeRestaurant)
                  _MenuButton(
                    label: 'Credits',
                    onPressed: () {},
                    color: Colors.white,
                  ),
                if (_currentMode != AppConfig.posModeRestaurant)
                  _MenuButton(
                    label: 'Reports',
                    onPressed: () {},
                    color: Colors.white,
                  ),
                if (_currentMode != AppConfig.posModeRestaurant)
                  _MenuButton(
                    label: 'History',
                    onPressed: () {},
                    color: Colors.white,
                  ),
                if (_currentMode == AppConfig.posModeRestaurant)
                  _MenuButton(
                    label: 'Table',
                    onPressed: () {},
                    color: Colors.white,
                  ),
                _MenuButton(
                  label: _currentMode == AppConfig.posModeRestaurant ? 'Kitchen Note' : 'Comment',
                  onPressed: () {},
                  color: Colors.white,
                ),
                _MenuButton(
                  label: 'Help',
                  onPressed: () {},
                  color: Colors.white,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'User: $userName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Panel (65%)
                  Expanded(
                    flex: 65,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFcccccc)),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          // Input Row (hidden in reservation mode)
                          if (_currentMode != AppConfig.posModeReservation) _buildInputRow(),
                          // Order Table
                          Expanded(child: _buildOrderTable()),
                          // Totals Section (includes customer display)
                          _buildTotalsSection(),
                          // Current Bill Status Bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2c3e50),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF16a085),
                                  ),
                                  child: const Text(
                                    'New',
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Current Bill: Selling List',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Right Panel (35%)
                  Expanded(
                    flex: 35,
                    child: Column(
                      children: [
                        Expanded(child: _buildRightPanel()),
                        const SizedBox(height: 5),
                        _buildPaySection(),
                      ],
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

  Widget _buildInputRow() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFf8f9fa), Colors.white],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentMode == AppConfig.posModeRestaurant ? 'GUEST' : 'CUSTOMER',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: '1',
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFe0e0e0), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: '1', child: Text('Walk-in Customer')),
                  ],
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentMode == AppConfig.posModeRestaurant ? 'MENU ITEM' : 'PRODUCT',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: _currentMode == AppConfig.posModeRestaurant ? 'Select Menu Item' : 'Select Product',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFe0e0e0), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QUANTITY',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  initialValue: '1',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFe0e0e0), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Stock List Button
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Open stock list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stock List feature coming soon')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Stock List', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 10),
          // Salesperson Dropdown
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentMode == AppConfig.posModeRestaurant ? 'WAITER' : 'SALESPERSON',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFe0e0e0), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('No Salesmen Found')),
                  ],
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTable() {
    final isReservationMode = _currentMode == AppConfig.posModeReservation;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFe0e0e0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: _buildTableHeaderCell('Description')),
                if (!isReservationMode) Expanded(flex: 2, child: _buildTableHeaderCell('UPC')),
                Expanded(flex: 2, child: _buildTableHeaderCell('Unit Price')),
                if (!isReservationMode) Expanded(flex: 1, child: _buildTableHeaderCell('Qty')),
                if (!isReservationMode) Expanded(flex: 1, child: _buildTableHeaderCell('Disc')),
                Expanded(flex: 2, child: _buildTableHeaderCell('Amount')),
                if (!isReservationMode) Expanded(flex: 1, child: _buildTableHeaderCell('VAT')),
                Expanded(flex: 2, child: _buildTableHeaderCell('Balance Due')),
              ],
            ),
          ),
          // Table Body
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Text(
                      'No items in cart',
                      style: TextStyle(color: Color(0xFF999999)),
                    ),
                  )
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: const Color(0xFFf0f0f0)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  item.productName ?? 'Unknown',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                            if (!isReservationMode)
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text('', style: const TextStyle(fontSize: 13)),
                                ),
                              ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  Formatters.currency(item.price),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                            if (!isReservationMode)
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            if (!isReservationMode)
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    Formatters.currency(item.discountAmount),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  Formatters.currency(item.totalAmount),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                            if (!isReservationMode)
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    '\$0.00',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  Formatters.currency(item.totalAmount),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Container(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          // Totals Left
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2c3e50), Color(0xFF34495e)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalRow('Sub-Total', _subtotal + _discountTotal + _subTotalDiscount),
                  _buildTotalRow('Discount', _discountTotal + _subTotalDiscount),
                  _buildTotalRow('VAT 0%', 0.0),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFf59e0b), Color(0xFFd97706)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Balance Due',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    Formatters.currency(_total),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4ade80),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          // Totals Right (Customer Display - will be filled in _buildCustomerDisplay)
          Expanded(flex: 3, child: _buildCustomerDisplay()),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          Text(
            Formatters.currency(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDisplay() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFf0f0f0),
        border: Border.all(color: const Color(0xFFcccccc)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User',
                      style: TextStyle(fontSize: 10, color: Color(0xFF999999)),
                    ),
                    Text(
                      _currentCustomerName ?? '-',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Balance Due',
                      style: TextStyle(fontSize: 10, color: Color(0xFF999999)),
                    ),
                    Text(
                      Formatters.currency(_total),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2e7d32),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phone',
                      style: TextStyle(fontSize: 10, color: Color(0xFF999999)),
                    ),
                    Text(
                      _currentCustomerPhone ?? '-',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Table No / Address',
                      style: TextStyle(fontSize: 10, color: Color(0xFF999999)),
                    ),
                    Text(
                      _tableNo ?? '-',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(_total),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2e7d32),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Action Buttons Column (140px)
        Container(
          width: 140,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFFf8f9fa), const Color(0xFFe9ecef)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (_currentMode == AppConfig.posModeReservation)
                _ActionButton(
                  label: 'New Reservation',
                  onPressed: () {
                    // TODO: Show new reservation modal
                  },
                  color: Colors.green,
                ),
              _ActionButton(
                label: 'Delete Line',
                onPressed: () {
                  if (_cart.isNotEmpty) {
                    _deleteLine(_cart.length - 1);
                  }
                },
                color: const Color(0xFFff6b6b),
              ),
              _ActionButton(
                label: 'Clear Bill',
                onPressed: _clearCart,
                color: const Color(0xFF4ecdc4),
              ),
              _ActionButton(
                label: 'Line Discount',
                onPressed: _applyLineDiscount,
                color: const Color(0xFF56ab2f),
              ),
              _ActionButton(
                label: _currentMode == AppConfig.posModeRestaurant ? 'Send to Kitchen' : 'Hold Items',
                onPressed: _holdOrder,
                color: const Color(0xFFeb3349),
              ),
              _ActionButton(
                label: 'Sub Total Discount',
                onPressed: _applySubTotalDiscount,
                color: const Color(0xFF667eea),
              ),
              if (_currentMode != AppConfig.posModeRestaurant) ...[
                _ActionButton(
                  label: 'Price Check',
                  onPressed: _showPriceCheck,
                  color: const Color(0xFF3498db),
                ),
                _ActionButton(
                  label: 'Quotation',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Quotation feature coming soon'),
                        backgroundColor: AppColors.statusInfo,
                      ),
                    );
                  },
                  color: const Color(0xFFf1c40f),
                ),
              ],
              _ActionButton(
                label: 'Checkout',
                onPressed: _checkout,
                color: const Color(0xFF2c3e50),
              ),
              _ActionButton(
                label: _currentMode == AppConfig.posModeRestaurant ? 'Kitchen Note' : 'Order Note',
                onPressed: _showOrderNote,
                color: const Color(0xFF95a5a6),
              ),
              _ActionButton(
                label: 'Print Hold Bill',
                onPressed: _printHoldBill,
                color: const Color(0xFFe74c3c),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Product/Reservation Grid Area
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Category Tabs (not in reservation mode)
                if (_currentMode != AppConfig.posModeReservation) _buildCategoryTabs(),
                // View Type Buttons (for all modes)
                _buildViewTypeButtons(),
                // Product/Reservation Grid
                Expanded(child: _buildProductGrid()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFfbbf24), Color(0xFFf59e0b), Color(0xFFd97706)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _CategoryTab(
              label: _currentMode == AppConfig.posModeRestaurant ? 'All Products' : 'All Products',
              count: _products.length,
              isSelected: _selectedCategoryId == 'all',
              onTap: () => _filterByCategory('all'),
            ),
            ..._categories.map((cat) {
              final categoryId = cat['id'].toString();
              final count = _getCategoryCount(categoryId);
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _CategoryTab(
                  label: cat['name'] ?? 'Unknown',
                  count: count,
                  isSelected: _selectedCategoryId == categoryId,
                  onTap: () => _filterByCategory(categoryId),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildViewTypeButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _currentMode == AppConfig.posModeReservation ? 'Reservations' : 'All Products',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF666)),
          ),
          Row(
            children: [
          _ViewTypeButton(
            icon: Icons.grid_view,
            label: 'Detailed',
            isSelected: _viewType == 'grid',
            onTap: () => setState(() => _viewType = 'grid'),
          ),
          const SizedBox(width: 5),
          _ViewTypeButton(
            icon: Icons.view_list,
            label: 'List',
            isSelected: _viewType == 'list',
            onTap: () => setState(() => _viewType = 'list'),
          ),
          const SizedBox(width: 5),
          _ViewTypeButton(
            icon: Icons.view_module,
            label: 'Compact',
            isSelected: _viewType == 'compact',
            onTap: () => setState(() => _viewType = 'compact'),
          ),
          const SizedBox(width: 5),
          _ViewTypeButton(
            icon: Icons.view_agenda,
            label: 'Summary',
            isSelected: _viewType == 'summary',
            onTap: () => setState(() => _viewType = 'summary'),
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_currentMode == AppConfig.posModeReservation) {
      return _buildReservationsGrid();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredProducts = _filteredProducts;
    
    if (filteredProducts.isEmpty) {
      return const Center(child: Text('No products found'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _ProductCard(
          product: product,
          onTap: () => _addToCart(product),
        );
      },
    );
  }

  Widget _buildReservationsGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Color(0xFF999999)),
            const SizedBox(height: 16),
            const Text(
              'No Reservations Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF666)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Reservations with balance due will appear here',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    switch (_viewType) {
      case 'list':
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _reservations.length,
          itemBuilder: (context, index) {
            final reservation = _reservations[index];
            return _ReservationListCard(
              reservation: reservation,
              isSelected: _selectedReservation?.reservationId == reservation.reservationId,
              onTap: () => _selectReservation(reservation),
            );
          },
        );
      case 'compact':
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _reservations.length,
          itemBuilder: (context, index) {
            final reservation = _reservations[index];
            return _ReservationCompactCard(
              reservation: reservation,
              isSelected: _selectedReservation?.reservationId == reservation.reservationId,
              onTap: () => _selectReservation(reservation),
            );
          },
        );
      case 'summary':
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _reservations.length,
          itemBuilder: (context, index) {
            final reservation = _reservations[index];
            return _ReservationSummaryCard(
              reservation: reservation,
              isSelected: _selectedReservation?.reservationId == reservation.reservationId,
              onTap: () => _selectReservation(reservation),
            );
          },
        );
      default: // grid (detailed)
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _reservations.length,
          itemBuilder: (context, index) {
            final reservation = _reservations[index];
            return _ReservationDetailedCard(
              reservation: reservation,
              isSelected: _selectedReservation?.reservationId == reservation.reservationId,
              onTap: () => _selectReservation(reservation),
            );
          },
        );
    }
  }

  Widget _buildPaySection() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFe74c3c), Color(0xFFc0392b)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFe74c3c).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _checkout,
          borderRadius: BorderRadius.circular(8),
          child: const Center(
            child: Text(
              'PAY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showModeSwitchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select POS Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_bag, color: Color(0xFF3498db)),
              title: const Text('Retail'),
              subtitle: const Text('Standard sales & inventory'),
              onTap: () {
                Navigator.pop(context);
                _switchMode(AppConfig.posModeRetail);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant, color: Color(0xFF27ae60)),
              title: const Text('Restaurant'),
              subtitle: const Text('Tables & food service'),
              onTap: () {
                Navigator.pop(context);
                _switchMode(AppConfig.posModeRestaurant);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event, color: Color(0xFFf39c12)),
              title: const Text('Reservation'),
              subtitle: const Text('Hotel & table bookings'),
              onTap: () {
                Navigator.pop(context);
                _switchMode(AppConfig.posModeReservation);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Menu Button Widget
class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _MenuButton({
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: color == Colors.red
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFe74c3c), Color(0xFFc0392b)],
                  ).colors.first
                : color == Colors.green
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2ecc71), Color(0xFF27ae60)],
                      ).colors.first
                    : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// Action Button Widget
class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// View Type Button Widget
class _ViewTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewTypeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF667eea) : const Color(0xFFf0f0f0),
            border: Border.all(
              color: isSelected ? const Color(0xFF667eea) : const Color(0xFFcccccc),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : const Color(0xFF666666),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Category Tab Widget
class _CategoryTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.25),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF667eea) : Colors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ).colors.first
                      : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Product Card Widget
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product.imageUrl != null
                      ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.image_outlined, size: 48, color: AppColors.textLight),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.currency(product.price),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reservation Detailed Card Widget
class _ReservationDetailedCard extends StatelessWidget {
  final ReservationModel reservation;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReservationDetailedCard({
    required this.reservation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (reservation.status) {
      case 'reserved':
        statusColor = AppColors.secondaryOrange;
        break;
      case 'checked_in':
        statusColor = AppColors.roomOccupied;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    final balanceDue = reservation.balanceDue ?? reservation.totalPrice ?? 0.0;

    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF3498db) : Colors.transparent,
          width: isSelected ? 3 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    reservation.reservationNumber ?? reservation.roomNumber ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      reservation.status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (reservation.guestName != null) ...[
                Text(
                  reservation.guestName!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (reservation.guestPhone != null)
                Text(
                  Formatters.phone(reservation.guestPhone!),
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check-in: ${Formatters.date(reservation.checkInDate)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          'Check-out: ${Formatters.date(reservation.checkOutDate)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${reservation.calculatedNights} nights',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Price:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(
                          Formatters.currency(reservation.totalPrice ?? 0.0),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (balanceDue > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Balance Due:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.statusError),
                          ),
                          Text(
                            Formatters.currency(balanceDue),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.statusError),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reservation List Card Widget
class _ReservationListCard extends StatelessWidget {
  final ReservationModel reservation;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReservationListCard({
    required this.reservation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (reservation.status) {
      case 'reserved':
        statusColor = AppColors.secondaryOrange;
        break;
      case 'checked_in':
        statusColor = AppColors.roomOccupied;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    final balanceDue = reservation.balanceDue ?? reservation.totalPrice ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF3498db) : Colors.transparent,
          width: isSelected ? 3 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            Container(
              width: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [statusColor, statusColor.withOpacity(0.8)],
                ),
              ),
              child: const Icon(Icons.bed, size: 36, color: Colors.white),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                reservation.reservationNumber ?? 'N/A',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 15),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  reservation.status.toUpperCase(),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: Color(0xFF3498db)),
                              const SizedBox(width: 6),
                              Text(reservation.guestName ?? 'Unknown', style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 20),
                              const Icon(Icons.meeting_room, size: 16, color: Color(0xFF3498db)),
                              const SizedBox(width: 6),
                              Text('Room ${reservation.roomNumber ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 20),
                              const Icon(Icons.bedtime, size: 16, color: Color(0xFF3498db)),
                              const SizedBox(width: 6),
                              Text('${reservation.calculatedNights} nights', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.currency(balanceDue),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: balanceDue > 0 ? const Color(0xFFe74c3c) : const Color(0xFF27ae60),
                          ),
                        ),
                        const Text('Balance Due', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reservation Compact Card Widget
class _ReservationCompactCard extends StatelessWidget {
  final ReservationModel reservation;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReservationCompactCard({
    required this.reservation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (reservation.status) {
      case 'reserved':
        statusColor = AppColors.secondaryOrange;
        break;
      case 'checked_in':
        statusColor = AppColors.roomOccupied;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    final balanceDue = reservation.balanceDue ?? reservation.totalPrice ?? 0.0;

    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF3498db) : Colors.transparent,
          width: isSelected ? 3 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [statusColor, statusColor.withOpacity(0.8)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reservation.reservationNumber ?? 'N/A',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Room ${reservation.roomNumber ?? 'N/A'}',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reservation.guestName ?? 'Unknown',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${Formatters.date(reservation.checkInDate)}\n${Formatters.date(reservation.checkOutDate)}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Due:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      Text(
                        Formatters.currency(balanceDue),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: balanceDue > 0 ? const Color(0xFFe74c3c) : const Color(0xFF27ae60),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reservation Summary Card Widget
class _ReservationSummaryCard extends StatelessWidget {
  final ReservationModel reservation;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReservationSummaryCard({
    required this.reservation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (reservation.status) {
      case 'reserved':
        statusColor = AppColors.secondaryOrange;
        break;
      case 'checked_in':
        statusColor = AppColors.roomOccupied;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    final balanceDue = reservation.balanceDue ?? reservation.totalPrice ?? 0.0;

    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF3498db) : Colors.transparent,
          width: isSelected ? 3 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [statusColor, statusColor.withOpacity(0.8)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.reservationNumber ?? 'N/A',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          reservation.guestName ?? 'Unknown',
                          style: const TextStyle(fontSize: 10, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      Formatters.currency(balanceDue),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Room ${reservation.roomNumber ?? 'N/A'}', style: const TextStyle(fontSize: 11)),
                      Text('${reservation.calculatedNights}n', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${Formatters.date(reservation.checkInDate)}\n${Formatters.date(reservation.checkOutDate)}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Due:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      Text(
                        Formatters.currency(balanceDue),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: balanceDue > 0 ? const Color(0xFFe74c3c) : const Color(0xFF27ae60),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Payment Dialog
class _PaymentDialog extends StatefulWidget {
  final double total;

  const _PaymentDialog({required this.total});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  String _paymentMethod = 'cash';
  TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Process Payment'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total: ${Formatters.currency(widget.total)}', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                DropdownMenuItem(value: 'debit_card', child: Text('Debit Card')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
              ],
              onChanged: (value) => setState(() => _paymentMethod = value ?? 'cash'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount Paid',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'payment_method': _paymentMethod,
                'amount_paid': double.parse(_amountController.text),
              });
            }
          },
          child: const Text('Process Payment'),
        ),
      ],
    );
  }
}

// Receipt Dialog
class _ReceiptDialog extends StatelessWidget {
  final OrderModel order;
  final String customerName;
  final double? amountPaid;
  final String? reservationNumber;

  const _ReceiptDialog({
    required this.order,
    required this.customerName,
    this.amountPaid,
    this.reservationNumber,
  });

  @override
  Widget build(BuildContext context) {
    final change = (amountPaid ?? order.total) - order.total;
    final paymentMethodName = order.paymentMethod
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'RECEIPT',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.dateTime(order.createdAt ?? DateTime.now()),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  if (order.billNumber != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Bill #: ${order.billNumber}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  if (reservationNumber != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reservation #: $reservationNumber',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Receipt Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Info
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.isRestaurantMode ? 'GUEST:' : 'CUSTOMER:',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            customerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (order.tableNo != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Table: ${order.tableNo}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                          if (order.waiterName != null) ...[
                            Text(
                              'Waiter: ${order.waiterName}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Items
                    const Text(
                      'ITEMS:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...order.items!.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName ?? 'Item',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (item.quantity > 1)
                                  Text(
                                    'Qty: ${item.quantity} × ${Formatters.currency(item.price)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (item.discountAmount > 0)
                            Expanded(
                              child: Text(
                                '-${Formatters.currency(item.discountAmount)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.statusError,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              Formatters.currency(item.totalAmount),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Totals
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                        Text(
                          Formatters.currency(order.subtotal),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    if (order.discountTotal > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Discount:',
                            style: TextStyle(fontSize: 14, color: AppColors.statusError),
                          ),
                          Text(
                            '-${Formatters.currency(order.discountTotal)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.statusError,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          Formatters.currency(order.total),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment (${paymentMethodName}):',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          Formatters.currency(amountPaid ?? order.total),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    if (change > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Change:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            Formatters.currency(change),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (order.comment != null && order.comment!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Note: ${order.comment}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Thank you for your business!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Print receipt
                      html.window.print();
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Line Discount Dialog
class _LineDiscountDialog extends StatefulWidget {
  final List<OrderItemModel> cart;
  final Function(int index, double discountAmount) onDiscountApplied;

  const _LineDiscountDialog({
    required this.cart,
    required this.onDiscountApplied,
  });

  @override
  State<_LineDiscountDialog> createState() => _LineDiscountDialogState();
}

class _LineDiscountDialogState extends State<_LineDiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedItemIndex;
  TextEditingController _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.cart.isNotEmpty) {
      _selectedItemIndex = 0;
      _discountController.text = widget.cart[0].discountAmount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Apply Line Discount'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _selectedItemIndex,
              decoration: const InputDecoration(
                labelText: 'Select Item',
                border: OutlineInputBorder(),
              ),
              items: widget.cart.asMap().entries.map((entry) {
                int idx = entry.key;
                OrderItemModel item = entry.value;
                return DropdownMenuItem<int>(
                  value: idx,
                  child: Text('${item.productName} (${Formatters.currency(item.price * item.quantity)})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedItemIndex = value;
                  if (value != null) {
                    _discountController.text = widget.cart[value].discountAmount.toStringAsFixed(2);
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _discountController,
              decoration: const InputDecoration(
                labelText: 'Discount Amount (\$)',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter discount amount';
                }
                final discount = double.tryParse(value);
                if (discount == null || discount < 0) {
                  return 'Enter a valid discount';
                }
                if (_selectedItemIndex != null) {
                  final item = widget.cart[_selectedItemIndex!];
                  if (discount > (item.price * item.quantity)) {
                    return 'Discount cannot exceed item total';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _selectedItemIndex != null) {
              final discount = double.parse(_discountController.text);
              widget.onDiscountApplied(_selectedItemIndex!, discount);
              Navigator.pop(context);
            }
          },
          child: const Text('Apply Discount'),
        ),
      ],
    );
  }
}

// Sub Total Discount Dialog
class _SubTotalDiscountDialog extends StatefulWidget {
  final double subtotal;
  final double currentDiscount;
  final Function(double discountAmount) onDiscountApplied;

  const _SubTotalDiscountDialog({
    required this.subtotal,
    required this.currentDiscount,
    required this.onDiscountApplied,
  });

  @override
  State<_SubTotalDiscountDialog> createState() => _SubTotalDiscountDialogState();
}

class _SubTotalDiscountDialogState extends State<_SubTotalDiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _discountController.text = widget.currentDiscount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Apply Sub Total Discount'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Subtotal: ${Formatters.currency(widget.subtotal)}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _discountController,
              decoration: const InputDecoration(
                labelText: 'Discount Amount (\$)',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter discount amount';
                }
                final discount = double.tryParse(value);
                if (discount == null || discount < 0) {
                  return 'Enter a valid discount';
                }
                if (discount > widget.subtotal) {
                  return 'Discount cannot exceed subtotal';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final discount = double.parse(_discountController.text);
              widget.onDiscountApplied(discount);
              Navigator.pop(context);
            }
          },
          child: const Text('Apply Discount'),
        ),
      ],
    );
  }
}

// Price Check Dialog
class _PriceCheckDialog extends StatefulWidget {
  final List<ProductModel> products;

  const _PriceCheckDialog({required this.products});

  @override
  State<_PriceCheckDialog> createState() => _PriceCheckDialogState();
}

class _PriceCheckDialogState extends State<_PriceCheckDialog> {
  TextEditingController _searchController = TextEditingController();
  List<ProductModel> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = widget.products
          .where((product) =>
              product.name.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Price Check'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Product',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return ListTile(
                    title: Text(product.name),
                    trailing: Text(Formatters.currency(product.price)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
