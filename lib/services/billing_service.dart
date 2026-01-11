/// Billing Service
/// 
/// Handles billing and payment operations with offline support

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/billing_model.dart';
import 'api_service.dart';
import 'offline_storage_service.dart';
import '../config/api_config.dart';

class BillingService extends ApiService {
  Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get all invoices (with offline support)
  Future<List<BillingModel>> getInvoices({Map<String, dynamic>? filters}) async {
    try {
      if (await _isOnline()) {
        try {
          final response = await get(
            '${ApiConfig.billingEndpoint}read.php',
            queryParameters: filters,
          );
          
          List<BillingModel> billings = [];
          if (response.data is List) {
            billings = BillingModel.fromJsonList(response.data as List);
          } else if (response.data is Map && response.data['data'] != null) {
            billings = BillingModel.fromJsonList(response.data['data'] as List);
          }
          
          if (billings.isNotEmpty) {
            await OfflineStorageService.saveBillings(billings);
            await OfflineStorageService.saveLastSync('billings', DateTime.now());
          }
          
          return billings;
        } catch (e) {
          debugPrint('API fetch failed, using local storage: $e');
        }
      }
      
      return OfflineStorageService.getBillings();
    } catch (e) {
      return OfflineStorageService.getBillings();
    }
  }

  /// Get invoice by ID (with offline support)
  Future<BillingModel?> getInvoiceById(int billingId) async {
    try {
      if (await _isOnline()) {
        try {
          final response = await get(
            '${ApiConfig.billingEndpoint}read.php',
            queryParameters: {'billing_id': billingId},
          );
          
          BillingModel? invoice;
          if (response.data is List && (response.data as List).isNotEmpty) {
            invoice = BillingModel.fromJson(response.data[0] as Map<String, dynamic>);
          } else if (response.data is Map && response.data['data'] != null) {
            invoice = BillingModel.fromJson(response.data['data'] as Map<String, dynamic>);
          } else if (response.data is Map && response.data['billing_id'] != null) {
            invoice = BillingModel.fromJson(response.data as Map<String, dynamic>);
          }
          
          if (invoice != null) {
            await OfflineStorageService.saveBilling(invoice);
          }
          
          return invoice;
        } catch (e) {
          debugPrint('API fetch failed, using local storage: $e');
        }
      }
      
      // Try to find in local storage
      final allBillings = OfflineStorageService.getBillings();
      try {
        return allBillings.firstWhere((b) => b.billingId == billingId);
      } catch (e) {
        return null;
      }
    } catch (e) {
      // Final fallback to local storage
      try {
        final allBillings = OfflineStorageService.getBillings();
        return allBillings.firstWhere((b) => b.billingId == billingId);
      } catch (e2) {
        return null;
      }
    }
  }

  /// Create invoice (with offline support)
  Future<BillingModel> createInvoice(BillingModel invoice) async {
    try {
      if (await _isOnline()) {
        try {
          final response = await post(
            '${ApiConfig.billingEndpoint}create.php',
            data: invoice.toJson(),
          );
          
          if (response.data is Map && response.data['success'] == true) {
            final data = response.data['data'] as Map<String, dynamic>? ?? response.data;
            final createdInvoice = BillingModel.fromJson(data);
            await OfflineStorageService.saveBilling(createdInvoice);
            return createdInvoice;
          }
          throw Exception('Invalid response format');
        } catch (e) {
          debugPrint('API create failed, adding to sync queue: $e');
        }
      }
      
      // Offline mode: save locally and queue
      final tempId = invoice.billingId != null && invoice.billingId! < 0
          ? invoice.billingId
          : -(DateTime.now().millisecondsSinceEpoch);
      final tempInvoice = invoice.copyWith(billingId: tempId);
      
      await OfflineStorageService.saveBilling(tempInvoice);
      await OfflineStorageService.addToSyncQueue(
        operation: 'create',
        entityType: 'billing',
        data: tempInvoice.toJson(),
        entityId: tempInvoice.billingId?.toString(),
      );
      
      return tempInvoice;
    } catch (e) {
      throw Exception('Failed to create invoice: $e');
    }
  }

  /// Process payment
  Future<bool> processPayment(int billingId, Map<String, dynamic> paymentData) async {
    try {
      final response = await post(
        '${ApiConfig.billingEndpoint}process-payment.php',
        data: {
          'billing_id': billingId,
          ...paymentData,
        },
      );
      
      return response.data['success'] == true || response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  /// Update invoice (with offline support)
  Future<BillingModel> updateInvoice(BillingModel invoice) async {
    try {
      if (await _isOnline()) {
        try {
          final response = await put(
            '${ApiConfig.billingEndpoint}update.php',
            data: invoice.toJson(),
          );
          
          if (response.data is Map) {
            final updatedInvoice = BillingModel.fromJson(response.data as Map<String, dynamic>);
            await OfflineStorageService.saveBilling(updatedInvoice);
            return updatedInvoice;
          }
          throw Exception('Invalid response format');
        } catch (e) {
          debugPrint('API update failed, adding to sync queue: $e');
        }
      }
      
      // Offline mode: update locally and queue
      await OfflineStorageService.saveBilling(invoice);
      await OfflineStorageService.addToSyncQueue(
        operation: 'update',
        entityType: 'billing',
        data: invoice.toJson(),
        entityId: invoice.billingId?.toString(),
      );
      
      return invoice;
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
    }
  }
}

