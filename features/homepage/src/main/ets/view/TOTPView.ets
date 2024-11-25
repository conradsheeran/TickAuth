import { fileIo as fs } from "@kit.CoreFileKit"
import { buffer } from '@kit.ArkTS';
import { SecretClass } from "../model/TOTPModel"
import { BusinessError, pasteboard } from "@kit.BasicServicesKit";
import { bufferToString, Logger, WriteToJson } from "utils"
import { GenerateTOTP, GetTOTPTimeInfo } from "totp"
import { Constants } from "../common/Constants";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { promptAction } from "@kit.ArkUI";

const TAG: string = "TOTPView";
const logger = new Logger(getContext(this))

@Component
export struct TOTP {
  @StorageLink("hasKey") hasKey: boolean = false;
  @State TOTPList: Array<SecretClass> = [];
  @Link @Watch("Refresh") refresh: boolean;

  private writeToJson = new WriteToJson(getContext(this).filesDir + Constants.SECRET_FILE_DIR)

  aboutToAppear(): void {
    try {
      this.GetSecretFromJson();
    } catch (e) {
      logger.error(Constants.DOMAIN, TAG, "GetSecretFromJson fatal: %{public}s", String(e))
    }

    this.refresh = false;
  }

  Refresh() {
    try {
      this.GetSecretFromJson();
    } catch (e) {
      logger.error(Constants.DOMAIN, TAG, "GetSecretFromJson fatal: %{public}s", String(e))
    }

    this.refresh = false;
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
            TOTPItem({ totpItem: item })
          }
          .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))
          .swipeAction({
            end: {
              builder: () => { this.itemEnd(this.TOTPList.indexOf(item), item.alias) },
            }
          })
        }, (item: SecretClass) => item.alias)
      }
      .width(Constants.TOTPVIEW_LIST_SIZE)
      .height(Constants.TOTPVIEW_LIST_SIZE)
      .scrollBar(BarState.Auto)
      .padding({ left: $r('app.float.TOTPView_List_padding'), right: $r('app.float.TOTPView_List_padding') })
    }
    .margin({ top: $r('app.float.TOTPView_List_margin') })
  }

  @Builder
  itemEnd(index: number, alias: string) {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.trash'))
        .fontSize($r('app.float.TOTPView_ListItem_DeleteButton_Symbol_size'))
        .fontColor([Color.White])
    }
    .backgroundColor($r('app.color.TOTPView_ListItem_deleteButton'))
    .width($r('app.float.TOTPView_ListItem_DeleteButton_size'))
    .height($r('app.float.TOTPView_ListItem_DeleteButton_size'))
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
  @StorageLink("refresh") refresh: boolean = false;
  @Prop totpItem: SecretClass;
  @State totalTime: number = 30;
  @State timeRemain: number = 1;

  aboutToAppear(): void {
    GenerateTOTP(this.totpItem.secret).then((result) => {
      this.totpItem.secret = result.code;
      hilog.info(Constants.DOMAIN, TAG, "GenerateTOTP(%{public}s) Succeed", this.totpItem.alias)
    }).catch((e: BusinessError) => {
      logger.error(Constants.DOMAIN, TAG, "GenerateTOTP fatal: %{public}s", String(e))
    })

    try {
      let currentRemain = GetTOTPTimeInfo();
      setInterval(async () => {
        currentRemain -= 1;

        if (currentRemain === 0) {
          currentRemain = 30;
          GenerateTOTP(this.totpItem.secret).then((result) => {
            this.totpItem.secret = result.code;
            hilog.info(Constants.DOMAIN, TAG, "GenerateTOTP(%{public}s) Succeed", this.totpItem.alias)
          }).catch((e: BusinessError) => {
            logger.error(Constants.DOMAIN, TAG, "GenerateTOTP fatal: %{public}s", String(e))
          })

          this.refresh = true;
        } else {
          this.refresh = false;
        }

        this.timeRemain = currentRemain
      }, 1000)
    } catch (e) {
      logger.error(Constants.DOMAIN, TAG, "Get the TOTP time parameter fatal: %{public}s", String(e));
    }
  }

  private gradientColor: LinearGradient = new LinearGradient([{ color: $r('app.color.TOTPView_ListItem_Progress_end'), offset: 0.2 },
                                                              { color: $r('app.color.TOTPView_ListItem_Progress_start'), offset: 1.0 }])

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
          .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))

        if (!this.refresh) {
          this.totpItemSecret()
        } else {
          this.totpItemSecret()
        }
      }
      .margin({ right: $r('app.float.TOTPView_ListItem_Text_margin') })

      Blank()

      Progress({ value: this.timeRemain, total: this.totalTime, type: ProgressType.Ring })
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
        .setData(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.totpItem.secret));

      promptAction.showToast({
        message: `验证码（${this.totpItem.alias}）已复制`,
        duration: 1500
      });
    })
  }

  @Builder
  totpItemSecret() {
    Text(this.totpItem.secret)
      .height(Constants.TOTPVIEW_LISTITEM_TOTP_HEIGHT)
      .width(Constants.TOTPVIEW_LISTITEM_TOTP_WIDTH)
      .fontSize($r('app.float.TOTPView_ListItem_Secret_fontsize'))
      .fontColor($r('app.color.TOTPView_ListItem_fontcolor'))
      .textAlign(TextAlign.Start)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .maxLines(Constants.TOTPVIEW_LISTITEM_MAXLINE)
      .margin({ bottom: $r('app.float.TOTPView_ListItem_Secret_margin') })
      .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))
  }
}