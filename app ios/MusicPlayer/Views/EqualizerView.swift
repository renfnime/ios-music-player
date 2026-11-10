import SwiftUI

struct EqualizerView: View {
    @EnvironmentObject var playerVM: PlayerViewModel

    let frequencyLabels = ["32", "64", "125", "250", "500", "1K", "2K", "4K", "8K", "16K"]

    var body: some View {
        VStack(spacing: 24) {
            // Preset Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(EqualizerPreset.allPresets) { preset in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                playerVM.setEQPreset(preset)
                            }
                        }) {
                            Text(preset.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    playerVM.currentEQPreset.id == preset.id ?
                                    AppTheme.accentColor : AppTheme.cardColor
                                )
                                .foregroundColor(
                                    playerVM.currentEQPreset.id == preset.id ?
                                    .white : AppTheme.secondaryText
                                )
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }

            // EQ Bands
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<10, id: \.self) { index in
                    VStack(spacing: 8) {
                        // dB value
                        Text(String(format: "%.0f", playerVM.customBands[index]))
                            .font(.system(size: 9))
                            .foregroundColor(AppTheme.secondaryText)

                        // Slider
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.elevatedColor)
                                .frame(width: 6)

                            GeometryReader { geo in
                                let normalizedValue = CGFloat((playerVM.customBands[index] + 12) / 24)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.accentColor, AppTheme.accentColor.opacity(0.3)],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(width: 6, height: geo.size.height * normalizedValue)
                                    .frame(maxHeight: .infinity, alignment: .bottom)
                            }
                            .frame(width: 6)

                            // Thumb
                            GeometryReader { geo in
                                let normalizedValue = CGFloat((playerVM.customBands[index] + 12) / 24)
                                Circle()
                                    .fill(AppTheme.accentColor)
                                    .frame(width: 16, height: 16)
                                    .shadow(color: AppTheme.accentColor.opacity(0.5), radius: 4)
                                    .position(
                                        x: geo.size.width / 2,
                                        y: geo.size.height * (1 - normalizedValue)
                                    )
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                let normalizedY = 1 - (value.location.y / geo.size.height)
                                                let clampedY = max(0, min(1, normalizedY))
                                                let dbValue = Float(clampedY * 24 - 12)
                                                playerVM.setCustomBand(index: index, value: dbValue)
                                            }
                                    )
                            }
                        }
                        .frame(height: 200)

                        // Frequency label
                        Text(frequencyLabels[index])
                            .font(.system(size: 9))
                            .foregroundColor(AppTheme.tertiaryText)
                    }
                }
            }
            .padding(.horizontal, 20)

            // dB scale reference
            HStack {
                Text("+12 dB")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.tertiaryText)
                Spacer()
                Text("0 dB")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.tertiaryText)
                Spacer()
                Text("-12 dB")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.tertiaryText)
            }
            .padding(.horizontal, 20)

            // Reset Button
            Button(action: {
                withAnimation {
                    playerVM.setEQPreset(.flat)
                }
            }) {
                Text("Reset to Flat")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(AppTheme.cardColor)
                    .cornerRadius(20)
            }

            Spacer()
        }
        .padding(.top)
        .background(AppTheme.backgroundColor.ignoresSafeArea())
        .navigationTitle("Equalizer")
        .navigationBarTitleDisplayMode(.inline)
    }
}
