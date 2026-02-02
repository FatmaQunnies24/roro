import 'package:flutter/material.dart';
import 'monitoring_view.dart';

class MonitoringSettingsView extends StatefulWidget {
  final String userId;

  const MonitoringSettingsView({super.key, required this.userId});

  @override
  State<MonitoringSettingsView> createState() => _MonitoringSettingsViewState();
}

class _MonitoringSettingsViewState extends State<MonitoringSettingsView> {
  String _playMode = 'فردي';
  String _monitoringFocus = 'screams'; // 'screams' = عدد الصرخات، 'badWords' = عدد الكلمات السيئة

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات المراقبة'),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'يرجى تحديد نوع اللعب قبل بدء المراقبة:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // نوع اللعب
            DropdownButtonFormField<String>(
              value: _playMode,
              decoration: const InputDecoration(
                labelText: 'نوع اللعب *',
                prefixIcon: Icon(Icons.people),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'فردي', child: Text('فردي')),
                DropdownMenuItem(value: 'جماعي', child: Text('جماعي')),
              ],
              onChanged: (value) {
                setState(() => _playMode = value!);
              },
            ),

            const SizedBox(height: 24),
            const Text(
              'ماذا تريد مراقبته؟',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            RadioListTile<String>(
              title: const Text('عدد الصرخات فقط (مستوى الصوت فوق 99%)'),
              subtitle: const Text('المايك يقيس مستوى الصوت وعدّ الصرخات'),
              value: 'screams',
              groupValue: _monitoringFocus,
              onChanged: (value) => setState(() => _monitoringFocus = value!),
            ),
            RadioListTile<String>(
              title: const Text('عدد الكلمات السيئة فقط'),
              subtitle: const Text('المايك يضل فاتح ويستمع للكلام فقط'),
              value: 'badWords',
              groupValue: _monitoringFocus,
              onChanged: (value) => setState(() => _monitoringFocus = value!),
            ),
            RadioListTile<String>(
              title: const Text('صراخ + كلمات سيئة'),
              subtitle: const Text('يتناوب بين قياس الصوت (صرخات) والكلام (كلمات سيئة)'),
              value: 'both',
              groupValue: _monitoringFocus,
              onChanged: (value) => setState(() => _monitoringFocus = value!),
            ),

            const SizedBox(height: 40),

            // زر البدء
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MonitoringView(
                        userId: widget.userId,
                        playMode: _playMode,
                        monitoringFocus: _monitoringFocus,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'بدء المراقبة',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

