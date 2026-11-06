import SwiftUI

/// Three things only: heart rate, receiver/signal indicator, start/stop.
/// Every row has a fixed height so nothing moves when values change. Problems
/// appear as a one-time alert (and an orange signal icon), never as inline text.
struct WatchContentView: View {
    @EnvironmentObject var w: WorkoutManager

    var body: some View {
        VStack(spacing: 10) {
            reading
            signal
            toggleButton
        }
        .alert("HR Bridge",
               isPresented: Binding(get: { w.alertMessage != nil },
                                    set: { if !$0 { w.alertMessage = nil } }),
               actions: { Button("OK", role: .cancel) {} },
               message: { Text(w.alertMessage ?? "") })
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
        .frame(height: 64)
    }

    /// Devices subscribed to the watch's heart-rate broadcast (Zwift, bike computer…).
    private var signal: some View {
        HStack(spacing: 4) {
            Image(systemName: w.bleProblem ? "antenna.radiowaves.left.and.right.slash"
                                           : "antenna.radiowaves.left.and.right")
            Text(w.receivers > 0 ? "\(w.receivers)" : "–")
                .monospacedDigit()
                .fontWeight(.semibold)
        }
        .font(.footnote)
        .foregroundStyle(w.bleProblem ? Color.orange : (w.receivers > 0 ? Color.green : Color.secondary))
        .frame(height: 20)
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
    }
}
