import { Constants } from "../common/Constants"
import { TOTP } from "../view/TOTPView"

@Component
export struct HomePage {
  @Link refresh: boolean;

  build() {
    Column() {
      TOTP({ refresh: this.refresh })
    }
    .height(Constants.HOMEPAGE_SIZE)
    .width(Constants.HOMEPAGE_SIZE)
    .padding({ top: $r('app.float.HomePage_padding') })
  }
}
