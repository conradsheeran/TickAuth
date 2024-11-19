import { SettingsItemView } from "../view/SettingsItemView"

@Component
export struct Settings {

  build() {
    Column() {
      SettingsItemView()
    }
    .width('100%')
    .height("100%")
    .padding({top: 36})
  }
}
