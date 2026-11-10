import SwiftUI
import WebKit
import Combine

// MARK: - Persistent YouTube Player Controller
class YouTubePlayerController: NSObject, ObservableObject, WKNavigationDelegate, WKScriptMessageHandler {
    static let shared = YouTubePlayerController()

    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentVideoId: String?
    @Published var isReady = false

    var onPlaybackFinished: (() -> Void)?

    let webView: WKWebView

    private override init() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        if #available(iOS 14.5, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        }

        let userContentController = WKUserContentController()
        configuration.userContentController = userContentController

        self.webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 220), configuration: configuration)
        self.webView.scrollView.isScrollEnabled = false
        self.webView.backgroundColor = .black
        self.webView.isOpaque = false

        super.init()

        userContentController.add(self, name: "youtubePlayback")
        self.webView.navigationDelegate = self
    }

    func load(videoId: String) {
        if currentVideoId == videoId && isReady {
            play()
            return
        }

        currentVideoId = videoId
        isReady = false
        currentTime = 0
        duration = 0
        isPlaying = true

        let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; background: #000; overflow: hidden; }
                html, body { width: 100%; height: 100%; }
                #player { width: 100%; height: 100%; }
            </style>
        </head>
        <body>
            <div id="player"></div>
            <script>
                var tag = document.createElement('script');
                tag.src = "https://www.youtube.com/iframe_api";
                var firstScriptTag = document.getElementsByTagName('script')[0];
                firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

                var player;
                var timeInterval;

                function onYouTubeIframeAPIReady() {
                    player = new YT.Player('player', {
                        videoId: '\(videoId)',
                        playerVars: {
                            'autoplay': 1,
                            'playsinline': 1,
                            'controls': 0,
                            'rel': 0,
                            'enablejsapi': 1,
                            'origin': 'https://www.youtube.com'
                        },
                        events: {
                            'onReady': onPlayerReady,
                            'onStateChange': onPlayerStateChange
                        }
                    });
                }

                function onPlayerReady(event) {
                    event.target.playVideo();
                    var dur = event.target.getDuration() || 0;
                    window.webkit.messageHandlers.youtubePlayback.postMessage({
                        type: 'ready',
                        duration: dur
                    });
                    startTimeUpdates();
                }

                function onPlayerStateChange(event) {
                    window.webkit.messageHandlers.youtubePlayback.postMessage({
                        type: 'state',
                        state: event.data
                    });
                }

                function startTimeUpdates() {
                    if (timeInterval) clearInterval(timeInterval);
                    timeInterval = setInterval(function() {
                        if (player && player.getCurrentTime) {
                            var cur = player.getCurrentTime() || 0;
                            var dur = player.getDuration() || 0;
                            window.webkit.messageHandlers.youtubePlayback.postMessage({
                                type: 'time',
                                currentTime: cur,
                                duration: dur
                            });
                        }
                    }, 500);
                }
            </script>
        </body>
        </html>
        """
        webView.loadHTMLString(embedHTML, baseURL: URL(string: "https://www.youtube.com"))
    }

    func play() {
        isPlaying = true
        webView.evaluateJavaScript("if (window.player && player.playVideo) { player.playVideo(); }", completionHandler: nil)
    }

    func pause() {
        isPlaying = false
        webView.evaluateJavaScript("if (window.player && player.pauseVideo) { player.pauseVideo(); }", completionHandler: nil)
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to seconds: TimeInterval) {
        currentTime = seconds
        webView.evaluateJavaScript("if (window.player && player.seekTo) { player.seekTo(\(seconds), true); }", completionHandler: nil)
    }

    func stop() {
        isPlaying = false
        currentVideoId = nil
        isReady = false
        currentTime = 0
        duration = 0
        webView.evaluateJavaScript("if (window.player && player.stopVideo) { player.stopVideo(); }", completionHandler: nil)
        webView.loadHTMLString("about:blank", baseURL: nil)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any],
              let type = dict["type"] as? String else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch type {
            case "ready":
                self.isReady = true
                if let dur = dict["duration"] as? Double, dur > 0 {
                    self.duration = dur
                }
                self.isPlaying = true
            case "state":
                if let state = dict["state"] as? Int {
                    // YT.PlayerState: -1 unstarted, 0 ended, 1 playing, 2 paused, 3 buffering, 5 cued
                    switch state {
                    case 0:
                        self.isPlaying = false
                        self.onPlaybackFinished?()
                    case 1:
                        self.isPlaying = true
                    case 2:
                        self.isPlaying = false
                    default:
                        break
                    }
                }
            case "time":
                if let cur = dict["currentTime"] as? Double {
                    self.currentTime = cur
                }
                if let dur = dict["duration"] as? Double, dur > 0 {
                    self.duration = dur
                }
            default:
                break
            }
        }
    }
}

// MARK: - YouTube Player SwiftUI View
struct YouTubePlayerView: UIViewRepresentable {
    let videoId: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = YouTubePlayerController.shared.webView
        if YouTubePlayerController.shared.currentVideoId != videoId {
            YouTubePlayerController.shared.load(videoId: videoId)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if YouTubePlayerController.shared.currentVideoId != videoId {
            YouTubePlayerController.shared.load(videoId: videoId)
        }
    }
}
