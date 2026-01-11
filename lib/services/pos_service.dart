/// POS Service
/// 
/// Handles POS operations for retail, restaurant, and reservation modes with offline support

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import 'api_service.dart';
import 'offline_storage_service.dart';
import 'product_service.dart';
import 'category_service.dart';
import '../config/api_config.dart';

class POSService extends ApiService {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get products for retail mode (using Firestore)
  Future<List<ProductModel>> getRetailProducts({int? categoryId}) async {
    try {
      final products = await _productService.getProducts(categoryId: categoryId);
      
      // Also save to offline storage for offline support
      if (products.isNotEmpty) {
        await OfflineStorageService.saveProducts(products);
      }
      
      return products;
    } catch (e) {
      debugPrint('Firestore fetch failed, using local storage: $e');
      // Fallback to local storage
      final allProducts = OfflineStorageService.getProducts();
      if (categoryId != null) {
        return allProducts.where((p) => p.categoryId == categoryId).toList();
      }
      return allProducts;
    }
  }

  /// Get restaurant menu items (with offline support)
  Future<List<ProductModel>> getRestaurantMenuItems({int? categoryId}) async {
    try {
      if (await _isOnline()) {
        try {
          final response = await get(
            '${ApiConfig.restaurantEndpoint}get-menu.php',
            queryParameters: categoryId != null ? {'category_id': categoryId} : null,
          );
          
          List<ProductModel> items = [];
          if (response.data is Map && response.data['success'] == true) {
            if (response.data['items'] != null) {
              items = ProductModel.fromJsonList(response.data['items'] as List);
            } else if (response.data['menu'] != null) {
              items = ProductModel.fromJsonList(response.data['menu'] as List);
            } else if (response.data['data'] != null) {
              items = ProductModel.fromJsonList(response.data['data'] as List);
            }
          } else if (response.data is List) {
            items = ProductModel.fromJsonList(response.data as List);
          }
          
          if (items.isNotEmpty) {
            await OfflineStorageService.saveProducts(items);
          }
          
          return items;
        } catch (e) {
          debugPrint('API fetch failed, using local storage: $e');
        }
      }
      
      // Filter by category if needed (local storage)
      final allProducts = OfflineStorageService.getProducts();
      if (categoryId != null) {
        return allProducts.where((p) => p.categoryId == categoryId).toList();
      }
      return allProducts;
    } catch (e) {
      return OfflineStorageService.getProducts();
    }
  }

  /// Get categories (using Firestore)
  Future<List<Map<String, dynamic>>> getCategories({String? mode}) async {
    try {
      final categories = await _categoryService.getCategories();
      
      // Also save to offline storage for offline support
      if (categories.isNotEmpty) {
        await OfflineStorageService.saveCategories(categories, mode: mode);
      }
      
      return categories;
    } catch (e) {
      debugPrint('Firestore fetch failed, using local storage: $e');
      // Fallback to local storage
      return OfflineStorageService.getCategories(mode: mode);
    }
  }

  /// Save order (with offline support)
  Future<bool> saveOrder(OrderModel order) async {
    try {
      final orderData = {
        'customer_id': order.customerId ?? 1,
        'salesperson_id': order.salespersonId ?? 1,
        'subtotal': order.subtotal,
        'discount_total': order.discountTotal,
        'service_charge': order.serviceCharge,
        'tip_amount': order.tipAmount,
        'tax': order.tax,
        'total': order.total,
        'status': order.status,
        'payment_method': order.paymentMethod,
        'business_mode': order.businessMode,
        'station_id': order.stationId ?? 1,
        if (order.waiterName != null && order.waiterName!.isNotEmpty) 'waiter_name': order.waiterName,
        if (order.tableNo != null && order.tableNo!.isNotEmpty) 'table_no': order.tableNo,
        if (order.comment != null && order.comment!.isNotEmpty) 'comment': order.comment,
        'items': order.items?.map((item) {
              final itemMap = <String, dynamic>{
                'name': item.productName ?? 'Unknown',
                'qty': item.quantity,
                'price': item.price,
                'discount': item.discountAmount,
                'amount': item.totalAmount,
              };
              
              if (item.isRestaurantItem && item.menuId != null) {
                itemMap['id'] = 'restaurant_${item.menuId}';
                itemMap['menu_id'] = item.menuId;
              } else if (item.productId != null) {
                itemMap['id'] = item.productId.toString();
              } else {
                itemMap['id'] = item.productName ?? 'unknown';
              }
              
              if (item.isRestaurantItem) {
                itemMap['isRestaurantItem'] = true;
              }
              if (item.isReservation) {
                itemMap['isReservation'] = true;
              }
              
              return itemMap;
            }).toList() ?? [],
      };

      if (await _isOnline()) {
        try {
          final response = await post(
            '${ApiConfig.posEndpoint}save_order.php',
            data: orderData,
          );
          
          final success = response.data['success'] == true || response.statusCode == 200;
          if (success && order.id != null) {
            await OfflineStorageService.saveOrder(order);
          }
          return success;
        } catch (e) {
          debugPrint('API save failed, adding to sync queue: $e');
        }
      }
      
      // Offline mode: save locally and queue
      final tempId = order.id != null && order.id! < 0
          ? order.id
          : -(DateTime.now().millisecondsSinceEpoch);
      final tempOrder = order.copyWith(id: tempId);
      
      await OfflineStorageService.saveOrder(tempOrder);
      await OfflineStorageService.addToSyncQueue(
        operation: 'create',
        entityType: 'order',
        data: tempOrder.toJson(),
        entityId: tempOrder.id?.toString(),
      );
      
      return true;
    } catch (e) {
      throw Exception('Failed to save order: $e');
    }
  }

  /// Get hold bills (with offline support)
  Future<List<OrderModel>> getHoldBills() async {
    try {
      if (await _isOnline()) {
        try {
          final response = await get('${ApiConfig.posEndpoint}get_hold_bills.php');
          
          List<OrderModel> holdBills = [];
          if (response.data is List) {
            holdBills = OrderModel.fromJsonList(response.data as List);
          } else if (response.data is Map && response.data['data'] != null) {
            holdBills = OrderModel.fromJsonList(response.data['data'] as List);
          } else if (response.data is Map && response.data['success'] == true) {
            if (response.data['bills'] != null) {
              holdBills = OrderModel.fromJsonList(response.data['bills'] as List);
            } else if (response.data['orders'] != null) {
              holdBills = OrderModel.fromJsonList(response.data['orders'] as List);
            }
          }
          
          if (holdBills.isNotEmpty) {
            await OfflineStorageService.saveOrders(holdBills);
          }
          
          return holdBills;
        } catch (e) {
          debugPrint('API fetch failed, using local storage: $e');
        }
      }
      
      // Offline mode: return hold bills from local storage
      return OfflineStorageService.getHoldBills();
    } catch (e) {
      return OfflineStorageService.getHoldBills();
    }
  }

  /// Get hold bill by ID (with offline support)
  Future<OrderModel?> getHoldBill(int billId) async {
    try {
      if (await _isOnline()) {
        try {
          final response = await get(
            '${ApiConfig.posEndpoint}get_hold_bill.php',
            queryParameters: {'bill_id': billId},
          );
          
          OrderModel? order;
          if (response.data is Map && response.data['success'] == true) {
            if (response.data['bill'] != null) {
              order = OrderModel.fromJson(response.data['bill'] as Map<String, dynamic>);
            } else if (response.data['order'] != null) {
              order = OrderModel.fromJson(response.data['order'] as Map<String, dynamic>);
            } else if (response.data['data'] != null) {
              order = OrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
            }
          } else if (response.data is Map && response.data['id'] != null) {
            order = OrderModel.fromJson(response.data as Map<String, dynamic>);
          }
          
          if (order != null) {
            await OfflineStorageService.saveOrder(order);
          }
          
          return order;
        } catch (e) {
          debugPrint('API fetch failed, using local storage: $e');
        }
      }
      
      // Try to find in local storage
      return OfflineStorageService.getOrderById(billId);
    } catch (e) {
      // Final fallback to local storage
      return OfflineStorageService.getOrderById(billId);
    }
  }
}

