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

import { bufferToString, Logger, Preference } from "utils";
import { Constants } from "../common/Constants";
import { SettingsItemClass } from "../model/SettingsItemModel"
import { hilog } from "@kit.PerformanceAnalysisKit";
import { promptAction } from "@kit.ArkUI";

const TAG: string = "SettingsItemView";
const logger = new Logger(getContext(this))

@Component
export struct SettingsItemView {
  @Consume("pathStack") pathStack: NavPathStack;
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
              .onClick(() => {
                if (item.title === "导入和导出") {
                  try {
                    this.pathStack.pushPath({ name: "ImportAndExport" })
                  } catch (e) {
                    promptAction.showToast({
                      message: `错误：${e.message} (${TAG})`,
                      duration: 2000
                    });
                    logger.error(Constants.DOMAIN, TAG, "pushPath(ImportAndExport) Fatal: %{public}s code: {public}d", e.message, e.code)
                  }
                }

                if (item.title === "关于") {
                  try {
                    this.pathStack.pushPath({ name: "About" })
                  } catch (e) {
                    promptAction.showToast({
                      message: `错误：${e.message} (${TAG})`,
                      duration: 2000
                    });
                    logger.error(Constants.DOMAIN, TAG, "pushPath Fatal: %{public}s code: {public}d", e.message, e.code)
                  }
                }
              })
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
  @State isOn: boolean = false;

  private preferences = new Preference(getContext(this), "Preferences")

  aboutToAppear(): void {
    this.preferences.get(this.settingsItem.title, false).then((value) => {
      this.isOn = Boolean(value)
    })
  }

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

      if (this.settingsItem.title != "身份认证") {
        if (this.settingsItem.title === "导入和导出" || this.settingsItem.title === "关于") {
          this.SwitchPage()
        }
      } else {
        this.Toggle()
      }
    }
    .width(Constants.SETTINGSITEMVIEW_LISTITEM_WIDTH)
    .height(Constants.SETTINGSITEMVIEW_LISTITEM_HEIGHT)
    .borderRadius($r('app.float.BorderRadius'))
    .backgroundColor(Color.White)
    .padding($r('app.float.SettingsItemView_ListItem_padding'))
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  Toggle() {
    Toggle({ type: ToggleType.Switch, isOn: this.isOn })
      .onChange((isOn: boolean) => {
        if (isOn) {
          this.preferences.put(this.settingsItem.title, true);
        } else {
          this.preferences.put(this.settingsItem.title, false);
        }
      })
      .size({
        "width": $r('app.float.SettingsItemView_ListItem_Toggle_width'),
        "height": $r('app.float.SettingsItemView_ListItem_Toggle_height')
      })
      .selectedColor($r('app.color.toggleBackground'))
      .margin({ right: $r('app.float.SettingsItemView_ListItem_Toggle_margin') })
      .alignSelf(ItemAlign.Center)
  }

  @Builder
  SwitchPage() {
    Blank()

    SymbolGlyph($r('sys.symbol.chevron_right'))
      .fontSize(30)
      .fontWeight(FontWeight.Normal)
      .fontColor([Color.Gray])
      .margin({ right: 14 })
      .alignSelf(ItemAlign.Center)
  }
}