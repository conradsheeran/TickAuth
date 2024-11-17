import { Constants } from "../common/Constants"
import { TOTP } from "../view/TOTPView"

@Component
export struct HomePage {

  build() {
    Column() {
      TOTP()
    }
    .height(Constants.HOMEPAGE_SIZE)
    .width(Constants.HOMEPAGE_SIZE)
    .padding({ top: $r('app.float.HomePage_padding') })
  }
}
