import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ad_helper.dart';


class AdService {
  static final AdService _instance = AdService._internal();

  factory AdService() => _instance;

  AdService._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // --- Ad Unit IDs ---
  String get bannerAdUnitId => AdHelper.bannerAdUnitId;
  String get interstitialAdUnitId => AdHelper.interstitialAdUnitId;
  String get rewardedAdUnitId => AdHelper.rewardedAdUnitId;


  // --- Initialization ---
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitialAd(); // Preload
    loadRewardedAd();     // Preload
  }

  // --- Interstitial Ad ---
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadInterstitialAd(); // Reload after dismiss
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              loadInterstitialAd(); // Reload on failure
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  DateTime? _lastInterstitialAdTime;

  void showInterstitialAd() {
    // Frequency cap: Check if 5 minutes have passed
    if (_lastInterstitialAdTime != null) {
      final difference = DateTime.now().difference(_lastInterstitialAdTime!);
      if (difference.inMinutes < 5) {
        debugPrint('InterstitialAd skipped: Freequency cap (waited ${difference.inMinutes} mins)');
        return;
      }
    }

    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _lastInterstitialAdTime = DateTime.now(); // Update timestamp
      _interstitialAd = null; // Clear reference
    } else {
      debugPrint('InterstitialAd not ready yet.');
      loadInterstitialAd(); // Try loading again
    }
  }

  // --- Rewarded Ad ---
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadRewardedAd(); // Reload
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  Future<void> showRewardedAd({required Function onRewardEarned}) async {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onRewardEarned();
        },
      );
      _rewardedAd = null;
    } else {
      debugPrint('RewardedAd not ready yet.');
      loadRewardedAd(); // Try loading again
      // Optionally handle the case where ad isn't ready (e.g., just proceed)
      // For now, we just don't show it and let the user click again or proceed.
      // A better UX might be to show a "Loading Ad..." toast or similar.
    }
  }
}

// --- Banner Ad Widget ---
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adUnitId = AdService().bannerAdUnitId;
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink(); // Hide if not loaded
  }
}
