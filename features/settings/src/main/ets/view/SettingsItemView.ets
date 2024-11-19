import { bufferToString, Logger } from "utils";
import { Constants } from "../common/Constants";
import { SettingsItemClass } from "../model/SettingsItemModel"
import { hilog } from "@kit.PerformanceAnalysisKit";

const TAG: string = "SettingsItemView";
const logger = new Logger(getContext(this))

@Component
export struct SettingsItemView {
  @State SettingsItemList: Array<SettingsItemClass> = [];

  aboutToAppear(): void {
    try {
      this.GetSettingsItemFromJson();
    } catch (e) {
      logger.error(Constants.DOMAIN, TAG, "GetSettingsItemFromJson fatal: %{public}s", String(e))
    }
  }

  async GetSettingsItemFromJson() {
    hilog.info(Constants.DOMAIN, TAG, "GetSettingsItemFromJson Start")

    getContext(this).resourceManager.getRawFileContent("settings.json").then((content) => {
      this.SettingsItemList = JSON.parse(bufferToString(content)) as SettingsItemClass[];
    })
  }

  build() {
    Column() {
      List({ space: Constants.SETTINGSITEM_LIST_SPACE }) {
        ForEach(this.SettingsItemList, (item: SettingsItemClass) => {
          ListItem() {
            SettingsItem({ settingsItem: item })
          }
        }, (item: SettingsItemClass) => item.title)
      }
      .width(Constants.SETTINGSITEM_LIST_SIZE)
      .height(Constants.SETTINGSITEM_LIST_SIZE)
      .scrollBar(BarState.Auto)
      .padding({ left: $r('app.float.SettingsItemView_List_padding'), right: $r('app.float.SettingsItemView_List_padding') })
    }
    .margin({ top: $r('app.float.SettingsItemView_List_margin') })
  }
}

@Component
struct SettingsItem {
  @Prop settingsItem: SettingsItemClass;

  build() {
    Row() {
      SymbolGlyph($r(this.settingsItem.symbol))
        .fontSize($r('app.float.SettingsItemView_ListItem_Symbol_size'))
        .alignSelf(ItemAlign.Center)

      Column() {
        Text(this.settingsItem.title)
          .height(Constants.SETTINGSITEMVIEW_LISTITEM_TITLE_HEIGHT)
          .width(Constants.SETTINGSITEMVIEW_LISTITEM_TITLE_WIDTH)
          .fontSize($r('app.float.SettingsItemView_ListItem_Title_fontsize'))
          .textAlign(TextAlign.Start)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(Constants.SETTINGSITEMVIEW_LISTITEM_MAXLINE)
          .padding({ top: $r('app.float.SettingsItemView_ListItem_Title_margin') })


        Blank()

        Text(this.settingsItem.content)
          .height(Constants.SETTINGSITEMVIEW_LISTITEM_CONTENT_HEIGHT)
          .width(Constants.SETTINGSITEMVIEW_LISTITEM_CONTENT_WIDTH)
          .fontSize($r('app.float.SettingsItemView_ListItem_Content_fontsize'))
          .fontColor(Color.Gray)
          .textAlign(TextAlign.Start)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(Constants.SETTINGSITEMVIEW_LISTITEM_MAXLINE)
          .padding({ bottom: $r('app.float.SettingsItemView_ListItem_Content_margin') })
      }
      .height(Constants.SETTINGSITEMVIEW_LISTITEM_TEXT_HEIGHT)
      .alignItems(HorizontalAlign.Center)
      .margin({ left: $r('app.float.SettingsItemView_ListItem_Text_left_margin'),
        top: $r('app.float.SettingsItemView_ListItem_Text_top_margin') })

      Toggle({ type: ToggleType.Switch, isOn: false })
        .onChange((isOn: boolean) => {
          if(isOn) {

          } else {

          }
        }
        )
        .size({
          "width": $r('app.float.SettingsItemView_ListItem_Toggle_width'),
          "height": $r('app.float.SettingsItemView_ListItem_Toggle_height')
        })
        .selectedColor($r('app.color.toggleBackground'))
        .margin({ right: $r('app.float.SettingsItemView_ListItem_Toggle_margin') })
        .alignSelf(ItemAlign.Center)
    }
    .width(Constants.SETTINGSITEMVIEW_LISTITEM_WIDTH)
    .height(Constants.SETTINGSITEMVIEW_LISTITEM_HEIGHT)
    .borderRadius($r('app.float.BorderRadius'))
    .backgroundColor(Color.White)
    .padding($r('app.float.SettingsItemView_ListItem_padding'))
    .alignItems(VerticalAlign.Top)
  }
}