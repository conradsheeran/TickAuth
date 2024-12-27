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

import { Constants } from "../common/Constants";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { Logger, WriteToJson, CatchSecretByScan } from "utils";
import { CustomDialog_editSecret } from "uicomponent"
import { common } from "@kit.AbilityKit";
import { promptAction, SelectDialog } from "@kit.ArkUI";

const TAG: string = "NoKeyInJSON"
const logger = new Logger(getContext(this))

@Component
export struct NoKeyInJSON {
  @State alias: string = "";
  @State secret: string = "";
  @State digit: number = 6;
  @State timeStep: number = 30;
  @State algorithm: string = "SHA1";
  @State rawSecretParam: string = "";
  @Link hasKey: boolean;
  @State isConfirm: boolean = false;
  @State CustomDialog_editTOTPItemIsClosed: boolean = false;
  @Consume("pathStack") pathStack: NavPathStack;

  dialogControllerList: CustomDialogController = new CustomDialogController({
    builder: SelectDialog({
      title: '请选择一种添加方式',
      selectedIndex: 3,
      confirm: {
        value: '取消',
        action: () => {
          hilog.debug(Constants.DOMAIN, TAG, "dialogControllerList: CANCEL button has been clicked.")
        },
      },
      radioContent: [
        {
          title: '扫码添加',
          action: async () => {
            try {
              hilog.info(Constants.DOMAIN, TAG, "The ADD button was clicked")
              CatchSecretByScan(this.context).then((value) => {
                this.rawSecretParam = value.raw
                const secretParam = value.SecretParams;
                this.secret = secretParam.secret;
                this.digit = secretParam.digits;
                this.algorithm = secretParam.algorithm;
                this.timeStep = secretParam.period;

                hilog.info(Constants.DOMAIN, TAG, "The SECRET accepted: %{private}s", String(this.alias))

                this.editTOTPItem.open()
                hilog.info(Constants.DOMAIN, TAG, "The editTOTPItem DIALOG opened")
              })

              // 等待用户输入
              while (!this.CustomDialog_editTOTPItemIsClosed) {
                await new Promise<void>(resolve => setTimeout(resolve, 100));
              }

              if (this.isConfirm) {
                hilog.debug(Constants.DOMAIN, TAG, "The edited alias is %{public}s", this.alias)

                await this.writeToJson.write({
                  type: "normal",
                  alias: this.alias,
                  secret: this.secret,
                  digit: this.digit,
                  timeStep: this.timeStep,
                  algorithm: this.algorithm,
                  raw: this.rawSecretParam
                });
                hilog.debug(Constants.DOMAIN, TAG, "WriteToJson completed", this.alias)

                this.hasKey = true;
                this.CustomDialog_editTOTPItemIsClosed = false
                logger.info(Constants.DOMAIN, TAG, "The SECRET(%{public}s) has been added", this.alias)
              }
            } catch (e) {
              promptAction.showToast({
                message: `错误：${e.message} (${TAG})`,
                duration: 2000
              });
              logger.error(Constants.DOMAIN, TAG, "ADD button: %{public}s", String(e));
            }
          }
        },
        {
          title: '手动输入 TOTP 验证码参数',
          action: () => {
            this.newTOTPItem.open()
          }
        },
        {
          title: '添加 Steam 手机令牌',
          action: () => {
            try {
              this.pathStack.pushPath({ name: "SteamPage" })
            } catch (e) {
              promptAction.showToast({
                message: `错误：${e.message} (${TAG})`,
                duration: 2000
              });
              logger.error(Constants.DOMAIN, TAG, "pushPath(SteamPage) Fatal: %{public}s code: {public}d", e.message, e.code)
            }
          }
        }
      ]
    })
  })

  newTOTPItem: CustomDialogController = new CustomDialogController({
    builder: CustomDialog_editSecret(
      {
        cancel: () => {
          this.hasKey = false;
        },

        confirm: async () => {
          this.hasKey = true
        },

        symbol: $r('sys.symbol.plus_square_on_square'),
        symbolColor: $r('sys.color.font_primary'),
        title: "请输入 TOTP 验证码参数",
        content: "请输入您的账户别名",
        retryContent: "请勿使用相同的账户别名",
        confirmButtonFontColor: $r("sys.color.warning"),
        cancelButtonFontColor: $r("sys.color.brand_font"),
        mode: "new",

        contentSecret: "请输入您的的密钥",

        alias: $alias
      }),

    customStyle: true,

    onWillDismiss:(dismissDialogAction: DismissDialogAction)=> {
      hilog.debug(Constants.DOMAIN, TAG, "editTOTPItem: User try to exit. Action: %{public}s", dismissDialogAction.reason.toString())
    }
  });

  private context = getContext(this) as common.UIAbilityContext;
  private writeToJson = new WriteToJson(this.context.filesDir + Constants.SECRET_FILE_DIR)

  editTOTPItem: CustomDialogController = new CustomDialogController({
    builder: CustomDialog_editSecret(
      {
        cancel: () => {
          this.isConfirm = false;
          this.CustomDialog_editTOTPItemIsClosed = false
        },

        confirm: () => {
          this.isConfirm = true
          this.CustomDialog_editTOTPItemIsClosed = true
        },

        symbol: $r('sys.symbol.square_and_pencil'),
        symbolColor: $r('sys.color.font_primary'),
        title: "请输入您的账户别名",
        content: "该别名将用于为您区分不同的验证码",
        retryContent: "请勿使用相同的账户别名",
        confirmButtonFontColor: $r("sys.color.warning"),
        cancelButtonFontColor: $r("sys.color.brand_font"),
        mode: "edit",

        alias: $alias
      }),

    customStyle: true,
  });

  build() {
    Row() {
      Column() {
        Image($r('app.media.plus_square'))
          .size({ height: $r('app.float.NoKeyInJSON_Image_size'), width: $r('app.float.NoKeyInJSON_Image_size') })
          .margin({ bottom: Constants.NOKEYINJSON_IMAGE_MARGIN })
          .onClick(() => {
            this.dialogControllerList.open()
          })

        Text($r('app.string.NoKeyInJSON_content'))
          .fontSize($r('app.float.NoKeyInJSON_fontsize'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.NoKeyInJSON_fontcolor'))
      }
      .width(Constants.HOMEPAGE_SIZE)
    }
    .height(Constants.HOMEPAGE_SIZE)
  }
}
