import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  static final bool _useTestAds = !kReleaseMode;

  // TODO(release): AdMob 콘솔에서 pupil 광고 단위 생성 후 ID 교체.
  static const _realRewardedId = 'ca-app-pub-0000000000000000/0000000000';
  static const _realInterstitialId = 'ca-app-pub-0000000000000000/0000000000';

  static const _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const _testInterstitialId = 'ca-app-pub-3940256099942544/4411468910';

  static String get _rewardedId => _useTestAds ? _testRewardedId : _realRewardedId;
  static String get _interstitialId => _useTestAds ? _testInterstitialId : _realInterstitialId;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  int _retryCount = 0;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;
  int _interstitialRetry = 0;
  int _resultViewCount = 0;

  bool _adsRemoved = false;
  void setAdsRemoved(bool v) => _adsRemoved = v;
  bool get adsRemoved => _adsRemoved;

  bool get isRewardedAdReady => _isRewardedAdReady;
  bool get isInterstitialReady => _isInterstitialReady;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    if (_adsRemoved) return;
    loadRewardedAd();
    loadInterstitialAd();
  }

  void loadRewardedAd() {
    if (_adsRemoved || _retryCount >= 3) return;
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          _retryCount = 0;
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdReady = false;
          _retryCount++;
          Future.delayed(const Duration(seconds: 5), loadRewardedAd);
        },
      ),
    );
  }

  Future<bool> showRewardedAd({required VoidCallback onRewarded}) async {
    if (_adsRemoved) {
      onRewarded();
      return true;
    }
    if (!_isRewardedAdReady || _rewardedAd == null) {
      if (_retryCount >= 3) {
        _retryCount = 0;
        loadRewardedAd();
      }
      return false;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isRewardedAdReady = false;
        _retryCount = 0;
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isRewardedAdReady = false;
        _retryCount = 0;
        loadRewardedAd();
      },
    );
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) => onRewarded(),
    );
    _rewardedAd = null;
    return true;
  }

  void loadInterstitialAd() {
    if (_adsRemoved || _interstitialRetry >= 3) return;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          _interstitialRetry = 0;
        },
        onAdFailedToLoad: (error) {
          _isInterstitialReady = false;
          _interstitialRetry++;
          Future.delayed(const Duration(seconds: 5), loadInterstitialAd);
        },
      ),
    );
  }

  Future<void> maybeShowResultInterstitial() async {
    if (_adsRemoved) return;
    _resultViewCount++;
    if (_resultViewCount % 2 != 0) return;
    if (!_isInterstitialReady || _interstitialAd == null) return;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isInterstitialReady = false;
        _interstitialRetry = 0;
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isInterstitialReady = false;
        _interstitialRetry = 0;
        loadInterstitialAd();
      },
    );
    await _interstitialAd!.show();
    _interstitialAd = null;
  }
}
