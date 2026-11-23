import CarPlay
import UIKit

final class NovaCarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        interfaceController.setRootTemplate(makeProfilesTemplate(), animated: true, completion: nil)
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController) {
        self.interfaceController = nil
    }

    private func makeProfilesTemplate() -> CPListTemplate {
        let items = EQPreset.all.map { preset -> CPListItem in
            let item = CPListItem(text: preset.name, detailText: preset.subtitle)
            item.handler = { _, completion in
                Task { @MainActor in
                    DSPAudioEngine.shared.applyPreset(preset)
                    completion()
                }
            }
            return item
        }
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "NOVA DSP Profiles", sections: [section])
        template.tabTitle = "NOVA DSP"
        template.tabImage = UIImage(systemName: "waveform")
        return template
    }
}
