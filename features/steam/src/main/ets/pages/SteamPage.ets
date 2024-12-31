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
import { Logger, Preference, WriteToJson } from "utils";
import { fileIo as fs, picker } from '@kit.CoreFileKit';
import { BusinessError } from "@kit.BasicServicesKit";
import { SteamTOTPView } from "../view/SteamTOTPView";

const TAG: string = "SteamPage"
const logger = new Logger(getContext(this))

interface ISteamSecretParams {
  shared_secret: string;
  identity_secret: string;
  revocation_code: string;
  steamid: string;
  uri: string;
  account_name: string;
  device_id: string;
}

@Component
export struct SteamPage {
  @Consume("pathStack") pathStack: NavPathStack;
  @State hasSteamKey: boolean = false;
  @State alias: string = "";
  @State timeOffset: number = NaN;

  private context = getContext(this);
  private writeToJson = new WriteToJson(this.context.filesDir + "/secret.json")
  private preferences = new Preference(getContext(this), "Preferences");

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
        }
      },
      radioContent: [
        {
          title: '从 maFile 文件导入密钥（推荐）',
          action: () => {
            try {
              let documentSelectOptions = new picker.DocumentSelectOptions();
              documentSelectOptions.maxSelectNumber = 1;
              documentSelectOptions.fileSuffixFilters = ["maFile"];

              let documentPicker = new picker.DocumentViewPicker(this.context);
              documentPicker.select(documentSelectOptions).then((documentSelectResult: Array<string>) => {
                fs.open(documentSelectResult[0], fs.OpenMode.READ_ONLY).then((file) => {
                  fs.readText(file.path).then(async (content: string) => {
                    let steamSecretParams: ISteamSecretParams = JSON.parse(content);
                    await this.writeToJson.write({
                      type: "steam",
                      alias: steamSecretParams.account_name,
                      secret: steamSecretParams.shared_secret,
                      digit: 5,
                      timeStep: 30,
                      algorithm: "SHA1",
                      raw: content
                    });
                    fs.close(file.fd)
                    this.hasSteamKey = true;
                    this.preferences.put("hasSteamKey", true)
                    //todo: 增加跳转TOTP界面
                  }).catch((e: BusinessError) => {
                    promptAction.showToast({
                      message: `错误：${e.message} (${TAG})`,
                      duration: 2000
                    });
                    fs.close(file.fd)
                    logger.error(Constants.DOMAIN, TAG, "Read JSON file fatal: %{public}s", String(e))
                  })
                })
                hilog.info(Constants.DOMAIN, TAG, "WriteToJson Succeed")
              }).catch((e: BusinessError) => {
                promptAction.showToast({
                  message: `错误：${e.message}(${TAG})`,
                  duration: 2000
                });
                logger.error(Constants.DOMAIN, TAG, "documentViewPicker.select Fatal: %{public}s code: {public}d", e.message, e.code)
              });
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

  async aboutToAppear(): Promise<void> {
    try {
      this.hasSteamKey = await this.preferences.get("hasSteamKey", false) as boolean;
    } catch (e) {
      logger.error(Constants.DOMAIN, TAG, "Detect whether to add a key fatal: %{public}s", String(e));
    }
  }

  build() {
    NavDestination() {
      Column() {
        if (this.hasSteamKey) {
          SteamTOTPView()
        } else {
          AddSteamTOTP()
        }
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