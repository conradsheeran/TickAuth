import { UserAuth } from "../model/UserAuth"
import { Constants } from "../common/Constants"

@Component
export struct UserAuthView {
  @StorageLink("login") login: boolean = false;

  build() {
    Column() {
      Image($r("app.media.app_icon_startwindow"))
        .width($r('app.float.UserAuthView_Image_size'))
        .height($r('app.float.UserAuthView_Image_size'))
        .margin({ top: Constants.USERAUTHVIEW_ITEM_MARGIN })


      Button($r('app.string.UserAuthView_button'))
        .margin({ top: Constants.USERAUTHVIEW_ITEM_MARGIN })
        .backgroundColor($r('app.color.UserAuthView_button'))
        .onClick(() => {
          UserAuth().then((result) => {
            if (result === 12500000) {
              this.login = true
            }
          })
        })
    }
    .width(Constants.USERAUTHVIEW_SIZE)
    .height(Constants.USERAUTHVIEW_SIZE)
    .backgroundColor($r('app.color.background'))
    .justifyContent(FlexAlign.Center)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}