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

import { common } from '@kit.AbilityKit';
import { promptAction, SelectDialog, SymbolGlyphModifier } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { CustomDialog_disclaimer } from '../uicomponent/Disclaimer'
import { HomePage, NoKeyInJSON } from "homepage"
import { Settings } from "settings"
import { WriteToJson, Logger, Preference, CatchSecretByScan, ISecretItem } from "utils"
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Constants } from '../common/Constants';
import { UserAuth } from '../model/UserAuth';
import { UserAuthView } from '../view/UserAuth';
import { CustomDialog_editSecret } from "uicomponent"
import { SteamTOTPView } from 'steam/src/main/ets/view/SteamTOTPView';
import { SecretClass } from 'homepage/src/main/ets/model/TOTPModel';
import { fileIo as fs } from "@kit.CoreFileKit"

const TAG: string = "Index"
const logger = new Logger(getContext(this))

@Entry
@Component
struct Index {
  @Provide("pathStack") pathStack: NavPathStack = new NavPathStack();;
  @LocalStorageLink("login") login: boolean = false;
  @LocalStorageLink("hasKey") hasKey: boolean = false;
  @LocalStorageLink("refresh") refresh: boolean = false;
  @State CustomDialog_editTOTPItemIsClosed: boolean = false;
  @State alias: string = "";
  @State secret: string = "";
  @State digit: number = 6;
  @State timeStep: number = 30;
  @State algorithm: string = "SHA1";
  @State rawSecretParam: string = "";
  @State useDefault: boolean = false;
  @State currentIndex: number = 0;
  @State onForeground: boolean = false;
  @State isConfirm: boolean = false;
  @State hasSteamKey: boolean = false;
  @State TOTPList_Steam: Array<SecretClass> = [];

  // 弹窗控制器
  dialogControllerList: CustomDialogController = new CustomDialogController({
    builder: SelectDialog({
      title: '请选择一种添加方式',
      selectedIndex: 3,
      confirm: {
        value: '取消',
        action: () => {
          hilog.debug(Constants.DOMAIN, TAG, "dialogControllerList: CANCEL button has been clicked.")
        },
      },
      radioContent: [
        this.addTOTPKeyByScan(),
        this.addTOTPKeyByInput(),
        {
          title: '添加 Steam 手机令牌',
          action: () => {
            try {
              this.pathStack.pushPath({ name: "SteamPage" })
            } catch (e) {
              promptAction.showToast({
                message: `错误：${e.message} (${TAG})`,
                duration: 2000
              });
              logger.error(Constants.DOMAIN, TAG, "pushPath(SteamPage) Fatal: %{public}s code: {public}d", e.message, e.code)
            }
          }
        }
      ]
    })
  })

  dialogControllerList_withoutSteam: CustomDialogController = new CustomDialogController({
    builder: SelectDialog({
      title: '请选择一种添加方式',
      selectedIndex: 3,
      confirm: {
        value: '取消',
        action: () => {
          hilog.debug(Constants.DOMAIN, TAG, "dialogControllerList: CANCEL button has been clicked.")
        },
      },
      radioContent: [
        this.addTOTPKeyByScan(),
        this.addTOTPKeyByInput()
      ]
    })
  })

  disclaimer: CustomDialogController = new CustomDialogController({
    builder: CustomDialog_disclaimer(
      {
        cancel: () => {
          this.context.terminateSelf();
        },

        confirm: () => {
          this.preferences.put("disclaimerIsConfirm", true);
        }
      }),

    customStyle: true,

    onWillDismiss:(dismissDialogAction: DismissDialogAction)=> {
      hilog.debug(Constants.DOMAIN, TAG, "disclaimer: User try to exit. Action: %{public}s", dismissDialogAction.reason.toString())
    }
  });

  editTOTPItem: CustomDialogController = new CustomDialogController({
    builder: CustomDialog_editSecret(
      {
        cancel: () => {
          this.isConfirm = false;
          this.CustomDialog_editTOTPItemIsClosed = false
        },

        confirm: () => {
          this.isConfirm = true
          this.CustomDialog_editTOTPItemIsClosed = true
        },

        symbol: $r('sys.symbol.square_and_pencil'),
        symbolColor: $r('sys.color.font_primary'),
        title: "请输入您的账户别名",
        content: "该别名将用于为您区分不同的验证码",
        retryContent: "请勿使用相同的账户别名",
        confirmButtonFontColor: $r("sys.color.warning"),
        cancelButtonFontColor: $r("sys.color.brand_font"),
        mode: "edit",

        alias: $alias
      }),

    customStyle: true,

    onWillDismiss:(dismissDialogAction: DismissDialogAction)=> {
      hilog.debug(Constants.DOMAIN, TAG, "editTOTPItem: User try to exit. Action: %{public}s", dismissDialogAction.reason.toString())
    }
  });

  newTOTPItem: CustomDialogController = new CustomDialogController({
    builder: CustomDialog_editSecret(
      {
        cancel: () => {
          this.refresh = false;
        },

        confirm: async () => {
          this.hasKey = true
          this.refresh = true
        },

        symbol: $r('sys.symbol.plus_square_on_square'),
        symbolColor: $r('sys.color.font_primary'),
        title: "请输入 TOTP 验证码参数",
        content: "请输入您的账户别名",
        retryContent: "请勿使用相同的账户别名",
        confirmButtonFontColor: $r("sys.color.warning"),
        cancelButtonFontColor: $r("sys.color.brand_font"),
        mode: "new",

        contentSecret: "请输入您的的密钥",

        alias: $alias
      }),

    customStyle: true,

    onWillDismiss:(dismissDialogAction: DismissDialogAction)=> {
      hilog.debug(Constants.DOMAIN, TAG, "newTOTPItem: User try to exit. Action: %{public}s", dismissDialogAction.reason.toString())
    }
  });

  // 系统图标
  private plus: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.plus'));

  // 初始化必要数据
  private context = getContext(this) as common.UIAbilityContext;
  private writeToJson = new WriteToJson(this.context.filesDir + Constants.SECRET_FILE_DIR)
  private preferences = new Preference(this.context, "Preferences")

  // 标题栏
  @Builder
  Title() {
    Row() {
      if (this.currentIndex === 0) {
        Text($r('app.string.Title')).fontSize(24).fontWeight(FontWeight.Bold)
      } else if (this.currentIndex === 1) {
        Text($r("app.string.Title_SteamPage")).fontSize(24).fontWeight(FontWeight.Bold)
      } else {
        Text($r("app.string.Title_Settings")).fontSize(24).fontWeight(FontWeight.Bold)
      }
    }
    .width("30%")
    .height("100%")
    .margin({ left: 18 })
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  TitleMenuItem() {
    Row() {
      if (this.currentIndex === 0) {
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.plus'))
            .fontSize(24)
            .fontColor([$r('sys.color.font_primary')])
        }
        .buttonStyle(ButtonStyleMode.NORMAL)
        .size({ width: 40, height: 40 })
        .onClick(() => {
          if (this.hasSteamKey) {
            this.dialogControllerList_withoutSteam.open()
          } else {
            this.dialogControllerList.open()
          }
        })
      } else if (this.currentIndex === 1) {
        Select([{ value: this.TOTPList_Steam[0].alias, icon: "" }])
          .selected(0)
          .value("账号")
          .font({ size: 16, weight: 500 })
          .fontColor($r('sys.color.font_primary'))
          .selectedOptionFont({ size: 16, weight: 400 })
          .optionFont({ size: 16, weight: 400 })
          .space(8)
          .arrowPosition(ArrowPosition.END)
          .menuAlign(MenuAlignType.START, {dx:0, dy:0})
          .optionWidth(200)
          .optionHeight(300)
          .onSelect((index:number, text?: string | undefined)=>{
            // console.info('Select:' + index)
            // this.index = index;
            // if(text){
            //   this.text = text;
            // }
          });
      }
    }
    .width("60%")
    .height("100%")
    .margin({ right: 12 })
    .justifyContent(FlexAlign.End)
  };

  // 导航栏
  private tabsController: TabsController = new TabsController()

  private addTOTPKeyByInput(): SheetInfo {
    return {
      title: '手动输入 TOTP 验证码参数',
      action: () => {
        this.newTOTPItem.open();
      }
    };
  }

  private addTOTPKeyByScan(): SheetInfo {
    return {
      title: '扫码添加',
      action: async () => {
        try {
          hilog.info(Constants.DOMAIN, TAG, "The ADD button was clicked");

          CatchSecretByScan(this.context).then((value) => {
            this.rawSecretParam = value.raw;
            const secretParam = value.SecretParams;
            this.secret = secretParam.secret;
            this.digit = secretParam.digits;
            this.algorithm = secretParam.algorithm;
            this.timeStep = secretParam.period;

            hilog.info(Constants.DOMAIN, TAG, "The SECRET accepted: %{private}s", String(this.alias));

            this.editTOTPItem.open();
            hilog.info(Constants.DOMAIN, TAG, "The editTOTPItem DIALOG opened");
          });

          // 等待用户输入
          while (!this.CustomDialog_editTOTPItemIsClosed) {
            await new Promise<void>(resolve => setTimeout(resolve, 100));
          }

          if (this.isConfirm) {
            hilog.debug(Constants.DOMAIN, TAG, "The edited alias is %{public}s", this.alias);

            await this.writeToJson.write({
              type: "normal",
              alias: this.alias,
              secret: this.secret,
              digit: this.digit,
              timeStep: this.timeStep,
              algorithm: this.algorithm,
              raw: this.rawSecretParam
            });
            hilog.debug(Constants.DOMAIN, TAG, "WriteToJson completed", this.alias);

            // 控制页面刷新
            this.hasKey = true;
            this.refresh = true;
            this.CustomDialog_editTOTPItemIsClosed = false;
            logger.info(Constants.DOMAIN, TAG, "The SECRET(%{public}s) has been added", this.alias);
          }
        } catch (e) {
          promptAction.showToast({
            message: `错误：${e.message} (${TAG})`,
            duration: 2000
          });
          logger.error(Constants.DOMAIN, TAG, "ADD button: %{public}s", String(e));
        }
      }
    };
  }

  @Builder tabBuilder(targetIndex: number, selectedImg: Resource, normalImg: Resource, title?: Resource) {
    Column() {
      if (targetIndex === 1) {
        Image(this.currentIndex === targetIndex ? selectedImg : normalImg)
          .size({ height: 32, width: 32 })
      } else {
        SymbolGlyph(this.currentIndex === targetIndex ? selectedImg : normalImg)
          .fontSize($r("app.float.Title"))
      }

      /*Text(title)
        .fontColor(this.currentIndex === targetIndex ? '#1698CE' : '#6B6B6B')
        .fontSize($r("app.float.content"))*/
    }
    .width('100%')
    .height("100%")
    .justifyContent(FlexAlign.Center)
  }

  // 生命周期函数
  async onPageShow(): Promise<void> {
    this.onForeground = true;

    this.preferences.get("disclaimerIsConfirm", false).then((value) => {
      hilog.debug(Constants.DOMAIN, TAG, "The disclaimerIsConfirm is: %{public}s", value.toString())

      if (!value) {
        this.disclaimer.open();
      }
    });

    this.preferences.get(Constants.SETTINGS_USERAUTH, false).then((value: preferences.ValueType) => {
      hilog.debug(Constants.DOMAIN, TAG, "The UserAuth is: %{public}s", value.toString())

      if (value) {
        UserAuth().then((result) => {
          if (result === 12500000) {
            this.login = true
          }
        })
      } else {
        this.login = true
      }
    });

    this.preferences.get("hasSteamKey", false).then((value) => {
      hilog.debug(Constants.DOMAIN, TAG, "The disclaimerIsConfirm is: %{public}s", value.toString())

      if (value) {
        this.hasSteamKey = value as boolean;
      }
    });

    // 校验 JSON 文件是否存在数据
    try {
      this.hasKey = await this.writeToJson.isExist(undefined, "normal");
    } catch (e) {
      logger.error(Constants.DOMAIN, TAG, "Detect whether to add a key fatal: %{public}s", String(e));
    }

    try {
      const filePath = getContext(this).filesDir + "/secret.json"
      const file = (await fs.open(filePath, fs.OpenMode.READ_ONLY));
      await fs.readText(file.path).then(async (value: string) => {
        const content: ISecretItem[] =  JSON.parse(value.replace(/[\u0000-\u001F\u007F-\u009F]/g, "").trim())
        this.TOTPList_Steam = content.filter(item => item.type === "steam") as SecretClass[];
        fs.close(file.fd);
      })
    } catch (e) {
      // logger.error(Constants.DOMAIN, TAG, "Detect whether to add a key fatal: %{public}s", String(e));
    }
  }

  onPageHide(): void {
    this.onForeground = false;
  }

  build() {
    if (this.login) {
      this.Index()
    } else {
      UserAuthView()
    }
  }

  @Builder
  Index() {
    Navigation(this.pathStack) {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex, controller: this.tabsController }) {
        TabContent() {
          if (this.hasKey) {
            HomePage({ pathStack: this.pathStack, refresh: this.refresh, onForeground: this.onForeground });
          } else {
            NoKeyInJSON({ hasKey: this.hasKey });
          }
        }
        .tabBar(this.tabBuilder(0, $r('sys.symbol.house_fill'), $r('sys.symbol.house')))
        .backgroundColor($r('app.color.background'))
        .padding({ top: 18 });

        if (this.hasSteamKey) {
          TabContent() {
            SteamTOTPView()
          }
          .tabBar(this.tabBuilder(1, $r('app.media.steam_logo_symbol_fill'), $r("app.media.steam_logo_symbol")))
          .backgroundColor($r('app.color.background'))
          .padding({ top: 36 });
        }

        TabContent() {
          Settings();
        }
        .tabBar(this.tabBuilder(2, $r('sys.symbol.gearshape_fill'), $r('sys.symbol.gearshape')))
        .backgroundColor($r('app.color.background'));
      }
      .scrollable(false)
      .vertical(false)
      .barMode(BarMode.Fixed)
      .width("100%")
      .height("100%")
      .margin({ top: "3%" })
      .backgroundColor($r('app.color.tabBar'))
      .onChange((index: number) => {
        this.currentIndex = index;
      });
    }
    .mode(NavigationMode.Auto)
    .title(this.Title(),
      {
        'barStyle': BarStyle.STACK,
        'backgroundColor': $r('app.color.titleBar'),
      }
    )
    .titleMode(NavigationTitleMode.Mini)
    .hideBackButton(true)
    .menus(this.TitleMenuItem())
    .backgroundColor($r('app.color.background'))
  }
}
