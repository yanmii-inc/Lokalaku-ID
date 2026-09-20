import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: BackofficeApp()));
}

class BackofficeApp extends StatelessWidget {
  const BackofficeApp({super.key});

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lokalaku Backoffice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF15803D),
          primary: const Color(0xFF15803D),
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(apiBaseUrl: apiBaseUrl),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final String apiBaseUrl;

  const DashboardScreen({super.key, required this.apiBaseUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokalaku Backoffice Portal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Chip(
                label: Text(
                  'API: $apiBaseUrl',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Ekosistem Desa',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Panel kontrol superadmin dan operator klaster Lokalaku.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: const [
                  MetricCard(
                    title: 'Klaster Aktif',
                    value: '12 Desa',
                    icon: Icons.holiday_village_outlined,
                  ),
                  MetricCard(
                    title: 'Warung Terdaftar',
                    value: '148 Warung',
                    icon: Icons.storefront_outlined,
                  ),
                  MetricCard(
                    title: 'Pesanan Bersama',
                    value: '24 Batch',
                    icon: Icons.group_work_outlined,
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

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
