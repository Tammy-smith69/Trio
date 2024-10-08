import Foundation

extension DataTable {
    final class Provider: BaseProvider, DataTableProvider {
        @Injected() var pumpHistoryStorage: PumpHistoryStorage!
        @Injected() var tempTargetsStorage: TempTargetsStorage!
        @Injected() var glucoseStorage: GlucoseStorage!
        @Injected() var carbsStorage: CarbsStorage!
        @Injected() var nightscoutManager: NightscoutManager!
        @Injected() var healthkitManager: HealthKitManager!
        @Injected() var tidepoolManager: TidepoolManager!

        func pumpHistory() -> [PumpHistoryEvent] {
            pumpHistoryStorage.recent()
        }

        func pumpSettings() -> PumpSettings {
            storage.retrieve(OpenAPS.Settings.settings, as: PumpSettings.self)
                ?? PumpSettings(from: OpenAPS.defaults(for: OpenAPS.Settings.settings))
                ?? PumpSettings(insulinActionCurve: 6, maxBolus: 10, maxBasal: 2)
        }

        func tempTargets() -> [TempTarget] {
            tempTargetsStorage.recent()
        }

        func carbs() -> [CarbsEntry] {
            carbsStorage.recent()
        }

        func fpus() -> [CarbsEntry] {
            carbsStorage.recent()
        }

        func deleteCarbs(_ treatement: Treatment) {
            // need to start with tidepool because Nightscout delete data
            // probably to revise the logic
            // TODO:
            tidepoolManager.deleteCarbs(
                at: treatement.date,
                isFPU: treatement.isFPU,
                fpuID: treatement.fpuID,
                syncID: treatement.id
            )

            nightscoutManager.deleteCarbs(
                at: treatement.date,
                isFPU: treatement.isFPU,
                fpuID: treatement.fpuID,
                syncID: treatement.id
            )
        }

        func deleteInsulin(_ treatement: Treatment) {
            // delete tidepoolManager before NS - TODO
            tidepoolManager.deleteInsulin(at: treatement.date)
            nightscoutManager.deleteInsulin(at: treatement.date)
            if let id = treatement.idPumpEvent {
                healthkitManager.deleteInsulin(syncID: id)
            }
        }

        func glucose() -> [BloodGlucose] {
            glucoseStorage.recent().sorted { $0.date > $1.date }
        }

        func deleteGlucose(id: String) {
            glucoseStorage.removeGlucose(ids: [id])
            healthkitManager.deleteGlucose(syncID: id)
        }
    }
}
