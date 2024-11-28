import { Constants } from "../common/Constants"
import { TOTP } from "../view/TOTPView"

@Component
export struct HomePage {
  @Link onForeground: boolean;
  @Link refresh: boolean;

  build() {
    Column() {
      if (this.onForeground || this.refresh) {
        TOTP({ refresh: this.refresh, onForeground: this.onForeground })
      } else {
        TOTP({ refresh: this.refresh, onForeground: this.onForeground })
      }
    }
    .height(Constants.HOMEPAGE_SIZE)
    .width(Constants.HOMEPAGE_SIZE)
    .padding({ top: $r('app.float.HomePage_padding') })
  }
}
