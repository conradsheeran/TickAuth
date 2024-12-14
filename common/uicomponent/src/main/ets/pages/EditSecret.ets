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
import { Logger, WriteToJson } from "utils";

const TAG: string = "CustomDialog_EditSecret";
const logger = new Logger(getContext(this));

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

  @State secret: string = "";
  @State digit: number = 6;
  @State timeStep: number = 30;
  @State algorithm: string = "SHA1";

  @Prop mode: string;
  @Prop contentSecret: string;

  private isConfirm: boolean = false;
  private isConfirm_secret: boolean = true;

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
      .height("55%")
      .width("96%")
      .borderRadius($r('app.float.BorderRadius'))
      .backgroundColor($r('app.color.background'))
    } else if (this.mode === "newSteamCode") {
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
        } else if (this.mode === "new" || this.mode === "newSteamCode") {
          if (!(await this.writeToJson.isExist(input))) {
            this.alias = input;
            this.isConfirm = true;
          } else {
            this.isConfirm = false
          }
        }
      })
      .width(Constants.CUSTOMDIALOG_WARNING_TEXT_WIDTH)

    if (this.mode === "new" || this.mode === "newSteamCode") {
      TextInput({ placeholder: this.contentSecret })
        .margin({ top: $r('app.float.CustomDialog_Warning_TextInput_margin') })
        .enterKeyType(EnterKeyType.Done)
        .onChange(async (input) => {
          if (input) {
            this.secret = input;
          } else {
            this.isConfirm_secret = false
          }
        })
        .width(Constants.CUSTOMDIALOG_WARNING_TEXT_WIDTH);

      if (this.mode !== "newSteamCode") {
        Row() {
          Text("加密方式: ")
            .fontSize(16)
            .textAlign(TextAlign.Start)
            .margin({ left: 5 })

          Blank()

          Select([{ value: 'SHA1' }, { value: 'SHA256' }, { value: 'SHA512' }])
            .value("请选择您的加密方式")
            .selected(0)
            .fontColor($r('sys.color.font_primary'))
            .onSelect((index: number, value: string) => {
              this.algorithm = value
            })
        }
        .width(Constants.CUSTOMDIALOG_WARNING_TEXT_WIDTH)
        .margin({ top: 18 })

        Row() {
          Text("有效时长: ")
            .fontSize(16)
            .textAlign(TextAlign.Start)
            .padding({ left: 5 })
            .margin({ left: 5 })

          Blank()

          Row() {
            Slider({
              value: this.timeStep,
              step: 5,
              style: SliderStyle.InSet,
              direction: Axis.Horizontal,
              max: 60
            })
              .selectedColor("#4e7ca1")
              .showSteps(true)
              .onChange((value: number, mode: SliderChangeMode) => {
                this.timeStep = value
              })
            Text(this.timeStep.toFixed(0)).fontSize(14)
          }
          .width(210)
        }
        .width(Constants.CUSTOMDIALOG_WARNING_TEXT_WIDTH)
        .padding({ right: 12 })
        .margin({ top: 18, right: 10 })

        Row() {
          Text("验证码位数: ")
            .fontSize(16)
            .textAlign(TextAlign.Start)
            .padding({ left: 5 })
            .margin({ left: 5 })

          Blank()

          Row() {
            Slider({
              value: this.digit,
              step: 1,
              style: SliderStyle.InSet,
              direction: Axis.Horizontal,
              max: 8
            })
              .selectedColor("#4e7ca1")
              .showSteps(true)
              .onChange((value: number, mode: SliderChangeMode) => {
                this.digit = value
              })
            Text(this.digit.toFixed(0)).fontSize(14)
          }
          .width(210)
        }
        .width(Constants.CUSTOMDIALOG_WARNING_TEXT_WIDTH)
        .padding({ right: 12 })
        .margin({ top: 18, right: 10 })
      }
    }

    Blank()

    Row() {
      Button("确定", { type: ButtonType.Normal })
        .onClick(async () => {
          if (this.controller != undefined && this.isConfirm && this.isConfirm_secret) {
            if (this.mode === "new") {
              try {
                await this.writeToJson.write({
                  alias: this.alias,
                  secret: this.secret,
                  digit: this.digit,
                  timeStep: this.timeStep,
                  algorithm: this.algorithm,
                  raw: this.secret
                });
              } catch (e) {
                logger.error(Constants.DOMAIN, TAG, "new: %{public}s, %{public}d", e.message, e.code)
              }
            } //todo: 建议直接在弹窗写入，降低代码修改量
            this.controller.close();
            this.confirm();
          } else if (!this.isConfirm) {
            promptAction.showToast({
              message: this.retryContent,
              duration: 1500
            });
          } else if (!this.isConfirm_secret) {
            promptAction.showToast({
              message: "请输入正确的密钥",
              duration: 2000
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