import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'features/timer/stopwatch_controller.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  runApp(const ProviderScope(child: AppLifecycleManager()));
}

/// Uygulama yaşam döngüsü yöneticisi
/// Uygulama kapanırken kronometreyi otomatik durdurur
class AppLifecycleManager extends ConsumerStatefulWidget {
  const AppLifecycleManager({super.key});

  @override
  ConsumerState<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends ConsumerState<AppLifecycleManager> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama kapanıyor veya arka plana geçiyor
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.detached) {
      
      // Kronometreyi duraklat (ama kaydetme)
      try {
        final stopwatchState = ref.read(stopwatchProvider);
        if (stopwatchState.isRunning) {
          ref.read(stopwatchProvider.notifier).pause();
          debugPrint('✓ Kronometre otomatik durduruldu');
        }
      } catch (e) {
        // Provider henüz initialize olmamış olabilir, görmezden gel
        debugPrint('Kronometre provider hatası: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MobilApp();
  }
}