import Foundation
import HealthKit

/// Runs an indoor-cycling workout session so watchOS streams heart rate
/// continuously (about once a second), and broadcasts each sample over BLE.
final class WorkoutManager: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    @Published var heartRate: Int = 0
    @Published var running = false
    @Published var status = "Ready"
    @Published var bleStatus = ""
    @Published var receivers = 0

    private let ble = WatchBroadcaster()
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var resendTimer: Timer?

    private let hrType = HKQuantityType(.heartRate)
    private let hrUnit = HKUnit.count().unitDivided(by: .minute())

    override init() {
        super.init()
        ble.onStatus = { [weak self] in self?.bleStatus = $0 }
        ble.onReceivers = { [weak self] in self?.receivers = $0 }
        #if DEBUG
        // Sample state for App Store screenshots in the simulator (no sensor there).
        if CommandLine.arguments.contains("-screenshot-running") {
            heartRate = 142; running = true; receivers = 1; status = "Sending HR…"
        }
        #endif
    }

    func start() {
        guard HKHealthStore.isHealthDataAvailable() else { status = "Health unavailable"; return }
        status = "Requesting access…"
        let share: Set<HKSampleType> = [HKObjectType.workoutType()]
        let read: Set<HKObjectType> = [hrType]
        store.requestAuthorization(toShare: share, read: read) { [weak self] ok, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if ok { self.beginSession() } else { self.status = "Health access denied" }
            }
        }
    }

    private func beginSession() {
        let config = HKWorkoutConfiguration()
        config.activityType = .cycling
        config.locationType = .indoor
        do {
            let s = try HKWorkoutSession(healthStore: store, configuration: config)
            let b = s.associatedWorkoutBuilder()
            b.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            s.delegate = self
            b.delegate = self
            session = s
            builder = b
            let start = Date()
            s.startActivity(with: start)
            b.beginCollection(withStart: start) { [weak self] ok, error in
                DispatchQueue.main.async {
                    self?.running = ok
                    self?.status = ok ? "Sending HR…" : "Start failed: \(error?.localizedDescription ?? "?")"
                }
            }
            ble.start()
            // Re-notify the last value every 2 s so receivers never see a gap between samples.
            resendTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                guard let self, self.heartRate > 0 else { return }
                self.ble.sendBPM(self.heartRate)
            }
        } catch {
            status = "Error: \(error.localizedDescription)"
        }
    }

    func stop() {
        resendTimer?.invalidate(); resendTimer = nil
        session?.end()
        ble.stop()
    }

    // MARK: HKWorkoutSessionDelegate

    func workoutSession(_ s: HKWorkoutSession, didChangeTo to: HKWorkoutSessionState,
                        from: HKWorkoutSessionState, date: Date) {
        if to == .ended {
            builder?.endCollection(withEnd: date) { [weak self] _, _ in
                // Do not clutter Health with a fake cycling workout; Zwift/Strava record the ride.
                self?.builder?.discardWorkout()
                DispatchQueue.main.async {
                    self?.running = false
                    self?.heartRate = 0
                    self?.status = "Stopped"
                    self?.session = nil
                    self?.builder = nil
                }
            }
        }
    }

    func workoutSession(_ s: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async { self.status = "Error: \(error.localizedDescription)" }
    }

    // MARK: HKLiveWorkoutBuilderDelegate

    func workoutBuilderDidCollectEvent(_ b: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ b: HKLiveWorkoutBuilder, didCollectDataOf types: Set<HKSampleType>) {
        guard types.contains(hrType),
              let stats = b.statistics(for: hrType),
              let q = stats.mostRecentQuantity() else { return }
        let bpm = Int(q.doubleValue(for: hrUnit).rounded())
        DispatchQueue.main.async {
            self.heartRate = bpm
            self.ble.sendBPM(bpm)
        }
    }
}
