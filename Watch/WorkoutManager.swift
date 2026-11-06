import Foundation
import HealthKit

/// Runs an indoor-cycling workout session so watchOS streams heart rate
/// continuously (about once a second), and broadcasts each sample over BLE.
final class WorkoutManager: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    @Published var heartRate: Int = 0
    @Published var running = false
    @Published var receivers = 0
    /// Bluetooth is unavailable or errored (the signal icon turns orange).
    @Published var bleProblem = false
    /// One-time message shown as an alert. Never shown inline, so the layout never moves.
    @Published var alertMessage: String?

    private let ble = WatchBroadcaster()
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var resendTimer: Timer?

    private let hrType = HKQuantityType(.heartRate)
    private let hrUnit = HKUnit.count().unitDivided(by: .minute())

    override init() {
        super.init()
        ble.onStatus = { [weak self] msg in
            self?.bleProblem = !msg.isEmpty
            if !msg.isEmpty { self?.alertMessage = msg }
        }
        ble.onReceivers = { [weak self] in self?.receivers = $0 }
        #if DEBUG
        // Sample state for App Store screenshots in the simulator (no sensor there).
        if CommandLine.arguments.contains("-screenshot-running") {
            heartRate = 142; running = true; receivers = 1
        }
        #endif
    }

    func start() {
        guard HKHealthStore.isHealthDataAvailable() else {
            alertMessage = "Health data isn't available on this watch."
            return
        }
        let share: Set<HKSampleType> = [HKObjectType.workoutType()]
        let read: Set<HKObjectType> = [hrType]
        store.requestAuthorization(toShare: share, read: read) { [weak self] ok, error in
            DispatchQueue.main.async {
                guard let self else { return }
                // `ok` only says the prompt finished. Tapping "Don't Allow" shows up as a denied share status.
                let denied = self.store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingDenied
                if ok && !denied { self.beginSession() } else { self.alertMessage = Self.healthDeniedMessage }
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
                    if !ok { self?.alertMessage = Self.message(for: error) }
                }
            }
            ble.start()
            // Re-notify the last value every 2 s so receivers never see a gap between samples.
            resendTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                guard let self, self.heartRate > 0 else { return }
                self.ble.sendBPM(self.heartRate)
            }
        } catch {
            alertMessage = Self.message(for: error)
        }
    }

    func stop() {
        resendTimer?.invalidate(); resendTimer = nil
        session?.end()
        ble.stop()
    }

    // MARK: Messages

    private static let healthDeniedMessage =
        "Allow Health access for HR Bridge: on your iPhone open Health, tap your picture, then Apps, then HR Bridge."

    private static func message(for error: Error?) -> String {
        guard let error else { return "Couldn't start the workout." }
        let e = error as NSError
        if e.domain == HKError.errorDomain,
           e.code == HKError.errorAuthorizationDenied.rawValue || e.code == HKError.errorAuthorizationNotDetermined.rawValue {
            return healthDeniedMessage
        }
        return error.localizedDescription
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
                    self?.session = nil
                    self?.builder = nil                }
            }
        }
    }

    func workoutSession(_ s: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async { self.alertMessage = Self.message(for: error) }
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
