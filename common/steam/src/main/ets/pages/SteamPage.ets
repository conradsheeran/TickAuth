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
import { AddSteamTOTP } from "../view/AddSteamTOTP";
import { promptAction, SelectDialog, SymbolGlyphModifier } from "@kit.ArkUI";
import { SteamTOTP } from "steam-totp";
import { CustomDialog_editSecret } from "uicomponent";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { Constants } from "../common/Constants";
import { Logger } from "utils";

const TAG: string = "SteamPage"
const logger = new Logger(getContext(this))

@Component
export struct SteamPage {
  @Consume("pathStack") pathStack: NavPathStack;
  @State alias: string = "";
  @State timeOffset: number = NaN;

  private plus: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.plus'));
  private refreshSymbol: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise'));

  private TitleMenuItem1: NavigationMenuItem = {
    'value': "",
    'symbolIcon': this.refreshSymbol,
    'action': async () => {
      this.timeOffset = (await SteamTOTP.getTimeOffset()).offset;
    }
  };

  private TitleMenuItem2: NavigationMenuItem = {
    'value': "",
    'symbolIcon': this.plus,
    'action': () => {
      this.dialogControllerList.open()
    }
  };

  dialogControllerList: CustomDialogController = new CustomDialogController({
    builder: SelectDialog({
      title: '请选择一种添加方式',
      selectedIndex: 2,
      confirm: {
        value: '取消',
        action: () => {
          hilog.debug(Constants.DOMAIN, TAG, "dialogControllerList: CANCEL button has been clicked.")
        },
      },
      radioContent: [
        {
          title: '从 maFile 文件导入密钥（推荐）',
          action: () => {
            try {
              //todo: 建议写入json文件的raw参数部分，json文件增加type参数
            } catch (e) {
              promptAction.showToast({
                message: `错误：${e.message} (${TAG})`,
                duration: 2000
              });
              logger.error(Constants.DOMAIN, TAG, "ADD button: %{public}s", String(e));
            }
          }
        },
        {
          title: '手动输入 Steam 手机令牌参数',
          action: () => {
            this.newSteamTOTP.open()
          }
        }
      ]
    })
  })

  private newSteamTOTP: CustomDialogController = new CustomDialogController({
    builder: CustomDialog_editSecret(
      {
        cancel: () => {
          //
        },

        confirm: async () => {
          //
        },

        symbol: $r('sys.symbol.plus_square_on_square'),
        symbolColor: $r('sys.color.font_primary'),
        title: "请输入 Steam 手机令牌参数",
        content: "请输入您的账户别名",
        retryContent: "请勿使用相同的账户别名",
        confirmButtonFontColor: $r("sys.color.warning"),
        cancelButtonFontColor: $r("sys.color.brand_font"),
        mode: "newSteamCode",

        contentSecret: "请输入您的的密钥 (shared_secret)",

        alias: $alias
      }),

    customStyle: true,

    onWillDismiss:(dismissDialogAction: DismissDialogAction)=> {
      hilog.debug(Constants.DOMAIN, TAG, "newSteamTOTP: User try to exit. Action: %{public}s", dismissDialogAction.reason.toString())
    }
  })

  build() {
    NavDestination() {
      Column() {
        AddSteamTOTP()
      }
      .width('100%')
      .height('100%')
    }
    .backgroundColor($r('app.color.background'))
    .title('Steam', { backgroundColor: "#93B5CF" })
    .menus([this.TitleMenuItem1, this.TitleMenuItem2])
    .onBackPressed(() => {
      this.pathStack.pop()
      return true;
    })
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}

@Builder
export function SteamPageBuilder(name: string, param: Object) {
  SteamPage()
}