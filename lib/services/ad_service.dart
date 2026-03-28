import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const String appId = 'ca-app-pub-8395541911265203~6586053904';
  static const String bannerId = 'ca-app-pub-8395541911265203/9387477003';
  static const String interstitialId = 'ca-app-pub-8395541911265203/9714513224';
  static const String rewardedId = 'ca-app-pub-8395541911265203/5883031579';

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => print('InterstitialAd failed to load: $error'),
      ),
    );
  }

  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
       // Reload for next time
    }
  }

  void loadRewardedAd(Function onComplete, Function onFailed) {
    RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            onComplete();
          });
        },
        onAdFailedToLoad: (error) {
          print('RewardedAd failed to load: $error');
          onFailed();
        },
      ),
    );
  }

  BannerAd createBannerAd(Function onLoaded) {
    return BannerAd(
      adUnitId: bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('BannerAd failed to load: $error');
        },
      ),
    )..load();
  }
}
