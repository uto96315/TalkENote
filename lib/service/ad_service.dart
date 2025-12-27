import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'dart:io' show Platform;

/// 広告サービス
/// 
/// 使用例:
/// ```dart
/// final adService = AdService();
/// await adService.initialize();
/// await adService.showInterstitialAd();
/// ```
class AdService {
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  
  // 本番環境の広告ユニットID（iOS）
  // インタースティシャル広告（録音完了時に表示）
  static const String _productionInterstitialAdUnitIdIOS = 'ca-app-pub-2532800325700758/1009215283';
  // バナー広告（記録リストに表示）
  // TODO: iOSバナーの広告ユニットIDを取得して設定してください
  static const String _productionBannerAdUnitIdIOS = 'ca-app-pub-2532800325700758/8850571509';
  
  // 本番環境の広告ユニットID（Android）
  // TODO: Android用の広告ユニットIDを取得して設定してください
  static const String _productionInterstitialAdUnitIdAndroid = 'ca-app-pub-2532800325700758/8850571509';
  static const String _productionBannerAdUnitIdAndroid = 'ca-app-pub-2532800325700758/8850571509';
  
  // プラットフォームに応じた広告ユニットIDを取得
  static String _getInterstitialAdUnitId() {
    if (kDebugMode) {
      return _testInterstitialAdUnitId;
    }
    return Platform.isIOS 
        ? _productionInterstitialAdUnitIdIOS 
        : _productionInterstitialAdUnitIdAndroid;
  }
  
  static String _getBannerAdUnitId() {
    if (kDebugMode) {
      return _testBannerAdUnitId;
    }
    return Platform.isIOS 
        ? _productionBannerAdUnitIdIOS 
        : _productionBannerAdUnitIdAndroid;
  }

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  bool _isInitialized = false;

  /// インタースティシャル広告が準備できているかどうか
  bool get isInterstitialAdReady => _isInterstitialAdReady && _interstitialAd != null;

  /// AdMobを初期化
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await MobileAds.instance.initialize();
    _isInitialized = true;
    debugPrint('AdMob initialized');
    
    // インタースティシャル広告を事前に読み込む
    _loadInterstitialAd();
  }

  /// インタースティシャル広告を事前に読み込む（外部から呼び出し可能）
  void preloadInterstitialAd() {
    if (!_isInitialized) {
      initialize().then((_) => _loadInterstitialAd());
      return;
    }
    // 既に読み込まれている場合は何もしない
    if (_isInterstitialAdReady && _interstitialAd != null) {
      return;
    }
    _loadInterstitialAd();
  }

  /// インタースティシャル広告を読み込む
  void _loadInterstitialAd() {
    final adUnitId = _getInterstitialAdUnitId();
    
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          debugPrint('Interstitial ad loaded');
          
          // 広告が閉じられたら次の広告を読み込む
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial ad failed to show: $error');
              ad.dispose();
              _isInterstitialAdReady = false;
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
          // リトライは自動的には行わない（次回のshowInterstitialAd呼び出し時に再試行）
        },
      ),
    );
  }

  /// インタースティシャル広告を表示
  /// 
  /// 広告が表示された場合、trueを返します。
  /// 広告が準備できていない場合、falseを返します。
  Future<bool> showInterstitialAd() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInterstitialAdReady || _interstitialAd == null) {
      debugPrint('Interstitial ad is not ready (ready: $_isInterstitialAdReady, ad: ${_interstitialAd != null})');
      // 広告が準備できていない場合でも、次の広告を読み込んでおく
      _loadInterstitialAd();
      return false;
    }

    debugPrint('Showing interstitial ad...');
    _interstitialAd!.show();
    _isInterstitialAdReady = false;
    return true;
  }

  /// バナー広告ウィジェットを作成
  /// 
  /// 使用例:
  /// ```dart
  /// AdBanner(adUnitId: AdService.getBannerAdUnitId())
  /// ```
  static String getBannerAdUnitId() {
    return _getBannerAdUnitId();
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
  }
}

/// バナー広告ウィジェット
class AdBanner extends StatefulWidget {
  const AdBanner({
    super.key,
    required this.adUnitId,
    this.width = 320,
    this.height = 50,
  });

  final String adUnitId;
  final double width;
  final double height;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
      );
    }

    return Container(
      alignment: Alignment.center,
      width: widget.width,
      height: widget.height,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

