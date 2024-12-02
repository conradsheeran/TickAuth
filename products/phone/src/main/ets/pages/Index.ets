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
import { SelectDialog, SymbolGlyphModifier } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { CustomDialog_disclaimer } from '../uicomponent/Disclaimer'
import { HomePage, NoKeyInJSON } from "homepage"
import { Settings } from "settings"
import { CatchSecretByScan } from "../model/CatchSecretByScan"
import { SecretParams, WriteToJson, Logger, Preference } from "utils"
import { CustomDialog_editTOTPItem } from '../uicomponent/EditTOTPItem';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Constants } from '../common/Constants';
import { UserAuth } from '../model/UserAuth';
import { UserAuthView } from '../view/UserAuth';
import { CustomDialog_NewTOTPItem } from '../uicomponent/NewTOTPItem';

const TAG: string = "Index"
const logger = new Logger(getContext(this))

@Entry
@Component
struct Index {
  @LocalStorageLink("login") login: boolean = false;
  @LocalStorageLink("hasKey") hasKey: boolean = false;
  @LocalStorageLink("refresh") refresh: boolean = false;
  @State CustomDialog_editTOTPItemIsClosed: boolean = false;
  @State alias: string = "default";
  @State currentIndex: number = 0;
  @State onForeground: boolean = false;

  dialogControllerList: CustomDialogController = new CustomDialogController({
    builder: SelectDialog({
      title: '请选择一种添加方式',
      selectedIndex: 2,
      confirm: {
        value: '取消',
        action: () => {
          //
        },
      },
      radioContent: [
        {
          title: '扫码添加',
          action: async () => {
            try {
              hilog.info(Constants.DOMAIN, TAG, "The ADD button was clicked")

              this.secret = await CatchSecretByScan(this.context);
              hilog.info(Constants.DOMAIN, TAG, "The SECRET accepted: %{private}s", String(this.secret.issuer))

              this.editTOTPItem.open()
              hilog.info(Constants.DOMAIN, TAG, "The editTOTPItem DIALOG opened")

              // Wait for the user to complete the input
              while (!this.CustomDialog_editTOTPItemIsClosed) {
                await new Promise<void>(resolve => setTimeout(resolve, 100));
              }

              this.secret.issuer = this.alias;
              hilog.debug(Constants.DOMAIN, TAG, "The edited alias is %{public}s", this.secret.issuer)

              await this.writeToJson.write({ "alias": this.secret.issuer, "secret": this.secret.secret });
              hilog.debug(Constants.DOMAIN, TAG, "WriteToJson completed", this.secret.issuer)

              this.hasKey = true;
              this.refresh = true;
              this.CustomDialog_editTOTPItemIsClosed = false
              logger.info(Constants.DOMAIN, TAG, "The SECRET(%{public}s) has been added", this.secret.issuer)
            } catch (e) {
              logger.error(Constants.DOMAIN, TAG, "ADD button: %{public}s", String(e));
            }
          }
        },
        {
          title: '手动输入 TOTP 验证码参数',
          action: () => {
            this.newTOTPItem.open()
          }
        }
      ]
    })
  })

  // SYSTEM ICON
  private plus: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.plus'));

  // Add the necessary data needed for the SECRET
  private context = getContext(this) as common.UIAbilityContext;
  private secret: SecretParams = {
    secret: "",
    algorithm: "SH1",
    digits: 6,
    period: 30,
    issuer: "default"
  };
  private writeToJson = new WriteToJson(this.context.filesDir + Constants.SECRET_FILE_DIR)
  private preferences = new Preference(this.context, "Preferences")

  // The main interface UI Component Controller
  private TitleMenuItem: NavigationMenuItem = {
    'value':"",
    'symbolIcon': this.plus,
    'action': async () => {
      this.dialogControllerList.open()
    }
  };

  private tabsController: TabsController = new TabsController()
  @Builder tabBuilder(targetIndex: number, selectedImg: Resource, normalImg: Resource, title?: Resource) {
    Column() {
      SymbolGlyph(this.currentIndex === targetIndex ? selectedImg : normalImg)
        .fontSize($r("app.float.Title"))

      /*Text(title)
        .fontColor(this.currentIndex === targetIndex ? '#1698CE' : '#6B6B6B')
        .fontSize($r("app.float.content"))*/
    }
    .width('100%')
    .height("100%")
    .justifyContent(FlexAlign.Center)
  }

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
    builder: CustomDialog_editTOTPItem(
      {
        cancel: () => {
          this.CustomDialog_editTOTPItemIsClosed = true
        },

        confirm: () => {
          this.CustomDialog_editTOTPItemIsClosed = true
        },

        alias: $alias
      }),

    customStyle: true,

    onWillDismiss:(dismissDialogAction: DismissDialogAction)=> {
      hilog.debug(Constants.DOMAIN, TAG, "editTOTPItem: User try to exit. Action: %{public}s", dismissDialogAction.reason.toString())
    }
  });

  newTOTPItem: CustomDialogController = new CustomDialogController({
    builder: CustomDialog_NewTOTPItem(
      {
        cancel: () => {
          this.CustomDialog_editTOTPItemIsClosed = true
        },

        confirm: () => {
          this.CustomDialog_editTOTPItemIsClosed = true
        },
      }),

    customStyle: true,

    onWillDismiss:(dismissDialogAction: DismissDialogAction)=> {
      hilog.debug(Constants.DOMAIN, TAG, "editTOTPItem: User try to exit. Action: %{public}s", dismissDialogAction.reason.toString())
    }
  });

  // LIFECYCLE
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

    // Detect whether to add a key
    try {
      this.hasKey = await this.writeToJson.hasSecret();
    } catch (e) {
      logger.error(Constants.DOMAIN, TAG, "Detect whether to add a key fatal: %{public}s", String(e));
    }
  }

  pageStack: NavPathStack = new NavPathStack();

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
    Navigation(this.pageStack) {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex, controller: this.tabsController }) {
        TabContent() {
          if (this.hasKey) {
            HomePage({ refresh: this.refresh, onForeground: this.onForeground });
          } else {
            NoKeyInJSON({ hasKey: this.hasKey });
          }
        }
        .tabBar(this.tabBuilder(0, $r('sys.symbol.house_fill'), $r('sys.symbol.house')))
        .backgroundColor($r('app.color.background'))
        .padding({ top: 18 });

        TabContent() {
          Settings();
        }
        .tabBar(this.tabBuilder(1, $r('sys.symbol.gearshape_fill'), $r('sys.symbol.gearshape')))
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
    .title($r('app.string.Title'),
      {
        'barStyle': BarStyle.STACK,
        'backgroundColor': $r('app.color.titleBar'),
      }
    )
    .titleMode(NavigationTitleMode.Mini)
    .hideBackButton(true)
    .menus([this.TitleMenuItem])
    .backgroundColor($r('app.color.background'))
  }
}
