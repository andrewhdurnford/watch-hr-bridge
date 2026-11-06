import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var w: WorkoutManager

    /// "Sending HR…" is obvious from the number itself; only surface other states.
    private var statusText: String? {
        w.status == "Sending HR…" ? nil : w.status
    }

    var body: some View {
        VStack(spacing: 4) {
            VStack(spacing: -2) {
                Text(w.heartRate > 0 ? "\(w.heartRate)" : "--")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.red)
                    .minimumScaleFactor(0.6)
                Text("BPM")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            // Receivers = devices subscribed to the watch's heart-rate broadcast (Zwift, bike computer…).
            HStack(spacing: 4) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                Text(w.receivers > 0 ? "\(w.receivers)" : "–")
                    .monospacedDigit()
                    .fontWeight(.semibold)
            }
            .font(.footnote)
            .foregroundStyle(w.receivers > 0 ? Color.green : Color.secondary)

            if !w.bleStatus.isEmpty {
                Text(w.bleStatus)
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }

            if let statusText {
                Text(statusText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                w.running ? w.stop() : w.start()
            } label: {
                Image(systemName: w.running ? "stop.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 56, height: 28)
            }
            .tint(w.running ? .red : .green)
            .buttonBorderShape(.capsule)
            .padding(.top, 2)
        }
    }
}
