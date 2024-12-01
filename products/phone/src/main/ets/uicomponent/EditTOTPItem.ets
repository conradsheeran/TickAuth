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

import { hilog } from "@kit.PerformanceAnalysisKit";
import { Logger } from "utils";
import { Constants } from "../common/Constants";

const TAG: string = "CustomDialog_editTOTPItem";
const logger = new Logger(getContext(this))

@CustomDialog
export struct CustomDialog_editTOTPItem {
  controller: CustomDialogController = new CustomDialogController({builder: ""});
  cancel: Function = () => {};
  confirm: Function = () => {};

  @Link alias: string

  build() {
    Column() {
      Text("请输入账户别名")
        .fontSize(20)
        .textAlign(TextAlign.Start)
        .margin({top: '10%'})
        .width('90%')

      TextInput({ placeholder: '该别名将用于为您区分不同的验证码' })
        .margin({ top: 24 })
        .enterKeyType(EnterKeyType.Done)
        .onChange((input)=>{
          this.alias = input
          hilog.debug(Constants.DOMAIN, TAG, "The Input value: %{public}s", input)
        })
        .width("88%")


      Blank()

      Row() {
        Button("确定", {type: ButtonType.Normal})
          .onClick(async () => {
            if (this.controller != undefined) {
              this.controller.close()
              this.confirm()
            }
          })
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .fontColor($r("sys.color.brand_font"))
          .borderRadius($r('app.float.BorderRadius'))
          .margin({ bottom: 12, right: 12 })
          .width("40%")

        Button("取消", {type: ButtonType.Normal})
          .onClick(() => {
            this.controller.close();
            this.cancel();
            hilog.info(Constants.DOMAIN, TAG, "The CANCEL button was clicked")
          })
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .fontColor($r("sys.color.brand_font"))
          .borderRadius($r('app.float.BorderRadius'))
          .margin({ bottom: 12, left: 12 })
          .width("40%")
      }
      .width("100%")
      .padding({ bottom: 8 })
      .justifyContent(FlexAlign.Center)
      .margin({ top: "8%" })
    }
    .height('30%')
    .width('96%')
    .borderRadius($r('app.float.BorderRadius'))
    .backgroundColor("#f1f0ed")
  }
}