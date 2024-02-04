//
//  BannerAd.swift
//  Pace
//
//  Created by Brandon Roehl on 2/24/23.
//

import SwiftUI
import GoogleMobileAds

struct BannerAd: View {
    let adUnitID: String
    var minHeight: CGFloat = 60
    var maxHeight: CGFloat = .infinity
    
    private struct AdView : UIViewRepresentable {
#if DEBUG
        private static let isDebug = true
#else
        private static let isDebug = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
#endif
        
        @Binding fileprivate var viewWidth: CGFloat
        fileprivate var adUnitId: String
        
        private let bannerView = GADBannerView()
        
        func makeUIView(context: UIViewRepresentableContext<AdView>) -> GADBannerView {
            // This is important for the terms of service do not use the real ID in debug or TestFlight
            self.bannerView.adUnitID = Self.isDebug ? "ca-app-pub-3940256099942544/2934735716" : self.adUnitId
            self.bannerView.rootViewController = UIApplication.shared.rootViewController
            return bannerView
        }
        
        func updateUIView(_ uiView: GADBannerView, context: Context) {
            guard self.viewWidth != .zero else { return }

            // Request a banner ad with the updated viewWidth.
            uiView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(self.viewWidth)
            uiView.load(GADRequest())
        }
    }
    
    @State private var viewWidth: CGFloat = .zero
    
    var body: some View {
        VStack {
            GeometryReader { (geometry) in
                AdView(viewWidth: self.$viewWidth, adUnitId: self.adUnitID)
                    .onAppear {
                        self.viewWidth = geometry.size.width
                    }
            }
        }.frame(
            minWidth: 0,
            idealWidth: .infinity,
            maxWidth: .infinity,
            minHeight: self.minHeight,
            idealHeight: nil,
            maxHeight: self.maxHeight
        )
    }
}

struct BannerAd_Previews: PreviewProvider {
    static var previews: some View {
        BannerAd(adUnitID: "", minHeight: 300)
    }
}
