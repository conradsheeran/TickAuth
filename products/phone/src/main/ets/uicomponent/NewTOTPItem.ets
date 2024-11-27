import { hilog } from "@kit.PerformanceAnalysisKit";
import { Logger, SecretItem, WriteToJson } from "utils";
import { Constants } from "../common/Constants";

const TAG: string = "CustomDialog_NewTOTPItem";
const logger = new Logger(getContext(this))

@CustomDialog
export struct CustomDialog_NewTOTPItem {
  @StorageLink("refresh") refresh: boolean = false;
  @State newItem: SecretItem = { alias: "", secret: "" };

  controller: CustomDialogController = new CustomDialogController({builder: ""});
  cancel: Function = () => {};
  confirm: Function = () => {};

  build() {
    Column() {
      Text("请输入账户别名")
        .fontSize(20)
        .textAlign(TextAlign.Start)
        .margin({top: '10%'})
        .width('90%')

      TextInput({ placeholder: this.newItem.alias })
        .margin({ top: 24 })
        .enterKeyType(EnterKeyType.Done)
        .onChange((input)=>{
          if (!input.length) {
            // this.newItem.alias = this.oldItem.alias
          } else {
            this.newItem.alias = input
          }
          hilog.debug(Constants.DOMAIN, TAG, "The Input value: %{public}s", input)
        })
        .width("88%")

      Text("请输入修改后的密钥")
        .fontSize(20)
        .textAlign(TextAlign.Start)
        .margin({top: '10%'})
        .width('90%')

      TextInput({ placeholder: this.newItem.secret })
        .margin({ top: 24 })
        .enterKeyType(EnterKeyType.Done)
        .onChange((input)=>{
          if (!input.length) {
            // this.newItem.secret = this.oldItem.secret
          } else {
            this.newItem.secret = input
          }
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
              await new WriteToJson(getContext(this).filesDir + Constants.SECRET_FILE_DIR)
                .write(this.newItem);
              logger.info(Constants.DOMAIN, TAG, "The Confirm button was clicked")
            }

            this.refresh = true
          })
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .fontColor(Color.Black)
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
          .fontColor(Color.Black)
          .borderRadius($r('app.float.BorderRadius'))
          .margin({ bottom: 12, left: 12 })
          .width("40%")
      }
      .width("100%")
      .padding({ bottom: 8 })
      .justifyContent(FlexAlign.Center)
      .margin({ top: Constants.DISCLAIMER_BUTTON_ENSEMBLE_MARGIN })
    }
    .height('48%')
    .width('96%')
    .borderRadius($r('app.float.BorderRadius'))
    .backgroundColor("#f1f0ed")
  }
}