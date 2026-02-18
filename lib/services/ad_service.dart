import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../ad_helper.dart';

class AdService {
  static final AdService _instance = AdService._internal();

  factory AdService() => _instance;

  AdService._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  // --- Ad Unit IDs ---
  String get bannerAdUnitId => AdHelper.bannerAdUnitId;
  String get interstitialAdUnitId => AdHelper.interstitialAdUnitId;
  String get rewardedAdUnitId => AdHelper.rewardedAdUnitId;

  /// Logs a key ad event to Firebase Analytics (only important events)
  void _logAdEvent(String eventName, {Map<String, Object>? params}) {
    _analytics.logEvent(name: eventName, parameters: params);
    debugPrint('[AdService] $eventName: $params');
  }

  // --- Initialization ---
  Future<void> initialize() async {
    // Handle Consent (GDPR/CPRA)
    await handleConsent();
    
    // Configure test devices to avoid AdMob bans
    final requestConfiguration = RequestConfiguration(
      testDeviceIds: AdHelper.testDeviceIds,
    );
    await MobileAds.instance.updateRequestConfiguration(requestConfiguration);
    
    // Initialize Mobile Ads SDK
    final initStatus = await MobileAds.instance.initialize();

    // Log adapter status summary (once per app launch)
    final adapterStatuses = initStatus.adapterStatuses;
    final readyCount = adapterStatuses.values.where((s) => s.state == AdapterInitializationState.ready).length;
    _logAdEvent('ad_init', params: {
      'adapters_ready': readyCount,
      'adapters_total': adapterStatuses.length,
    });
    
    // Preload ads
    loadInterstitialAd();
    loadRewardedAd();
  }

  /// Handles the consent flow using User Messaging Platform (UMP) SDK.
  Future<void> handleConsent() async {
    final completer = Completer<void>();
    
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        final consentStatus = await ConsentInformation.instance.getConsentStatus();
        _logAdEvent('ad_consent', params: {
          'status': consentStatus.toString(),
        });

        ConsentInformation.instance.isConsentFormAvailable().then((isAvailable) {
          if (isAvailable) {
            _showConsentForm(completer);
          } else {
            completer.complete();
          }
        });
      },
      (FormError error) {
        _logAdEvent('ad_consent', params: {
          'status': 'error',
          'error_code': error.errorCode,
          'error_msg': error.message,
        });
        completer.complete(); // Proceed anyway
      },
    );

    return completer.future;
  }

  void _showConsentForm(Completer<void> completer) {
    ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (error != null) {
        debugPrint("Consent Form Error (${error.errorCode}): ${error.message}");
      }
      completer.complete();
    });
  }

  // --- Interstitial Ad ---
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('[AdService] Interstitial loaded');
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          // Only log failures — this is what we need to diagnose
          _logAdEvent('ad_load_fail', params: {
            'type': 'interstitial',
            'code': error.code,
            'msg': error.message.length > 100 ? error.message.substring(0, 100) : error.message,
          });
          Future.delayed(const Duration(seconds: 30), () {
            loadInterstitialAd();
          });
        },
      ),
    );
  }

  DateTime? _lastInterstitialAdTime;

  void showInterstitialAd() {
    if (_lastInterstitialAdTime != null) {
      final difference = DateTime.now().difference(_lastInterstitialAdTime!);
      if (difference.inMinutes < 2) {
        return;
      }
    }

    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _lastInterstitialAdTime = DateTime.now();
      _interstitialAd = null;
    } else {
      debugPrint('[AdService] Interstitial not ready');
      loadInterstitialAd();
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
          debugPrint('[AdService] Rewarded loaded');
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _logAdEvent('ad_load_fail', params: {
            'type': 'rewarded',
            'code': error.code,
            'msg': error.message.length > 100 ? error.message.substring(0, 100) : error.message,
          });
          Future.delayed(const Duration(seconds: 30), () {
            loadRewardedAd();
          });
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
      loadRewardedAd();
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_rewardedAd != null) {
          _rewardedAd!.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              onRewardEarned();
            },
          );
          _rewardedAd = null;
          return;
        }
      }
      // Ad still not available — proceed anyway
      _logAdEvent('ad_load_fail', params: {
        'type': 'rewarded',
        'code': -1,
        'msg': 'timeout_fallback',
      });
      onRewardEarned();
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
          debugPrint('[AdService] Banner loaded');
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          AdService()._logAdEvent('ad_load_fail', params: {
            'type': 'banner',
            'code': error.code,
            'msg': error.message.length > 100 ? error.message.substring(0, 100) : error.message,
          });
          ad.dispose();
          Future.delayed(const Duration(seconds: 30), () {
            if (mounted) _loadAd();
          });
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
    return const SizedBox.shrink();
  }
}
