import GoogleMobileAds
import SwiftUI

struct NativeContentView: View {
    @StateObject private var nativeViewModel = NativeAdViewModel()
    
    init(adUnitID: String) {
        self.nativeViewModel.adUnitID = adUnitID
    }
    
    var body: some View {
        NativeAdView(nativeViewModel: nativeViewModel)
            .onAppear {
                self.nativeViewModel.refreshAd()
            }
            .frame(height: 120)
    }
}

struct NativeContentView_Previews: PreviewProvider {
    static var previews: some View {
        NativeContentView(adUnitID: "test")
    }
}

private struct NativeAdView: UIViewRepresentable {
    typealias UIViewType = GADNativeAdView
    
    @ObservedObject var nativeViewModel: NativeAdViewModel
    
    func makeUIView(context: Context) -> GADNativeAdView {
        return Bundle.main.loadNibNamed(
            "NativeAdView",
            owner: nil,
            options: nil)?.first as! GADNativeAdView
    }
    
    func updateUIView(_ nativeAdView: GADNativeAdView, context: Context) {
        guard let nativeAd = nativeViewModel.nativeAd else { return }
        
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        (nativeAdView.storeView as? UILabel)?.text = nativeAd.store
        (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        // In order for the SDK to process touch events properly, user interaction should be disabled.
        nativeAdView.callToActionView?.isUserInteractionEnabled = false
        
        // Associate the native ad view with the native ad object. This is required to make the ad clickable.
        // Note: this should always be done after populating the ad views.
        nativeAdView.nativeAd = nativeAd
    }
}

private class NativeAdViewModel: NSObject, ObservableObject, GADNativeAdLoaderDelegate {
    @Published var nativeAd: GADNativeAd?
    private var adLoader: GADAdLoader!
    
    var adUnitID: String = "ca-app-pub-3940256099942544/2247696110"
    
#if DEBUG
        private static let isDebug = true
#else
        private static let isDebug = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
#endif
    
    func refreshAd() {
        adLoader = GADAdLoader(
            adUnitID: Self.isDebug ?
            "ca-app-pub-3940256099942544/2247696110": self.adUnitID,
            rootViewController: nil,
            adTypes: [.native], options: nil)
        adLoader.delegate = self
        adLoader.load(GADRequest())
    }
    
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        self.nativeAd = nativeAd
        nativeAd.delegate = self
    }
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
    }
}

// MARK: - GADNativeAdDelegate implementation
extension NativeAdViewModel: GADNativeAdDelegate {
    func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdWillPresentScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdWillDismissScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    func nativeAdDidDismissScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
}
