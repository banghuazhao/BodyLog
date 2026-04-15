import AdSupport
import AppTrackingTransparency
import GoogleMobileAds
import SwiftUI

class AdManager {
    static var isAuthorized = false

    struct GoogleAdsID {
        static let bannerViewAdUnitID = Bundle.main.object(forInfoDictionaryKey: "bannerViewAdUnitID") as? String ?? ""
        static let appOpenAdID = Bundle.main.object(forInfoDictionaryKey: "appOpenAdID") as? String ?? ""
    }

    static func requestATTPermission(with time: TimeInterval = 0) {
        guard !isAuthorized else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    // Tracking authorization dialog was shown
                    // and we are authorized
                    print("Authorized")
                    isAuthorized = true
    
                    // Now that we are authorized we can get the IDFA
                    print(ASIdentifierManager.shared().advertisingIdentifier)
                case .denied:
                    // Tracking authorization dialog was
                    // shown and permission is denied
                    print("Denied")
                case .notDetermined:
                    // Tracking authorization dialog has not been shown
                    print("Not Determined")
                case .restricted:
                    print("Restricted")
                @unknown default:
                    print("Unknown")
                }
            }
        }
    }
}

struct BannerView: View {
    static let fixedAdWidth: CGFloat = 320
    static let fixedAdHeight: CGFloat = 100
    private let adUnitID = AdManager.GoogleAdsID.bannerViewAdUnitID

    var body: some View {
        BannerContainer(adUnitID: adUnitID)
    }
}

private struct BannerContainer: UIViewRepresentable {
    let adUnitID: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> GoogleMobileAds.BannerView {
        let banner = GoogleMobileAds.BannerView()
        banner.delegate = context.coordinator
        banner.adUnitID = adUnitID
        return banner
    }

    func updateUIView(_ banner: GoogleMobileAds.BannerView, context: Context) {
        guard !adUnitID.isEmpty else { return }
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController
            ?? scene.windows.first?.rootViewController
        guard let root else { return }

        banner.rootViewController = root
        let adSize = adSizeFor(cgSize: CGSize(width: BannerView.fixedAdWidth, height: BannerView.fixedAdHeight))
        if context.coordinator.didLoad { return }

        context.coordinator.didLoad = true
        banner.adSize = adSize
        let request = Request()
        request.scene = scene
        banner.load(request)
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        var didLoad = false

        func bannerViewDidReceiveAd(_ bannerView: GoogleMobileAds.BannerView) {
            print("DID RECEIVE Banner AD")
        }

        func bannerView(_ bannerView: GoogleMobileAds.BannerView, didFailToReceiveAdWithError error: Error) {
            print("DID NOT RECEIVE Banner AD: \(error.localizedDescription)")
        }
    }
}
