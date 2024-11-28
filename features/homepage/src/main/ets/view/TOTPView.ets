import { fileIo as fs } from "@kit.CoreFileKit"
import { buffer } from '@kit.ArkTS';
import { SecretClass } from "../model/TOTPModel"
import { BusinessError, pasteboard } from "@kit.BasicServicesKit";
import { bufferToString, Logger, SecretItem, WriteToJson } from "utils"
import { GenerateTOTP, GetTOTPTimeInfo } from "totp"
import { Constants } from "../common/Constants";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { promptAction } from "@kit.ArkUI";
import { CustomDialog_editTOTPItem_Secret } from "../uicomponent/EditTOTPItem_Secret";

const TAG: string = "TOTPView";
const logger = new Logger(getContext(this))

@Component
export struct TOTP {
  @LocalStorageLink("hasKey") hasKey: boolean = false;
  @Link refresh: boolean;
  @Link onForeground: boolean;
  @State TOTPList: Array<SecretClass> = [];
  @State CustomDialog_editTOTPItem_SecretIsClosed: boolean = false;
  @State editTOTPItem_secret: SecretItem = { alias: "", secret: "" };

  private writeToJson = new WriteToJson(getContext(this).filesDir + Constants.SECRET_FILE_DIR)

  editTOTPItem_Secret: CustomDialogController = new CustomDialogController({
    builder: CustomDialog_editTOTPItem_Secret(
      {
        cancel: () => {
          this.CustomDialog_editTOTPItem_SecretIsClosed = true
        },

        confirm: () => {
          this.CustomDialog_editTOTPItem_SecretIsClosed = true
        },

        oldItem: this.editTOTPItem_secret
      }),

    customStyle: true,
  });

  aboutToAppear(): void {
    try {
      this.GetSecretFromJson();
    } catch (e) {
      logger.error(Constants.DOMAIN, TAG, "GetSecretFromJson fatal: %{public}s", String(e))
    }

    this.refresh = false;
    this.onForeground = false;
  }

  async GetSecretFromJson() {
    hilog.info(Constants.DOMAIN, TAG, "GetSecretFromJson Start")

    const filePath = getContext(this).filesDir + Constants.SECRET_FILE_DIR
    const fd = (await fs.open(filePath, fs.OpenMode.READ_ONLY)).fd;
    let arrayBuffer = new ArrayBuffer(4096);

    await fs.read(fd, arrayBuffer).then((readLen) => {
      let buf = buffer.from(arrayBuffer, 0, readLen);
      this.TOTPList = JSON.parse(bufferToString(new Uint8Array(buf.buffer)).replace(/[\u0000-\u001F\u007F-\u009F]/g, "").trim()) as SecretClass[];
      fs.close(fd);
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
            TOTPItem({ totpItem: item });
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
    }
    .margin({ top: $r('app.float.TOTPView_List_margin') })
  }

  @Builder
  itemEnd(index: number, alias: string, item: SecretClass) {
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
      this.editTOTPItem_secret = item as SecretItem;
      this.editTOTPItem_Secret.open()
      while (!this.CustomDialog_editTOTPItem_SecretIsClosed) {
        await new Promise<void>(resolve => setTimeout(resolve, 100));
      }
      this.CustomDialog_editTOTPItem_SecretIsClosed = false;
    })

    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.trash'))
        .fontSize($r('app.float.TOTPView_ListItem_DeleteButton_Symbol_size'))
        .fontColor([Color.White])
    }
    .backgroundColor($r('app.color.TOTPView_ListItem_deleteButton'))
    .width($r("app.float.TOTPView_ListItem_Button_size"))
    .height($r("app.float.TOTPView_ListItem_Button_size"))
    .margin({ left: $r('app.float.TOTPView_ListItem_DeleteButton_margin') })
    .onClick(async () => {
      this.TOTPList.splice(index, 1);
      this.writeToJson.remove(alias).then((isNull: boolean) => {
        if (!isNull) {
          this.hasKey = isNull;
        }
      })
    })
  }
}

@Component
struct TOTPItem {
  @Prop totpItem: SecretClass;
  @State code: string = '';
  @State totalTime: number = 30;
  @State currentRemain: number = GetTOTPTimeInfo();

  private gradientColor: LinearGradient = new LinearGradient([{ color: $r('app.color.TOTPView_ListItem_Progress_end'), offset: 0.2 },
                                                              { color: $r('app.color.TOTPView_ListItem_Progress_start'), offset: 1.0 }])

  private generateTOTP() {
    GenerateTOTP(this.totpItem.secret).then((result) => {
      this.code = result.code;
      hilog.info(Constants.DOMAIN, TAG, "GenerateTOTP(%{public}s) Succeed", this.totpItem.alias);
    }).catch((e: BusinessError) => {
      logger.error(Constants.DOMAIN, TAG, "GenerateTOTP fatal: %{public}s", String(e));
    });
  }

  aboutToAppear(): void {
    this.generateTOTP();
    try {
      setInterval(async () => {
        this.currentRemain -= 1;
        if (this.currentRemain === 0) {
          this.currentRemain = 30;
          this.generateTOTP();
        }
      }, 1000)
    } catch (e) {
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
        duration: 1500
      });
    })
  }
}