import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Constants } from '../common/Constants';

const TAG: string = "CustomDialog_disclaimer";

@CustomDialog
export struct CustomDialog_disclaimer {
  controller: CustomDialogController = new CustomDialogController({'builder': ''});
  cancel: Function = () => {};
  confirm: Function = () => {};

  @State message_1: Resource = $r('app.string.WarningPageButton_1');
  @State message_2: Resource = $r('app.string.WarningPageButton_2');

  getDataPreferences(common: Object, file_name: string) {
    return preferences.getPreferences(getContext(common), file_name);
  }

  build() {
    Column() {
      Text($r('app.string.WarningTitle'))
        .fontSize($r('app.float.warningTitle'))
        .textAlign(TextAlign.Start)
        .margin({top: '10%'})
        .width('90%')

      List() {
        ListItem() {
          Text($r('app.string.WarningContent_1'))
            .fontSize($r('app.float.WarningContent'))
            .textAlign(TextAlign.Start)
            .margin({top: '3%'})
            .width('90%')
        }

        ListItem() {
          Text($r('app.string.WarningContent_2'))
            .fontSize($r('app.float.WarningContent'))
            .textAlign(TextAlign.Start)
            .margin({top: '3%'})
            .width('90%')
        }

        ListItem() {
          Text($r('app.string.WarningContent_3'))
            .fontSize($r('app.float.WarningContent'))
            .textAlign(TextAlign.Start)
            .margin({top: '3%'})
            .width('90%')
        }

        ListItem() {
          Text($r('app.string.WarningContent_4'))
            .fontSize($r('app.float.WarningContent'))
            .textAlign(TextAlign.Start)
            .margin({top: '3%'})
            .width('90%')
        }

        ListItem() {
          Text($r('app.string.WarningContent_5'))
            .fontSize($r('app.float.WarningContent'))
            .textAlign(TextAlign.Start)
            .margin({top: '3%'})
            .width('90%')
        }
      }
      .width("90%")
      .height("82%")
      .scrollBar(BarState.Auto)

      Blank()

      Row() {
        Button(this.message_1, {type: ButtonType.Normal})
          .onClick(() => {
            this.controller.close();
            this.confirm();
            hilog.info(Constants.DOMAIN, TAG, "The CONFIRM button was clicked")
          })
          .backgroundColor(Color.Transparent)
          .fontColor($r('sys.color.font_primary'))
          .borderRadius($r('app.float.BorderRadius'))
          .width('48%')

        Divider().vertical(true).height(22).color($r('sys.color.font_primary')).opacity(0.6).margin({ left: 8, right: 8 })

        Button(this.message_2, {type: ButtonType.Normal})
          .onClick(() => {
            this.controller.close();
            this.cancel();
            hilog.info(Constants.DOMAIN, TAG, "The CANCEL button was clicked")
          })
          .backgroundColor(Color.Transparent)
          .fontColor(Color.Black)
          .borderRadius($r('app.float.BorderRadius'))
          .width('48%')
      }
      .width('90%')
      .height("8%")
      .margin({ bottom: '3%' })
    }
    .height('100%')
    .width('100%')
    .backgroundColor($r('app.color.background'))
  }
}