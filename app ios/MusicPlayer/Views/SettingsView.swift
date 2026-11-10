import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    settingsHeader

                    // Audio Settings
                    settingsSection("Audio") {
                        // Audio Quality
                        settingsRow(icon: "waveform", title: "Audio Quality") {
                            Picker("", selection: $settingsVM.audioQuality) {
                                ForEach(AudioQuality.allCases, id: \.self) { quality in
                                    Text(quality.rawValue).tag(quality)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(AppTheme.accentColor)
                        }

                        Divider().background(AppTheme.elevatedColor)

                        // Normalize Audio
                        settingsToggle(icon: "speaker.wave.2", title: "Normalize Audio",
                                      subtitle: "Set the same volume level for all songs",
                                      isOn: $settingsVM.normalizeAudio)

                        Divider().background(AppTheme.elevatedColor)

                        // Crossfade
                        settingsToggle(icon: "arrow.left.arrow.right", title: "Crossfade",
                                      subtitle: "Smooth transition between songs",
                                      isOn: $settingsVM.crossfadeEnabled)

                        if settingsVM.crossfadeEnabled {
                            HStack {
                                Text("\(Int(settingsVM.crossfadeDuration))s")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                                Slider(value: $settingsVM.crossfadeDuration, in: 1...12, step: 1)
                                    .tint(AppTheme.accentColor)
                                Text("12s")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }

                        Divider().background(AppTheme.elevatedColor)

                        // Equalizer
                        NavigationLink(destination: EqualizerView()) {
                            settingsNavRow(icon: "slider.horizontal.3", title: "Equalizer",
                                          subtitle: "Adjust audio frequencies")
                        }
                    }

                    // Music Sources
                    settingsSection("Music Sources") {
                        ForEach(MusicSource.allCases) { source in
                            settingsToggle(
                                icon: source.icon,
                                title: source.rawValue,
                                subtitle: nil,
                                isOn: Binding(
                                    get: { settingsVM.enabledSources.contains(source) },
                                    set: { _ in settingsVM.toggleSource(source) }
                                ),
                                tintColor: Color(hex: source.color)
                            )
                            if source != MusicSource.allCases.last {
                                Divider().background(AppTheme.elevatedColor)
                            }
                        }
                    }

                    // Playback
                    settingsSection("Playback") {
                        settingsToggle(icon: "text.quote", title: "Show Lyrics",
                                      subtitle: "Show lyrics automatically when available",
                                      isOn: $settingsVM.showLyricsAutomatically)
                    }

                    // Downloads
                    settingsSection("Downloads") {
                        settingsToggle(icon: "wifi", title: "Download over Wi-Fi only",
                                      subtitle: "Saves mobile data",
                                      isOn: $settingsVM.downloadOverWifiOnly)
                    }

                    // API Keys
                    settingsSection("API Configuration") {
                        apiKeyField(title: "Jamendo Client ID", text: $settingsVM.jamendoClientId)
                        Divider().background(AppTheme.elevatedColor)
                        apiKeyField(title: "Last.fm API Key", text: $settingsVM.lastfmApiKey)
                        Divider().background(AppTheme.elevatedColor)
                        apiKeyField(title: "YouTube API Key", text: $settingsVM.youtubeApiKey)
                        Divider().background(AppTheme.elevatedColor)
                        apiKeyField(title: "SoundCloud Client ID", text: $settingsVM.soundcloudClientId)
                    }

                    // Storage
                    settingsSection("Storage") {
                        HStack {
                            Image(systemName: "internaldrive")
                                .foregroundColor(AppTheme.accentColor)
                                .frame(width: 24)
                            VStack(alignment: .leading) {
                                Text("Cache Size")
                                    .foregroundColor(AppTheme.primaryText)
                                Text(settingsVM.cacheSize)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            Spacer()
                            Button("Clear") {
                                settingsVM.clearCache()
                            }
                            .font(.subheadline)
                            .foregroundColor(AppTheme.accentColor)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    // About
                    settingsSection("About") {
                        settingsInfoRow(title: "Version", value: "1.0.0")
                        Divider().background(AppTheme.elevatedColor)
                        settingsInfoRow(title: "Build", value: "2024.1")
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
            .background(AppTheme.backgroundColor.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header
    private var settingsHeader: some View {
        HStack {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
            Spacer()
        }
        .padding(.top)
    }

    // MARK: - Section
    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.secondaryText)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .background(AppTheme.cardColor)
            .cornerRadius(12)
        }
    }

    // MARK: - Settings Row
    private func settingsRow<Content: View>(icon: String, title: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 24)
            Text(title)
                .foregroundColor(AppTheme.primaryText)
            Spacer()
            trailing()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Settings Toggle
    private func settingsToggle(icon: String, title: String, subtitle: String?, isOn: Binding<Bool>, tintColor: Color = AppTheme.accentColor) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(tintColor)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(AppTheme.primaryText)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            Spacer()
            Toggle("", isOn: isOn)
                .tint(AppTheme.accentColor)
                .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Navigation Row
    private func settingsNavRow(icon: String, title: String, subtitle: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(AppTheme.primaryText)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.tertiaryText)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Info Row
    private func settingsInfoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(AppTheme.primaryText)
            Spacer()
            Text(value)
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - API Key Field
    private func apiKeyField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            SecureField("Enter API Key", text: text)
                .font(.subheadline)
                .foregroundColor(AppTheme.primaryText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
