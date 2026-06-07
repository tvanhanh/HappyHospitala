import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'promotion_provider.dart';
import 'premium_provider.dart';
import 'advertisement_provider.dart';
import 'report_provider.dart';
import 'salary_provider.dart';

final promotionProvider = ChangeNotifierProvider<PromotionProvider>((ref) {
  return PromotionProvider();
});

final premiumProvider = ChangeNotifierProvider<PremiumProvider>((ref) {
  return PremiumProvider();
});

final advertisementProvider = ChangeNotifierProvider<AdvertisementProvider>((ref) {
  return AdvertisementProvider();
});

final reportProvider = ChangeNotifierProvider<ReportProvider>((ref) {
  return ReportProvider();
});

final salaryProvider = ChangeNotifierProvider<SalaryProvider>((ref) {
  return SalaryProvider();
});
