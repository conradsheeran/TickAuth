/*
 * Copyright (c) 2024 Yang He
 *
 * TickAuth is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

import { UserAuth } from "../model/UserAuth"
import { Constants } from "../common/Constants"

@Component
export struct UserAuthView {
  @LocalStorageLink("login") login: boolean = false;

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