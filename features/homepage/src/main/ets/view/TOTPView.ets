import { fileIo as fs } from "@kit.CoreFileKit"
import { buffer } from '@kit.ArkTS';
import { SecretClass } from "../model/TOTPModel"
import { BusinessError } from "@kit.BasicServicesKit";
import { bufferToString, Logger } from "utils"
import { GenerateTOTP } from "totp"
import { Constants } from "../common/Constants";
import { hilog } from "@kit.PerformanceAnalysisKit";

const TAG: string = "TOTPView";
const logger = new Logger(getContext(this))

@Component
export struct TOTP {
  @State TOTPList: Array<SecretClass> = [];

  aboutToAppear(): void {
    try {
      this.GetSecretFromJson();
    } catch (e) {
      logger.error(Constants.DOMAIN, TAG, "GetSecretFromJson fatal: %{public}s", String(e))
    }
  }

  async GetSecretFromJson() {
    hilog.info(Constants.DOMAIN, TAG, "GetSecretFromJson Start")

    const filePath = getContext(this).filesDir + Constants.SECRET_FILE_DIR
    const fd = (await fs.open(filePath, fs.OpenMode.READ_ONLY)).fd;
    let arrayBuffer = new ArrayBuffer(4096);

    await fs.read(fd, arrayBuffer).then((readLen) => {
      let buf = buffer.from(arrayBuffer, 0, readLen);
      this.TOTPList = JSON.parse(bufferToString(new Uint8Array(buf.buffer)).replace(/[\u0000-\u001F\u007F-\u009F]/g, "").trim()) as SecretClass[];
      hilog.info(Constants.DOMAIN, TAG, "GetSecretFromJson Succeed")
    }).catch((e: BusinessError) => {
      logger.error(Constants.DOMAIN, TAG, "Read JSON file fatal: %{public}s", String(e))
    })
  }

  build() {
    Column() {
      List({ space: 12 }) {
        ForEach(this.TOTPList, (item: SecretClass) => {
          ListItem() {
            TOTPItem({ totpItem: item })
          }
        }, (item: SecretClass) => item.alias)
      }
      .scrollBar(BarState.Off)
      .padding({ left: 16, right: 16 })
    }
    .margin({ top: 18 })
  }
}

@Component
struct TOTPItem {
  @Prop totpItem: SecretClass;

  aboutToAppear(): void {
    GenerateTOTP(this.totpItem.secret).then((result) => {
      this.totpItem.secret = result.code;
      hilog.info(Constants.DOMAIN, TAG, "GenerateTOTP(%{public}s) Succeed", this.totpItem.alias)
    }).catch((e: BusinessError) => {
      logger.error(Constants.DOMAIN, TAG, "GenerateTOTP fatal: %{public}s", String(e))
    })
  }

  build() {
    Row() {
      Column() {
        Text(this.totpItem.alias)
          .height("50%")
          .width('100%')
          .fontSize(18)
          .textAlign(TextAlign.Start)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(1)

        Text(this.totpItem.secret)
          .height("50%")
          .width('100%')
          .fontSize(30)
          .fontColor("#66A9C9")
          .textAlign(TextAlign.Start)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(1)
          .margin({ bottom: 4 })

      }
      .height('100%')
      .layoutWeight(1)
      .margin({ right: 12 })
    }
    .width('100%')
    .height("13.5%")
    .borderRadius(16)
    .backgroundColor(Color.White)
    .padding(12)
    .alignItems(VerticalAlign.Top)
  }
}