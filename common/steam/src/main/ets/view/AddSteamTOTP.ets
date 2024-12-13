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

import { promptAction } from "@kit.ArkUI"
import { JumpToApp } from "utils"
import { common } from "@kit.AbilityKit"

@Component
export struct AddSteamTOTP {
  build() {
    Column() {
      Image($r('app.media.steam_logo'))
        .height(150)
        .width(150)
        .margin({ top: 56 })

      Text() {
        SymbolSpan($r("sys.symbol.exclamationmark_triangle_fill"))
          .fontColor(["#fecc11"])
        Span(" 注意事项：")
      }
        .fontSize(16)
        .textAlign(TextAlign.Start)
        .fontWeight(FontWeight.Medium)
        .width("85%")
        .margin({ top: 56 })

      Text(
        "1. 在添加 Steam 验证码前，建议先阅读使用教程\n" +
          "2. 目前仅能实现获取 Steam 验证码的功能，暂时无法实现 Steam Mobile 的全部功能，后续将陆续支持\n" +
          "3. 后续将陆续支持直接从本应用获取 Steam 密钥等功能，敬请期待"
      )
        .fontSize(14)
        .textAlign(TextAlign.Start)
        .lineHeight(28)
        .width("85%")

      List() {
        ListItem() {
          Row() {
            Text("使用教程")
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
        .height("40%")
        .borderRadius({ topLeft: 16, topRight: 16 })
        .onClick(() => {
          const url: string = "https://tickauth.com/steam-totp"
          new JumpToApp(getContext(this) as common.UIAbilityContext).browser(url)
        })

        ListItem() {
          Row() {
            Text("获取 Steam 令牌密钥")
              .margin({ left: 12 })

            Blank()

            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(20)
              .margin({ right: 18 })
          }
          .width("100%")
          .height("100%")
        }
        .align(Alignment.Start)
        .backgroundColor(Color.White)
        .width("100%")
        .height("40%")
        .borderRadius({ bottomLeft: 16, bottomRight: 16 })
        .onClick(() => {
          promptAction.showToast({
            message: "暂不支持该功能，请点击右上角导入密钥",
            duration: 2500
          });
        })
      }
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 1 })
      .width("85%")
      .height("20%")
      .margin({ top: 56 })
    }
    .width('100%')
    .height("100%")
    .justifyContent(FlexAlign.Center)
  }
}