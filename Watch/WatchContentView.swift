import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var w: WorkoutManager

    /// Normal states are obvious from the number and the button; only surface problems.
    private var statusText: String? {
        ["Sending HR…", "Ready", "Stopped"].contains(w.status) ? nil : w.status
    }

    var body: some View {
        VStack(spacing: 8) {
            reading
            receiversRow
            messages
            toggleButton
        }
    }

    // MARK: Pieces

    private var reading: some View {
        HStack(spacing: 6) {
            Text(w.heartRate > 0 ? "\(w.heartRate)" : "--")
                .font(.system(size: 56, weight: w.heartRate > 0 ? .bold : .regular, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(w.heartRate > 0 ? Color.red : Color.red.opacity(0.45))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Image(systemName: "heart.fill")
                .font(.system(size: 22))
                .foregroundStyle(.red)
        }
    }

    /// Devices subscribed to the watch's heart-rate broadcast (Zwift, bike computer…).
    private var receiversRow: some View {
        HStack(spacing: 4) {
            Image(systemName: "antenna.radiowaves.left.and.right")
            Text(w.receivers > 0 ? "\(w.receivers)" : "–")
                .monospacedDigit()
                .fontWeight(.semibold)
        }
        .font(.footnote)
        .foregroundStyle(w.receivers > 0 ? Color.green : Color.secondary)
    }

    @ViewBuilder private var messages: some View {
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
    }

    private var toggleButton: some View {
        Button {
            w.running ? w.stop() : w.start()
        } label: {
            Image(systemName: w.running ? "stop.fill" : "play.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 76, height: 34)
                .background(Capsule().fill(w.running ? Color.red : Color.green))
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }
}
