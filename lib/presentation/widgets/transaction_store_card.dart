import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/transaction_model.dart';

class TransactionStoreCard extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionStoreCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h, left: 16.w, right: 16.w),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          children: [
            // Icon Status berdasarkan status "paid" atau lainnya
            CircleAvatar(
              backgroundColor: transaction.isPaid 
                  ? Colors.green.withValues(alpha:  0.1) 
                  : Colors.orange.withValues(alpha: 0.1),
              child: Icon(
                transaction.isPaid ? Icons.check_circle : Icons.pending,
                color: transaction.isPaid ? Colors.green : Colors.orange,
              ),
            ),
            SizedBox(width: 12.w),
            
            // Informasi Detail Transaksi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.invoiceNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    transaction.createdAt,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Nominal Transaksi (Sudah terformat Rupiah dari Model)
            Text(
              transaction.formattedTotal,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: Colors.blue.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}