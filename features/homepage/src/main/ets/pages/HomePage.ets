import { TOTP } from "../view/TOTPView"

@Component
export struct HomePage {

  build() {
    Column() {
      TOTP()
    }
    .height("100%")
    .width("100%")
    .padding({ top: 18 })
  }
}
