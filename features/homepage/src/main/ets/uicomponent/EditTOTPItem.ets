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

      Button("确定", {type: ButtonType.Normal})
        .onClick(() => {
          if (this.controller != undefined) {
            this.controller.close()
            this.confirm()
            logger.info(Constants.DOMAIN, TAG, "The Confirm button was clicked")
          }
        })
        .width("88%")
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .fontColor($r("sys.color.brand_font"))
        .borderRadius($r('app.float.BorderRadius'))
        .margin({ bottom: 12 })
    }
    .height('30%')
    .width('96%')
    .borderRadius($r('app.float.BorderRadius'))
    .backgroundColor("#f1f0ed")
  }
}