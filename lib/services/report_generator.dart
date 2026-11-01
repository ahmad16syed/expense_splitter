import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/group.dart';
import '../models/settlement.dart';

String _money(double value) => 'Rs. ${value.toStringAsFixed(2)}';

String _date(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day/$month/${d.year}';
}

/// Builds a PDF report for one trip and returns its bytes.
Future<Uint8List> buildGroupReport(
  Group group,
  List<Settlement> settlements,
) async {
  final doc = pw.Document();

  final total = group.expenses.fold<double>(0, (sum, e) => sum + e.amount);
  final headingStyle = pw.TextStyle(
    fontSize: 16,
    fontWeight: pw.FontWeight.bold,
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Text(
          group.name,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text('Generated on ${_date(DateTime.now())}'),
        pw.SizedBox(height: 20),

        pw.Text('Summary', style: headingStyle),
        pw.SizedBox(height: 6),
        pw.Text('Total spent: ${_money(total)}'),
        pw.Text('Number of expenses: ${group.expenses.length}'),
        pw.Text('Members: ${group.members.map((m) => m.name).join(', ')}'),
        pw.SizedBox(height: 20),

        pw.Text('Expenses', style: headingStyle),
        pw.SizedBox(height: 6),
        if (group.expenses.isEmpty)
          pw.Text('No expenses recorded.')
        else
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Description', 'Paid by', 'Split', 'Amount'],
            data: group.expenses
                .map(
                  (e) => [
                    _date(e.date),
                    e.description,
                    e.paidBy.name,
                    '${e.splitBetween.length} people',
                    _money(e.amount),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        pw.SizedBox(height: 20),

        pw.Text('Who owes whom', style: headingStyle),
        pw.SizedBox(height: 6),
        if (settlements.isEmpty)
          pw.Text('Everyone is settled up.')
        else
          pw.TableHelper.fromTextArray(
            headers: ['From', 'To', 'Amount'],
            data: settlements
                .map((s) => [s.from.name, s.to.name, _money(s.amount)])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
          ),
      ],
    ),
  );

  return doc.save();
}
