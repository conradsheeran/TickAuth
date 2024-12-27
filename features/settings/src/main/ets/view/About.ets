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

import { JumpToApp, Logger } from "utils";
import { Constants } from "../common/Constants";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { bundleManager, common } from "@kit.AbilityKit";
import { pasteboard } from "@kit.BasicServicesKit";
import { promptAction } from "@kit.ArkUI";

const TAG: string = "About";
const logger = new Logger(getContext(this))
@Entry
@Component
struct About {
  @Consume("pathStack") pathStack: NavPathStack;
  @State versionName: string = "";
  @State versionCode: number = NaN;

  private jumpToApp = new JumpToApp(getContext(this) as common.UIAbilityContext);

  aboutToAppear(): void {
    // 申请获取bundleInfo和applicationInfo
    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;

    try {
      bundleManager.getBundleInfoForSelf(bundleFlags, (err, data) => {
        this.versionCode = data.versionCode;
        this.versionName = data.versionName;
      });
    } catch (e) {
      logger.error(Constants.DOMAIN, TAG, "getBundleInfoForSelf failed: %{public}s %{public}d", e.message, e.code);
    }
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Image($r('app.media.app_icon'))
            .width(135)
            .height(135)

          Divider()
            .vertical(true)
            .height(125)
            .color("#182431")
            .opacity(0.6)
            .margin({ left: 12, right: 12 })

          Image($r('app.media.vendorIcon'))
            .width(150)
            .height(150)
        }
        .margin({ top: "30%" })

        List({ space: 16 }) {
          ListItemGroup({ header: this.header("提供建议或反馈") }) {
            ListItem() {
              Row() {
                Text("GitHub")
                  .margin({ left: 12 })

                Blank()

                SymbolGlyph($r('sys.symbol.arrow_right_up_and_square'))
                  .fontSize(18)
                  .margin({ right: 16 })
              }
              .width("100%")
              .height("100%")
            }
            .align(Alignment.Start)
            .backgroundColor(Color.White)
            .width("100%")
            .height("33%")
            .borderRadius({ topLeft: 16, topRight: 16 })
            .onClick(() => {
              const url: string = "https://github.com/conradsheeran/TickAuth/issues"
              this.jumpToApp.browser(url)
            })

            ListItem() {
              Row() {
                Text("Gitee")
                  .margin({ left: 12 })

                Blank()

                SymbolGlyph($r('sys.symbol.arrow_right_up_and_square'))
                  .fontSize(18)
                  .margin({ right: 16 })
              }
              .width("100%")
              .height("100%")
            }
            .align(Alignment.Start)
            .backgroundColor(Color.White)
            .width("100%")
            .height("33%")
            .onClick(() => {
              const url: string = "https://gitee.com/conrad_sheeran/TickAuth/issues"
              this.jumpToApp.browser(url)
            })

            ListItem() {
              Row() {
                Text("去更新日志发表评论")
                  .margin({ left: 12 })

                Blank()

                SymbolGlyph($r('sys.symbol.arrow_right_up_and_square'))
                  .fontSize(18)
                  .margin({ right: 16 })
              }
              .width("100%")
              .height("100%")
            }
            .align(Alignment.Start)
            .backgroundColor(Color.White)
            .width("100%")
            .height("33%")
            .borderRadius({ bottomLeft: 16, bottomRight: 16 })
            .onClick(() => {
              const url: string = "https://www.tickauth.com/update_log"
              this.jumpToApp.browser(url)
            })
          }
          .height("60%")
          .divider({ strokeWidth: 1 })
        }
        .divider({ strokeWidth: 1 })
        .width("85%")
        .height("40%")
        .margin({ top: 56 })

        Text(`v${this.versionName} (${this.versionCode})`)
          .fontSize(12)
          .fontColor(Color.Gray)
          .width("85%")
          .padding(10)
          .textAlign(TextAlign.Center)
          .onClick(async () => {
            await pasteboard.getSystemPasteboard()
              .setData(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, `v${this.versionName} (${this.versionCode})`));

            promptAction.showToast({
              message: "已复制",
              duration: 1500
            });
          })
      }
      .width("100%")
      .height("100%")
    }
    .title("关于", { backgroundColor: "#93B5CF" })
    .backgroundColor("#F8F4ED")
    .onBackPressed(() => {
      this.pathStack.pop()
      return true;
    })
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }

  @Builder
  header(text: string) {
    Text(text)
      .fontSize(12)
      .fontColor(Color.Gray)
      .width("100%")
      .padding(10)
  }
}

@Builder
export function AboutBuilder(name: string, param: Object) {
  About()
}