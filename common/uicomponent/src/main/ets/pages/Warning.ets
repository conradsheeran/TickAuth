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
import { promptAction } from "@kit.ArkUI";
import { Constants } from "../common/Constants";

const TAG: string = "CustomDialog_Warning";

@CustomDialog
export struct CustomDialog_Warning {
  controller: CustomDialogController = new CustomDialogController({ builder: "" });
  cancel: Function = () => {};
  confirm: Function = () => {};

  @Prop symbol: Resource;
  @Prop symbolColor: ResourceStr;
  @Prop title: string;
  @Prop content: string;
  @Prop contentSpan: string;
  @Prop retryContent: string;
  @Prop confirmButtonFontColor: Resource;
  @Prop cancelButtonFontColor: Resource;

  private isConfirm: boolean = false;

  build() {
    Column() {
      Text() {
        SymbolSpan(this.symbol)
          .fontColor([this.symbolColor])
        Span(" ")
        Span(this.title)
      }
        .fontSize($r('app.float.CustomDialog_Warning_Title_fontsize'))
        .textAlign(TextAlign.Start)
        .margin({top: Constants.CUSTOMDIALOG_WARNING_TITLE_MARGIN})
        .width(Constants.CUSTOMDIALOG_WARNING_TEXT_WIDTH)

      TextInput({ placeholder: "请输入 " + this.content + " 以" + this.contentSpan })
        .margin({ top: $r('app.float.CustomDialog_Warning_TextInput_margin') })
        .enterKeyType(EnterKeyType.Done)
        .onChange((input)=>{
          if (input === this.content) {
            this.isConfirm = true
          }
          hilog.debug(Constants.DOMAIN, TAG, "TextInput: %{public}s", input)
        })
        .width(Constants.CUSTOMDIALOG_WARNING_TEXT_WIDTH)


      Blank()

      Row() {
        Button("确定", {type: ButtonType.Normal})
          .onClick(async () => {
            if (this.controller != undefined && this.isConfirm) {
              this.controller.close()
              this.confirm()
            } else if (!this.isConfirm) {
              promptAction.showToast({
                message: this.retryContent,
                duration: 1500
              });
            }
          })
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .fontColor(this.confirmButtonFontColor)
          .borderRadius($r('app.float.BorderRadius'))
          .margin({ bottom: $r('app.float.CustomDialog_Warning_Button_margin'), right: $r('app.float.CustomDialog_Warning_Button_margin') })
          .width(Constants.CUSTOMDIALOG_WARNING_BUTTON_WIDTH)

        Button("取消", {type: ButtonType.Normal})
          .onClick(() => {
            this.controller.close();
            this.cancel();
          })
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .fontColor(this.cancelButtonFontColor)
          .borderRadius($r('app.float.BorderRadius'))
          .margin({ bottom: $r('app.float.CustomDialog_Warning_Button_margin'), left: $r('app.float.CustomDialog_Warning_Button_margin') })
          .width(Constants.CUSTOMDIALOG_WARNING_BUTTON_WIDTH)
      }
      .width(Constants.CUSTOMDIALOG_WARNING_BUTTON_TOTAL_WIDTH)
      .padding({ bottom: $r('app.float.CustomDialog_Warning_Button_padding') })
      .justifyContent(FlexAlign.Center)
      .margin({ top: Constants.CUSTOMDIALOG_WARNING_BUTTON_TOTAL_MARGIN })
    }
    .height(Constants.CUSTOMDIALOG_WARNING_HEIGHT)
    .width(Constants.CUSTOMDIALOG_WARNING_WIDTH)
    .borderRadius($r('app.float.BorderRadius'))
    .backgroundColor($r('app.color.background'))
  }
}