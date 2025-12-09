import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart' as intl;

void main() {
  runApp(const OilCalculatorApp());
}

class OilCalculatorApp extends StatelessWidget {
  const OilCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'محاسبه‌گر بار',
      debugShowCheckedModeBanner: false,
      // Set locale to Persian (Farsi) for RTL layout
      locale: const Locale('fa', 'IR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fa', 'IR'), // Persian
        Locale('en', 'US'), // English
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'Roboto', // Fallback font, ideally use a Persian font like Vazir
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // 10 rows, 3 input columns (4th is calculated)
  final int _rowCount = 10;
  
  // Controllers for inputs
  late List<TextEditingController> _col1Controllers; // تحویل با بشکه
  late List<TextEditingController> _col2Controllers; // بشکه (تحویلی)
  late List<TextEditingController> _col3Controllers; // برگشت با بشکه
  
  // Computed values for display
  late List<double?> _col4Values; // بشکه (برگشتی) - Calculated

  // Totals
  double _sumCol1 = 0;
  double _sumCol2 = 0;
  double _sumCol3 = 0;
  double _sumCol4 = 0;
  double _finalTotal = 0;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _col1Controllers = List.generate(_rowCount, (_) => TextEditingController());
    _col2Controllers = List.generate(_rowCount, (_) => TextEditingController());
    _col3Controllers = List.generate(_rowCount, (_) => TextEditingController());
    _col4Values = List.generate(_rowCount, (_) => null);

    // Add listeners to recalculate on change
    for (int i = 0; i < _rowCount; i++) {
      _col1Controllers[i].addListener(_calculateTotals);
      _col2Controllers[i].addListener(_calculateTotals);
      _col3Controllers[i].addListener(_calculateTotals);
    }
  }

  @override
  void dispose() {
    for (var controller in _col1Controllers) controller.dispose();
    for (var controller in _col2Controllers) controller.dispose();
    for (var controller in _col3Controllers) controller.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    double tempSumCol1 = 0;
    double tempSumCol2 = 0;
    double tempSumCol3 = 0;
    double tempSumCol4 = 0;

    List<double?> tempCol4Values = List.filled(_rowCount, null);

    for (int i = 0; i < _rowCount; i++) {
      // Parse inputs
      double val1 = double.tryParse(_col1Controllers[i].text) ?? 0;
      double val2 = double.tryParse(_col2Controllers[i].text) ?? 0;
      String text3 = _col3Controllers[i].text;
      double val3 = double.tryParse(text3) ?? 0;

      // Logic for Column 4:
      // If Col3 has value (is not empty), Col4 = Col2. Else Col4 is empty.
      double val4 = 0;
      if (text3.isNotEmpty) {
        val4 = val2;
        tempCol4Values[i] = val4;
      } else {
        tempCol4Values[i] = null;
      }

      // Sums
      tempSumCol1 += val1;
      tempSumCol2 += val2;
      tempSumCol3 += val3;
      tempSumCol4 += val4;
    }

    // Final Calculation:
    // (Sum Col1) - (Sum Col2) - (Sum Col3) + (Sum Col4)
    double finalCalc = tempSumCol1 - tempSumCol2 - tempSumCol3 + tempSumCol4;

    setState(() {
      _col4Values = tempCol4Values;
      _sumCol1 = tempSumCol1;
      _sumCol2 = tempSumCol2;
      _sumCol3 = tempSumCol3;
      _sumCol4 = tempSumCol4;
      _finalTotal = finalCalc;
    });
  }

  void _resetForm() {
    for (int i = 0; i < _rowCount; i++) {
      _col1Controllers[i].clear();
      _col2Controllers[i].clear();
      _col3Controllers[i].clear();
    }
    _calculateTotals(); // Reset totals
  }

  void _shareData() {
    final buffer = StringBuffer();
    buffer.writeln('گزارش محاسبه بار:');
    buffer.writeln('--------------------------------');
    
    // Headers
    buffer.writeln('ردیف | تحویل با بشکه | بشکه | برگشت با بشکه | بشکه');
    
    // Rows
    for (int i = 0; i < _rowCount; i++) {
      String c1 = _col1Controllers[i].text.isEmpty ? '-' : _col1Controllers[i].text;
      String c2 = _col2Controllers[i].text.isEmpty ? '-' : _col2Controllers[i].text;
      String c3 = _col3Controllers[i].text.isEmpty ? '-' : _col3Controllers[i].text;
      String c4 = _col4Values[i] == null ? '-' : _formatNumber(_col4Values[i]!);
      
      if (c1 != '-' || c2 != '-' || c3 != '-') {
         buffer.writeln('${i + 1} | $c1 | $c2 | $c3 | $c4');
      }
    }
    
    buffer.writeln('--------------------------------');
    buffer.writeln('مجموع کل تحویل با بشکه: ${_formatNumber(_sumCol1)}');
    buffer.writeln('مجموع بشکه تحویلی: ${_formatNumber(_sumCol2)}');
    buffer.writeln('مجموع برگشت با بشکه: ${_formatNumber(_sumCol3)}');
    buffer.writeln('مجموع بشکه برگشتی: ${_formatNumber(_sumCol4)}');
    buffer.writeln('--------------------------------');
    buffer.writeln('*** مجموع بار تحویلی (خالص): ${_formatNumber(_finalTotal)} ***');

    Share.share(buffer.toString(), subject: 'گزارش بار');
  }

  String _formatNumber(double number) {
    // Remove decimal point if it's a whole number
    if (number % 1 == 0) {
      return number.toInt().toString();
    }
    return number.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محاسبه‌گر بار و بشکه'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetForm,
            tooltip: 'ریست',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareData,
            tooltip: 'ارسال',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Main Table
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(30), // Row Number
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(0.7),
                  3: FlexColumnWidth(1),
                  4: FlexColumnWidth(0.7),
                },
                border: TableBorder.all(color: Colors.grey.shade300),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // Header Row
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade200),
                    children: const [
                      Padding(padding: EdgeInsets.all(4), child: Text('#', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(4), child: Text('تحویل\nبا بشکه', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Padding(padding: EdgeInsets.all(4), child: Text('بشکه', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Padding(padding: EdgeInsets.all(4), child: Text('برگشت\nبا بشکه', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Padding(padding: EdgeInsets.all(4), child: Text('بشکه', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                  // Data Rows
                  ...List.generate(_rowCount, (index) {
                    return TableRow(
                      children: [
                        // Row Number
                        Text('${index + 1}', textAlign: TextAlign.center),
                        // Col 1 Input
                        _buildInputCell(_col1Controllers[index]),
                        // Col 2 Input
                        _buildInputCell(_col2Controllers[index]),
                        // Col 3 Input
                        _buildInputCell(_col3Controllers[index]),
                        // Col 4 Calculated (Read Only)
                        Container(
                          height: 48,
                          alignment: Alignment.center,
                          color: Colors.grey.shade50,
                          child: Text(
                            _col4Values[index] == null ? '' : _formatNumber(_col4Values[index]!),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Summary Table
            const Text('محاسبات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.blueGrey.shade50,
              ),
              child: Column(
                children: [
                  _buildSummaryRow('مجموع کل تحویل با بشکه:', _sumCol1),
                  const Divider(height: 1),
                  _buildSummaryRow('مجموع بشکه تحویلی:', _sumCol2),
                  const Divider(height: 1),
                  _buildSummaryRow('مجموع برگشت با بشکه:', _sumCol3),
                  const Divider(height: 1),
                  _buildSummaryRow('مجموع بشکه برگشتی:', _sumCol4),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Final Result Card
            Card(
              elevation: 4,
              color: Theme.of(context).colorScheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'مجموع بار تحویلی (خالص)',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatNumber(_finalTotal),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '(تحویل - بشکه تحویلی) - (برگشت + بشکه برگشتی)',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Bottom Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _resetForm,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('ریست کردن'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareData,
                    icon: const Icon(Icons.share),
                    label: const Text('ارسال گزارش'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCell(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            _formatNumber(value),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
