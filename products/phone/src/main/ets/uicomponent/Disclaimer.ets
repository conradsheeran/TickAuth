import { hilog } from '@kit.PerformanceAnalysisKit';
import { Constants } from '../common/Constants';

const TAG: string = "CustomDialog_disclaimer";

@CustomDialog
export struct CustomDialog_disclaimer {
  controller: CustomDialogController = new CustomDialogController({ builder: ''});
  cancel: Function = () => {};
  confirm: Function = () => {};

  build() {
    Column() {
      Text($r('app.string.Disclaimer_title'))
        .fontSize($r('app.float.Disclaimer_title'))
        .textAlign(TextAlign.Center)
        .margin({top: Constants.DISCLAIMER_TITLE_MARGIN})
        .width(Constants.DISCLAIMER_WIDTH)

      List() {
        ListItem() {
          Text($r('app.string.Disclaimer_content1'))
            .fontSize($r('app.float.Disclaimer_content'))
            .textAlign(TextAlign.Start)
            .margin({top: Constants.DISCLAIMER_CONTENT_MARGIN})
            .width(Constants.DISCLAIMER_WIDTH)
        }

        ListItem() {
          Text($r('app.string.Disclaimer_content2'))
            .fontSize($r('app.float.Disclaimer_content'))
            .textAlign(TextAlign.Start)
            .margin({top: Constants.DISCLAIMER_CONTENT_MARGIN})
            .width(Constants.DISCLAIMER_WIDTH)
        }

        ListItem() {
          Hyperlink($r('app.string.Disclaimer_PrivacyPolicyStatement_url'), $r('app.string.Disclaimer_PrivacyPolicyStatement_title'))
            .height($r('app.float.Disclaimer_content'))
            .margin({top: Constants.DISCLAIMER_CONTENT_MARGIN})
            .width(Constants.DISCLAIMER_WIDTH)
        }

        ListItem() {
          Text($r('app.string.Disclaimer_PrivacyPolicyStatement_explanation'))
            .fontSize($r('app.float.Disclaimer_PrivacyPolicyStatement_explanation'))
            .fontColor(Color.Gray)
            .textAlign(TextAlign.Start)
            .margin({top: Constants.DISCLAIMER_CONTENT_MARGIN})
            .width(Constants.DISCLAIMER_WIDTH)
        }
      }
      .width(Constants.DISCLAIMER_WIDTH)
      .height(Constants.DISCLAIMER_CONTENT_HEIGHT)
      .alignListItem(ListItemAlign.Center)
      .scrollBar(BarState.Auto)

      Row() {
        Button($r('app.string.Disclaimer_confirm'), {type: ButtonType.Normal})
          .onClick(() => {
            this.controller.close();
            this.confirm();
            hilog.info(Constants.DOMAIN, TAG, "The CONFIRM button was clicked")
          })
          .backgroundColor(Color.Transparent)
          .fontColor($r('sys.color.font_primary'))
          .borderRadius($r('app.float.BorderRadius'))
          .width(Constants.DISCLAIMER_BUTTON_WIDTH)

        Divider()
          .vertical(true)
          .height($r('app.float.Disclaimer_Divider_height'))
          .color($r('sys.color.font_primary'))
          .opacity($r('app.float.Disclaimer_Divider_opacity'))
          .margin({ left: $r('app.float.Disclaimer_Divider_margin'), right: $r('app.float.Disclaimer_Divider_margin') })

        Button($r('app.string.Disclaimer_cancel'), {type: ButtonType.Normal})
          .onClick(() => {
            this.controller.close();
            this.cancel();
            hilog.info(Constants.DOMAIN, TAG, "The CANCEL button was clicked")
          })
          .backgroundColor(Color.Transparent)
          .fontColor(Color.Black)
          .borderRadius($r('app.float.BorderRadius'))
          .width(Constants.DISCLAIMER_BUTTON_WIDTH)
      }
      .width(Constants.DISCLAIMER_BUTTON_ENSEMBLE_WIDTH)
      .height(Constants.DISCLAIMER_BUTTON_ENSEMBLE_HEIGHT)
      .margin({ top: Constants.DISCLAIMER_BUTTON_ENSEMBLE_MARGIN })
    }
    .height(Constants.DISCLAIMER_DIALOG_HEIGHT)
    .width(Constants.DISCLAIMER_DIALOG_WIDTH)
    .borderRadius($r('app.float.BorderRadius'))
    .backgroundColor($r('app.color.background'))
  }
}