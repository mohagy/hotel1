/// Print Helper Web Implementation
/// 
/// Web-specific implementation for thermal receipt printing with barcode

import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../core/utils/formatters.dart';

void printDocument() {
  html.window.print();
}

/// Print thermal receipt with barcode
/// Optimized for 80mm thermal printers
void printThermalReceipt({
  required OrderModel order,
  required String customerName,
  double? amountPaid,
  String? reservationNumber,
  String? storeName,
  String? storeAddress,
  String? storePhone,
}) {
  try {
    // Generate barcode data (use order ID or bill number)
    final barcodeData = order.billNumber ?? 
                        order.id?.toString() ?? 
                        DateTime.now().millisecondsSinceEpoch.toString();
    
    // Generate receipt HTML
    final receiptHtml = _generateReceiptHTML(
      order: order,
      customerName: customerName,
      amountPaid: amountPaid,
      reservationNumber: reservationNumber,
      barcodeData: barcodeData,
      storeName: storeName ?? 'Hotel Management',
      storeAddress: storeAddress ?? '',
      storePhone: storePhone ?? '',
    );
    
    // Create a new window for printing using Blob URL
    final blob = html.Blob([receiptHtml], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final printWindow = html.window.open(url, '_blank');
    
    if (printWindow != null) {
      // Wait for window to load, then print
      // Use Future.delayed to wait for the barcode library to load
      Future.delayed(const Duration(milliseconds: 1500), () {
        try {
          // Cast to Window to access print method
          final window = printWindow as html.Window;
          window.print();
        } catch (e) {
          debugPrint('Print error: $e');
        }
        // Clean up the blob URL after printing
        Future.delayed(const Duration(milliseconds: 100), () {
          html.Url.revokeObjectUrl(url);
          // Optionally close the window after a delay
          try {
            (printWindow as html.Window).close();
          } catch (e) {
            debugPrint('Close window error: $e');
          }
        });
      });
    }
  } catch (e) {
    print('Print error: $e');
    // Fallback to regular print
    html.window.print();
  }
}

String _generateReceiptHTML({
  required OrderModel order,
  required String customerName,
  double? amountPaid,
  String? reservationNumber,
  required String barcodeData,
  required String storeName,
  required String storeAddress,
  required String storePhone,
}) {
  final change = (amountPaid ?? order.total) - order.total;
  final paymentMethodName = order.paymentMethod
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
  
  final dateTime = order.createdAt ?? DateTime.now();
  final dateStr = Formatters.date(dateTime);
  final timeStr = Formatters.time(dateTime);
  
  // Build items HTML
  final itemsHtml = StringBuffer();
  if (order.items != null) {
    for (var item in order.items!) {
      final itemName = _truncateText(item.productName ?? 'Item', 20);
      final qty = item.quantity;
      final price = item.price;
      final total = item.totalAmount;
      final discount = item.discountAmount;
      
      if (qty > 1) {
        itemsHtml.writeln('''
          <div class="item-row">
            <div class="item-name">$itemName</div>
            <div class="item-qty">${qty}x ${Formatters.currency(price)}</div>
            ${discount > 0 ? '<div class="item-discount">-${Formatters.currency(discount)}</div>' : ''}
            <div class="item-total">${Formatters.currency(total)}</div>
          </div>
        ''');
      } else {
        itemsHtml.writeln('''
          <div class="item-row">
            <div class="item-name">$itemName</div>
            ${discount > 0 ? '<div class="item-discount">-${Formatters.currency(discount)}</div>' : ''}
            <div class="item-total">${Formatters.currency(total)}</div>
          </div>
        ''');
      }
    }
  }
  
  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Receipt</title>
  <script src="https://cdn.jsdelivr.net/npm/jsbarcode@3.11.5/dist/JsBarcode.all.min.js"></script>
  <style>
    @media print {
      @page {
        size: 80mm auto;
        margin: 0;
      }
      body {
        margin: 0;
        padding: 10mm 5mm;
      }
    }
    
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: 'Courier New', monospace;
      font-size: 12px;
      line-height: 1.4;
      width: 80mm;
      max-width: 80mm;
      margin: 0 auto;
      padding: 10mm 5mm;
      background: white;
      color: black;
    }
    
    .receipt {
      width: 100%;
    }
    
    .header {
      text-align: center;
      margin-bottom: 15px;
      border-bottom: 1px dashed #000;
      padding-bottom: 10px;
    }
    
    .store-name {
      font-size: 18px;
      font-weight: bold;
      margin-bottom: 5px;
      text-transform: uppercase;
    }
    
    .store-info {
      font-size: 10px;
      margin: 2px 0;
    }
    
    .receipt-title {
      font-size: 16px;
      font-weight: bold;
      margin: 10px 0;
      text-align: center;
      text-transform: uppercase;
    }
    
    .receipt-info {
      margin: 8px 0;
      font-size: 11px;
    }
    
    .receipt-info-row {
      display: flex;
      justify-content: space-between;
      margin: 3px 0;
    }
    
    .divider {
      border-top: 1px dashed #000;
      margin: 10px 0;
    }
    
    .section-title {
      font-weight: bold;
      font-size: 11px;
      margin: 8px 0 5px 0;
      text-transform: uppercase;
    }
    
    .item-row {
      display: flex;
      justify-content: space-between;
      margin: 5px 0;
      font-size: 11px;
    }
    
    .item-name {
      flex: 1;
      text-align: left;
    }
    
    .item-qty {
      font-size: 10px;
      color: #666;
      margin-left: 5px;
    }
    
    .item-discount {
      color: #d32f2f;
      font-size: 10px;
      margin-left: 5px;
    }
    
    .item-total {
      text-align: right;
      font-weight: bold;
      min-width: 60px;
    }
    
    .totals {
      margin: 10px 0;
    }
    
    .total-row {
      display: flex;
      justify-content: space-between;
      margin: 5px 0;
      font-size: 12px;
    }
    
    .total-label {
      font-weight: bold;
    }
    
    .total-amount {
      font-weight: bold;
      font-size: 14px;
    }
    
    .grand-total {
      border-top: 2px solid #000;
      border-bottom: 2px solid #000;
      padding: 8px 0;
      margin: 10px 0;
    }
    
    .grand-total .total-label {
      font-size: 16px;
    }
    
    .grand-total .total-amount {
      font-size: 18px;
    }
    
    .payment-info {
      margin: 10px 0;
      font-size: 11px;
    }
    
    .barcode-container {
      text-align: center;
      margin: 15px 0;
      padding: 10px 0;
      border-top: 1px dashed #000;
      border-bottom: 1px dashed #000;
    }
    
    .barcode {
      margin: 10px auto;
    }
    
    .barcode-number {
      font-size: 12px;
      font-weight: bold;
      margin-top: 5px;
      letter-spacing: 2px;
    }
    
    .footer {
      text-align: center;
      margin-top: 15px;
      padding-top: 10px;
      border-top: 1px dashed #000;
      font-size: 10px;
    }
    
    .thank-you {
      font-size: 12px;
      font-weight: bold;
      margin: 10px 0;
      text-align: center;
    }
    
    .note {
      font-size: 10px;
      font-style: italic;
      margin: 8px 0;
      color: #666;
    }
  </style>
</head>
<body>
  <div class="receipt">
    <!-- Store Header -->
    <div class="header">
      <div class="store-name">$storeName</div>
      ${storeAddress.isNotEmpty ? '<div class="store-info">$storeAddress</div>' : ''}
      ${storePhone.isNotEmpty ? '<div class="store-info">Tel: $storePhone</div>' : ''}
    </div>
    
    <!-- Receipt Title -->
    <div class="receipt-title">Receipt</div>
    
    <!-- Receipt Info -->
    <div class="receipt-info">
      <div class="receipt-info-row">
        <span>Date:</span>
        <span>$dateStr</span>
      </div>
      <div class="receipt-info-row">
        <span>Time:</span>
        <span>$timeStr</span>
      </div>
      ${order.billNumber != null ? '''
      <div class="receipt-info-row">
        <span>Bill #:</span>
        <span>${order.billNumber}</span>
      </div>
      ''' : ''}
      ${reservationNumber != null ? '''
      <div class="receipt-info-row">
        <span>Reservation #:</span>
        <span>$reservationNumber</span>
      </div>
      ''' : ''}
    </div>
    
    <div class="divider"></div>
    
    <!-- Customer Info -->
    <div class="section-title">${order.isRestaurantMode ? 'Guest' : 'Customer'}</div>
    <div class="receipt-info">
      <div class="receipt-info-row">
        <span>Name:</span>
        <span>${_truncateText(customerName, 25)}</span>
      </div>
      ${order.tableNo != null ? '''
      <div class="receipt-info-row">
        <span>Table:</span>
        <span>${order.tableNo}</span>
      </div>
      ''' : ''}
      ${order.waiterName != null ? '''
      <div class="receipt-info-row">
        <span>Waiter:</span>
        <span>${order.waiterName}</span>
      </div>
      ''' : ''}
    </div>
    
    <div class="divider"></div>
    
    <!-- Items -->
    <div class="section-title">Items</div>
    $itemsHtml
    
    <div class="divider"></div>
    
    <!-- Totals -->
    <div class="totals">
      <div class="total-row">
        <span class="total-label">Subtotal:</span>
        <span>${Formatters.currency(order.subtotal)}</span>
      </div>
      ${order.discountTotal > 0 ? '''
      <div class="total-row">
        <span class="total-label" style="color: #d32f2f;">Discount:</span>
        <span style="color: #d32f2f;">-${Formatters.currency(order.discountTotal)}</span>
      </div>
      ''' : ''}
      ${order.tax > 0 ? '''
      <div class="total-row">
        <span class="total-label">Tax:</span>
        <span>${Formatters.currency(order.tax)}</span>
      </div>
      ''' : ''}
      ${order.serviceCharge > 0 ? '''
      <div class="total-row">
        <span class="total-label">Service Charge:</span>
        <span>${Formatters.currency(order.serviceCharge)}</span>
      </div>
      ''' : ''}
      <div class="grand-total">
        <div class="total-row">
          <span class="total-label">TOTAL:</span>
          <span class="total-amount">${Formatters.currency(order.total)}</span>
        </div>
      </div>
    </div>
    
    <!-- Payment Info -->
    <div class="payment-info">
      <div class="receipt-info-row">
        <span>Payment Method:</span>
        <span>$paymentMethodName</span>
      </div>
      <div class="receipt-info-row">
        <span>Amount Paid:</span>
        <span>${Formatters.currency(amountPaid ?? order.total)}</span>
      </div>
      ${change > 0 ? '''
      <div class="receipt-info-row">
        <span>Change:</span>
        <span>${Formatters.currency(change)}</span>
      </div>
      ''' : ''}
    </div>
    
    ${order.comment != null && order.comment!.isNotEmpty ? '''
    <div class="note">
      Note: ${order.comment}
    </div>
    ''' : ''}
    
    <!-- Barcode -->
    <div class="barcode-container">
      <svg id="barcode" class="barcode"></svg>
      <div class="barcode-number">$barcodeData</div>
    </div>
    
    <!-- Footer -->
    <div class="footer">
      <div class="thank-you">Thank you for your business!</div>
      <div style="margin-top: 5px;">Please visit us again</div>
    </div>
  </div>
  
  <script>
    // Generate barcode using JsBarcode
    try {
      JsBarcode("#barcode", "$barcodeData", {
        format: "CODE128",
        width: 2,
        height: 50,
        displayValue: false,
        margin: 0
      });
    } catch (e) {
      console.error("Barcode generation error:", e);
    }
  </script>
</body>
</html>
  ''';
}

String _truncateText(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength - 3)}...';
}
