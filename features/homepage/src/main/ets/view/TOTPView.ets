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

import { fileIo as fs } from "@kit.CoreFileKit"
import { buffer } from '@kit.ArkTS';
import { SecretClass, WaitDeleteItemParam } from "../model/TOTPModel"
import { BusinessError, pasteboard } from "@kit.BasicServicesKit";
import { bufferToString, Logger, Preference, ISecretItem, WriteToJson } from "utils"
import { GenerateTOTP, GetTOTPTimeInfo } from "totp"
import { Constants } from "../common/Constants";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { promptAction } from "@kit.ArkUI";
import { CustomDialog_editSecret, CustomDialog_Warning } from "uicomponent"
import { preferences } from "@kit.ArkData";
import { pinyin4js as pinyin } from "@ohos/pinyin4js"

const TAG: string = "TOTPView";
const logger = new Logger(getContext(this))

@Component
export struct TOTP {
  @LocalStorageLink("hasKey") hasKey: boolean = false;
  @Link refresh: boolean;
  @Link onForeground: boolean;
  @State TOTPList: Array<SecretClass> = [];
  @State CustomDialog_editTOTPItem_IsClosed: boolean = false;
  @State editTOTPItem_alias: string = '';
  @State editTOTPItem_secret: string = '';
  @State editTOTPItem_item: ISecretItem = { type: "normal", alias: "", secret: "", digit: 6, timeStep: 30, algorithm: "SHA1", raw: "" }

  private writeToJson = new WriteToJson(getContext(this).filesDir + Constants.SECRET_FILE_DIR)
  private preferences = new Preference(getContext(this), "Preferences");
  private oldPined: Array<string> = [];
  private deleteAlias: string = "";
  private oldDeleteItem: Array<WaitDeleteItemParam> = []

  // 弹窗控制器
  editTOTPItem: CustomDialogController = new CustomDialogController({
    builder: CustomDialog_editSecret(
      {
        cancel: () => {
          this.CustomDialog_editTOTPItem_IsClosed = true
        },

        confirm: () => {
          this.writeToJson.edit(this.editTOTPItem_item, {
            type: "normal",
            alias: this.editTOTPItem_alias,
            secret: this.editTOTPItem_item.secret,
            digit: this.editTOTPItem_item.digit,
            timeStep: this.editTOTPItem_item.timeStep,
            algorithm: this.editTOTPItem_item.algorithm,
            raw: this.editTOTPItem_item.raw
          })
          this.refresh = true;
          this.CustomDialog_editTOTPItem_IsClosed = true
        },

        symbol: $r('sys.symbol.square_and_pencil'),
        symbolColor: $r('sys.color.font_primary'),
        title: "请输入修改后账户别名",
        content: "该别名将用于为您区分不同的验证码",
        retryContent: "请勿使用相同的账户别名",
        confirmButtonFontColor: $r("sys.color.warning"),
        cancelButtonFontColor: $r("sys.color.brand_font"),
        mode: "edit",

        alias: $editTOTPItem_alias
      }),

    customStyle: true,
  });

  warningDelete: CustomDialogController = new CustomDialogController({
    builder: CustomDialog_Warning(
      {
        cancel: () => {
          hilog.info(Constants.DOMAIN, TAG, "warningDelete: The CANCEL button has been clicked");
        },

        confirm: () => {
          hilog.info(Constants.DOMAIN, TAG, "warningDelete: The Confirm button has been clicked")

          try {
            if (!this.oldDeleteItem.length) {
              this.preferences.put("WaitDeleteAlias", [new WaitDeleteItemParam(this.deleteAlias, Date.now())])
              this.refresh = true
            } else {
              let newDeleteItem: Array<WaitDeleteItemParam> = [...this.oldDeleteItem, new WaitDeleteItemParam(this.deleteAlias, Date.now())];
              this.preferences.put("WaitDeleteAlias", newDeleteItem)
              this.refresh = true;
            }

            promptAction.showToast({
              message: `${this.deleteAlias} 将在 24 小时后删除`,
              duration: 2000
            });
          } catch (e) {
            promptAction.showToast({
              message: `错误：${e.message} (${TAG})`,
              duration: 2000
            });
            logger.error(Constants.DOMAIN, TAG, "warningDelete: %{public}s, %{public}d", e.message, e.code)
          }
        },

        symbol: $r("sys.symbol.exclamationmark_triangle_fill"),
        symbolColor: "#fecc11",
        title: "警告",
        content: "DELETE",
        contentSpan: "删除",
        retryContent: "请输入正确的字符",
        confirmButtonFontColor: $r("sys.color.warning"),
        cancelButtonFontColor: $r("sys.color.brand_font")
      }),

    customStyle: true,
  });

  // 生命周期
  async aboutToAppear(): Promise<void> {
    try {
      this.oldDeleteItem = await this.preferences.get("WaitDeleteAlias", []) as Array<WaitDeleteItemParam>;
      this.oldDeleteItem.forEach((value, index) => {
        if (value.time <= Date.now()) {
          this.writeToJson.remove(value.alias).then((isNull: boolean) => {
            if (!isNull) {
              this.hasKey = isNull;
            }
          })
          this.oldDeleteItem.splice(index, 1)
        }
      })
      await this.preferences.put("WaitDeleteAlias", this.oldDeleteItem)
    } catch (e) {
      logger.error(Constants.DOMAIN, TAG, "aboutToAppear: WaitDeleteAlias fatal, %{public}s", String(e))
    }

    try {
      this.GetSecretFromJson();
    } catch (e) {
      promptAction.showToast({
        message: `错误：${e.message} (${TAG})`,
        duration: 2000
      });
      logger.error(Constants.DOMAIN, TAG, "GetSecretFromJson fatal: %{public}s", String(e))
    }

    // 重置刷新控制器
    this.oldPined = await this.preferences.get("PinedAlias", []) as Array<string>;
    this.refresh = false;
    this.onForeground = false;
  }

  async GetSecretFromJson() {
    hilog.info(Constants.DOMAIN, TAG, "GetSecretFromJson Start")

    const filePath = getContext(this).filesDir + Constants.SECRET_FILE_DIR
    const fd = (await fs.open(filePath, fs.OpenMode.READ_ONLY)).fd;
    let arrayBuffer = new ArrayBuffer(12288);

    await fs.read(fd, arrayBuffer).then(async (readLen) => {
      let buf = buffer.from(arrayBuffer, 0, readLen);
      this.TOTPList = JSON.parse(bufferToString(new Uint8Array(buf.buffer)).replace(/[\u0000-\u001F\u007F-\u009F]/g, "").trim()) as SecretClass[];
      fs.close(fd);

      this.preferences.get("按字母排序", true).then((value: preferences.ValueType) => {
        if (value) {
          this.TOTPList.sort((a, b) => {
            const aLetter: string = pinyin.convertToPinyinString(a.alias, "", pinyin.FIRST_LETTER);
            const bLetter: string = pinyin.convertToPinyinString(b.alias, "", pinyin.FIRST_LETTER);

            return aLetter.localeCompare(bLetter);
          })
        }
      })

      const waitDeleteItems = await this.preferences.get("WaitDeleteAlias", []) as Array<WaitDeleteItemParam>;
      const pinedItems = await this.preferences.get("PinedAlias", []) as Array<string>;
      this.TOTPList.sort((a, b) => {
        const aWaitDeleteIndex = waitDeleteItems.findIndex(item => item.alias === a.alias);
        const bWaitDeleteIndex = waitDeleteItems.findIndex(item => item.alias === b.alias);

        if (aWaitDeleteIndex !== -1 && bWaitDeleteIndex === -1) {
          return 1;
        } else if (aWaitDeleteIndex === -1 && bWaitDeleteIndex !== -1) {
          return -1;
        } else if (aWaitDeleteIndex !== -1 && bWaitDeleteIndex !== -1) {
          return 0;
        }

        const aPinedIndex = pinedItems.indexOf(a.alias);
        const bPinedIndex = pinedItems.indexOf(b.alias);

        if (aPinedIndex === -1 && bPinedIndex !== -1) {
          return 1;
        } else if (aPinedIndex !== -1 && bPinedIndex === -1) {
          return -1;
        } else {
          return aPinedIndex - bPinedIndex;
        }
      });

      hilog.info(Constants.DOMAIN, TAG, "GetSecretFromJson Succeed")
    }).catch((e: BusinessError) => {
      fs.close(fd)
      logger.error(Constants.DOMAIN, TAG, "Read JSON file fatal: %{public}s", String(e))
    })
  }

  build() {
    Column() {
      List({ space: Constants.TOTPVIEW_LIST_SPACE }) {
        ForEach(this.TOTPList, (item: SecretClass) => {
          ListItem() {
            if (this.oldDeleteItem.some(waitDelete => waitDelete.alias === item.alias)) {
              TOTPItem({ totpItem: item })
                .borderWidth(2)
                .borderRadius($r('app.float.BorderRadius'))
                .borderColor($r('app.color.TOTPView_ListItem_deleteButton'))
            } else if (this.oldPined.some(oldPinedItem => oldPinedItem === item.alias)) {
              TOTPItem({ totpItem: item })
                .borderWidth(1)
                .borderRadius($r('app.float.BorderRadius'))
                .borderColor("#fecc11")
            } else {
              TOTPItem({ totpItem: item })
            }
          }
          .swipeAction({
            end: {
              builder: () => {
                this.itemEnd(this.TOTPList.indexOf(item), item.alias, item);
              }
            }
          });
        }, (item: SecretClass) => item.alias)
      }
      .transition(TransitionEffect.OPACITY.animation({ duration: Constants.ANIMATION_DURING }))
      .width(Constants.TOTPVIEW_LIST_SIZE)
      .height(Constants.TOTPVIEW_LIST_SIZE)
      .scrollBar(BarState.Auto)
      .padding({ left: $r('app.float.TOTPView_List_padding'), right: $r('app.float.TOTPView_List_padding') })
      .contentEndOffset(16)
    }
    .margin({ top: $r('app.float.TOTPView_List_margin') })
  }

  @Builder
  itemEnd(index: number, alias: string, item: SecretClass) {
    // 置顶按钮
    Button({ type: ButtonType.Circle }) {
      if (this.oldPined.some(item => item === alias)) {
        SymbolGlyph($r('sys.symbol.undo'))
          .fontSize($r('app.float.TOTPView_ListItem_DeleteButton_Symbol_size'))
          .fontColor([Color.White])
      } else {
        SymbolGlyph($r('sys.symbol.arrowshape_up_to_line_fill'))
          .fontSize($r('app.float.TOTPView_ListItem_DeleteButton_Symbol_size'))
          .fontColor([Color.White])
      }
    }
    .backgroundColor("#fecc11")
    .width($r("app.float.TOTPView_ListItem_Button_size"))
    .height($r("app.float.TOTPView_ListItem_Button_size"))
    .margin({ left: 16, right: $r('app.float.TOTPView_ListItem_DeleteButton_margin') })
    .onClick(async () => {
      try {
        if (!this.oldPined.length) {
          this.preferences.put("PinedAlias", [alias])
          this.refresh = true
        } else {
          if (this.oldPined.some(item => item === alias)) {
            const index = this.oldPined.indexOf(alias);
            this.oldPined.splice(index, 1)
            this.preferences.put("PinedAlias", this.oldPined)
            this.refresh = true;
          } else {
            let newPined: Array<string> = [...this.oldPined, alias];
            this.preferences.put("PinedAlias", newPined)
            this.refresh = true;
          }
        }
      } catch (e) {
        promptAction.showToast({
          message: `错误：${e.message} (${TAG})`,
          duration: 2000
        });
        logger.error(Constants.DOMAIN, TAG, "Pined: %{public}s, %{public}d", e.message, e.code)
      }
    })

    // 编辑按钮
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.square_and_pencil'))
        .fontSize($r('app.float.TOTPView_ListItem_DeleteButton_Symbol_size'))
        .fontColor([Color.White])
    }
    .backgroundColor($r('app.color.TOTPView_ListItem_editButton'))
    .width($r("app.float.TOTPView_ListItem_Button_size"))
    .height($r("app.float.TOTPView_ListItem_Button_size"))
    .margin({ left: $r('app.float.TOTPView_ListItem_EditButton_margin'), right: $r('app.float.TOTPView_ListItem_DeleteButton_margin') })
    .onClick(async () => {
      try {
        this.editTOTPItem_item = item as ISecretItem;
        this.editTOTPItem_alias = item.alias;
        this.editTOTPItem_secret = item.secret;
        this.editTOTPItem.open()
        while (!this.CustomDialog_editTOTPItem_IsClosed) {
          await new Promise<void>(resolve => setTimeout(resolve, 100));
        }
        this.CustomDialog_editTOTPItem_IsClosed = false;
      } catch (e) {
        promptAction.showToast({
          message: `错误：${e.message} (${TAG})`,
          duration: 2000
        });
        logger.error(Constants.DOMAIN, TAG, "editTOTPItem_Secret: %{public}s, %{public}d", e.message, e.code)
      }
    })

    // 删除按钮
    Button({ type: ButtonType.Circle }) {
      if (this.oldDeleteItem.some(item => item.alias === alias)) {
        SymbolGlyph($r('sys.symbol.undo'))
          .fontSize($r('app.float.TOTPView_ListItem_DeleteButton_Symbol_size'))
          .fontColor([Color.White])
      } else {
        SymbolGlyph($r('sys.symbol.trash'))
          .fontSize($r('app.float.TOTPView_ListItem_DeleteButton_Symbol_size'))
          .fontColor([Color.White])
      }
    }
    .backgroundColor($r('app.color.TOTPView_ListItem_deleteButton'))
    .width($r("app.float.TOTPView_ListItem_Button_size"))
    .height($r("app.float.TOTPView_ListItem_Button_size"))
    .margin({ left: $r('app.float.TOTPView_ListItem_DeleteButton_margin') })
    .onClick(() => {
      try {
        this.deleteAlias = alias;
        if (!(this.oldDeleteItem.some(item => item.alias === alias))) {
          this.warningDelete.open()
        } else {
          const index = this.oldDeleteItem.findIndex(item => item.alias === this.deleteAlias);
          this.oldDeleteItem.splice(index, 1)
          this.preferences.put("WaitDeleteAlias", this.oldDeleteItem)
          this.refresh = true;
        }
      } catch (e) {
        promptAction.showToast({
          message: `错误：${e.message} (${TAG})`,
          duration: 2000
        });
        logger.error(Constants.DOMAIN, TAG, "warningDelete: %{public}s, %{public}d", e.message, e.code)
      }
    })
  }
}

@Component
struct TOTPItem {
  @Prop totpItem: SecretClass;
  @State code: string = '';
  @State totalTime: number = this.totpItem.timeStep;
  @State currentRemain: number = GetTOTPTimeInfo(this.totpItem.timeStep);

  private gradientColor: LinearGradient = new LinearGradient([{ color: $r('app.color.TOTPView_ListItem_Progress_end'), offset: 0.2 },
                                                              { color: $r('app.color.TOTPView_ListItem_Progress_start'), offset: 1.0 }])

  private generateTOTP() {
    GenerateTOTP(this.totpItem.secret, this.totpItem.digit, this.totpItem.timeStep, this.totpItem.algorithm).then((result) => {
      this.code = result.code;
      hilog.info(Constants.DOMAIN, TAG, "GenerateTOTP(%{public}s) Succeed", this.totpItem.alias);
    }).catch((e: BusinessError) => {
      promptAction.showToast({
        message: `错误：${e.message} (${TAG})`,
        duration: 2000
      });
      logger.error(Constants.DOMAIN, TAG, "GenerateTOTP fatal: %{public}s", String(e));
    });
  }

  aboutToAppear(): void {
    this.generateTOTP();
    try {
      setInterval(async () => {
        this.currentRemain -= 1;
        if (this.currentRemain === 0) {
          this.currentRemain = this.totalTime;
          this.generateTOTP();
        }
      }, 1000)
    } catch (e) {
      promptAction.showToast({
        message: `错误：${e.message} (${TAG})`,
        duration: 2000
      });
      logger.error(Constants.DOMAIN, TAG, "Get the TOTP time parameter fatal: %{public}s", String(e));
    }
  }

  build() {
    Row() {
      Column() {
        Text(this.totpItem.alias)
          .height(Constants.TOTPVIEW_LISTITEM_TOTP_HEIGHT)
          .width(Constants.TOTPVIEW_LISTITEM_TOTP_WIDTH)
          .fontSize($r('app.float.TOTPView_ListItem_Alias_fontsize'))
          .textAlign(TextAlign.Start)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(Constants.TOTPVIEW_LISTITEM_MAXLINE)
          .transition(TransitionEffect.OPACITY.animation({ duration: Constants.ANIMATION_DURING }))

        Text(this.code)
          .height(Constants.TOTPVIEW_LISTITEM_TOTP_HEIGHT)
          .width(Constants.TOTPVIEW_LISTITEM_TOTP_WIDTH)
          .fontSize($r('app.float.TOTPView_ListItem_Secret_fontsize'))
          .fontColor($r('app.color.TOTPView_ListItem_fontcolor'))
          .textAlign(TextAlign.Start)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(Constants.TOTPVIEW_LISTITEM_MAXLINE)
          .margin({ bottom: $r('app.float.TOTPView_ListItem_Secret_margin') })
          .transition(TransitionEffect.OPACITY.animation({ duration: Constants.ANIMATION_DURING }))

      }
      .margin({ right: $r('app.float.TOTPView_ListItem_Text_margin') })

      Blank()

      Progress({ value: this.currentRemain, total: this.totalTime, type: ProgressType.Ring })
        .color(this.gradientColor)
        .style({ strokeWidth: $r('app.float.TOTPView_ListItem_Progress_strokeWidth'), shadow: true, enableScanEffect: true })
    }
    .width(Constants.TOTPVIEW_LISTITEM_WIDTH)
    .height(Constants.TOTPVIEW_LISTITEM_HEIGHT)
    .borderRadius($r('app.float.BorderRadius'))
    .backgroundColor(Color.White)
    .padding($r('app.float.TOTPView_ListItem_padding'))
    .alignItems(VerticalAlign.Top)
    .onClick(async () => {
      await pasteboard.getSystemPasteboard()
        .setData(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.code));

      promptAction.showToast({
        message: `验证码（${this.totpItem.alias}）已复制`,
        duration: 2000
      });
    })
  }
}