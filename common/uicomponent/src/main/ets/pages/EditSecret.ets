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
import { WriteToJson } from "utils";

const TAG: string = "CustomDialog_EditSecret";

@CustomDialog
export struct CustomDialog_editSecret {
  controller: CustomDialogController = new CustomDialogController({ builder: "" });
  cancel: Function = () => {};
  confirm: Function = () => {};

  @Prop symbol: Resource;
  @Prop symbolColor: ResourceStr | Color;
  @Prop title: string;
  @Prop content: string;
  @Prop retryContent: string;
  @Prop confirmButtonFontColor: ResourceStr | Color;
  @Prop cancelButtonFontColor: ResourceStr | Color;
  @Link alias: string;
  @Link secret: string;

  @Prop mode: string;
  @Prop titleSecret: string;
  @Prop contentSecret: string;

  private isConfirm: boolean = false;
  private writeToJson = new WriteToJson(getContext(this).filesDir + "/secret.json")

  build() {
    if (this.mode === "edit") {
      Column() {
        this.DialogContent()
      }
      .height("28%")
      .width("96%")
      .borderRadius($r('app.float.BorderRadius'))
      .backgroundColor($r('app.color.background'))
    } else if (this.mode === "new") {
      Column() {
        this.DialogContent()
      }
      .height("36%")
      .width("96%")
      .borderRadius($r('app.float.BorderRadius'))
      .backgroundColor($r('app.color.background'))
    }
  }

  @Builder
  DialogContent() {
    Text() {
      SymbolSpan(this.symbol)
        .fontColor([this.symbolColor]);
      Span(" ");
      Span(this.title);
    }
    .fontSize(20)
    .textAlign(TextAlign.Start)
    .margin({ top: Constants.CUSTOMDIALOG_WARNING_TITLE_MARGIN })
    .width(Constants.CUSTOMDIALOG_WARNING_TEXT_WIDTH)

    TextInput({ placeholder: this.content })
      .margin({ top: $r('app.float.CustomDialog_Warning_TextInput_margin') })
      .enterKeyType(EnterKeyType.Done)
      .onChange(async (input) => {
        if (this.mode === "edit") {
          hilog.debug(Constants.DOMAIN, TAG, "The Input value: %{public}s", input);
          if (!(await this.writeToJson.isExist(input))) {
            this.alias = input;
            this.isConfirm = true;
          } else {
            this.isConfirm = false
          }
        } else if (this.mode === "new") {
          if (!(await this.writeToJson.isExist(input))) {
            this.alias = input;
            this.isConfirm = true;
          } else {
            this.isConfirm = false
          }
        }
      })
      .width(Constants.CUSTOMDIALOG_WARNING_TEXT_WIDTH)

    if (this.mode === "new") {
      TextInput({ placeholder: this.contentSecret })
        .margin({ top: $r('app.float.CustomDialog_Warning_TextInput_margin') })
        .enterKeyType(EnterKeyType.Done)
        .onChange(async (input) => {
          this.secret = input;
        })
        .width(Constants.CUSTOMDIALOG_WARNING_TEXT_WIDTH);
    }

    Blank()

    Row() {
      Button("确定", { type: ButtonType.Normal })
        .onClick(async () => {
          if (this.controller != undefined && this.isConfirm) {
            this.controller.close();
            this.confirm();
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
        .margin({
          bottom: $r('app.float.CustomDialog_Warning_Button_margin'),
          right: $r('app.float.CustomDialog_Warning_Button_margin')
        })
        .width(Constants.CUSTOMDIALOG_WARNING_BUTTON_WIDTH);

      Button("取消", { type: ButtonType.Normal })
        .onClick(() => {
          this.controller.close();
          this.cancel();
        })
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .fontColor(this.cancelButtonFontColor)
        .borderRadius($r('app.float.BorderRadius'))
        .margin({
          bottom: $r('app.float.CustomDialog_Warning_Button_margin'),
          left: $r('app.float.CustomDialog_Warning_Button_margin')
        })
        .width(Constants.CUSTOMDIALOG_WARNING_BUTTON_WIDTH);
    }
    .width(Constants.CUSTOMDIALOG_WARNING_BUTTON_TOTAL_WIDTH)
    .padding({ bottom: $r('app.float.CustomDialog_Warning_Button_padding') })
    .justifyContent(FlexAlign.Center)
    .margin({ top: Constants.CUSTOMDIALOG_WARNING_BUTTON_TOTAL_MARGIN })
  }
}