import { common } from '@kit.AbilityKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { fileIo as fs } from "@kit.CoreFileKit"
import { CustomDialog_disclaimer } from '../uicomponent/Disclaimer'
import { HomePage, NoKeyInJSON } from "homepage"
import { Settings } from "settings"
import { CatchSecretByScan } from "../model/CatchSecretByScan"
import { SecretParams, WriteToJson, Logger } from "utils"
import { CustomDialog_editTOTPItem } from '../uicomponent/EditTOTPItem';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Constants } from '../common/Constants';

const TAG: string = "Index"
const logger = new Logger(getContext(this))

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @State hasKey: boolean = true;
  @State CustomDialog_editTOTPItemIsClosed: boolean = false;
  @State alias: string = "default";

  // SYSTEM ICON
  private plus: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.plus'));

  // Add the necessary data needed for the SECRET
  private context = getContext(this) as common.UIAbilityContext;
  private secretFileDir: string = this.context.filesDir + Constants.SECRET_FILE_DIR;
  private secret: SecretParams = {
    secret: "",
    algorithm: "SH1",
    digits: 6,
    period: 30,
    issuer: "default"
  };

  // The main interface UI Component Controller
  private TitleMenuItem: NavigationMenuItem = {
    'value':"",
    'symbolIcon': this.plus,
    'action': async () => {
      try {
        /*this.secret = {
          issuer: '',
          secret: 'RUUHXR4GSMMKJ6A4P3J6DKOEVAORGFSZ'
        }*/

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

        await WriteToJson(this.secretFileDir, { "alias": this.secret.issuer, "secret": this.secret.secret });
        hilog.debug(Constants.DOMAIN, TAG, "WriteToJson completed", this.secret.issuer)

        this.hasKey = true;
        this.CustomDialog_editTOTPItemIsClosed = false
        logger.info(Constants.DOMAIN, TAG, "The SECRET has been added", this.secret.issuer)
      } catch (e) {
        logger.error(Constants.DOMAIN, TAG, "ADD button: %{public}s", String(e));
      }
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
          let preferences: Promise<preferences.Preferences> = this.getPreferences(this, "Preferences");
          preferences.then((result: preferences.Preferences) => {
            result.put("disclaimerIsConfirm", false);
            result.flush();
          });
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

  // INTERNAL FUNCTION
  private getPreferences(common: Object, fileName: string) {
    return preferences.getPreferences(getContext(common), fileName);
  }

  // LIFECYCLE
  async onPageShow(): Promise<void> {
    // Detect whether the user agrees to the disclaimer
    this.getPreferences(this, "Preferences").then((preferences: preferences.Preferences) => {
      preferences.get("disclaimerIsConfirm", true).then((value: preferences.ValueType) => {
        hilog.debug(Constants.DOMAIN, TAG, "The disclaimerIsConfirm is: %{public}s", value.toString())

        if (value) {
          this.disclaimer.open();
        }
      });
    });

    // Detect whether to add a key
    try {
      this.hasKey = await fs.access(this.secretFileDir);
      hilog.debug(Constants.DOMAIN, TAG, "No Keys in the JSON")
    } catch (e) {
      logger.error(Constants.DOMAIN, TAG, "Detect whether to add a key fatal: %{public}s", String(e));
    }
  }

  pageStack: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.pageStack) {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex, controller: this.tabsController }) {
        TabContent() {
          if (this.hasKey) {
            HomePage()
          } else {
            NoKeyInJSON();
          }
        }
        .tabBar(this.tabBuilder(0, $r('sys.symbol.house_fill'), $r('sys.symbol.house')))
        .backgroundColor($r('app.color.background'))
        .padding({ top: 18 })

        TabContent() {
          Settings();
        }
        .tabBar(this.tabBuilder(1, $r('sys.symbol.gearshape_fill'), $r('sys.symbol.gearshape')))
        .backgroundColor($r('app.color.background'))
      }
      .scrollable(false)
      .vertical(false)
      .barMode(BarMode.Fixed)
      .width("100%")
      .height("100%")
      .margin({ top: "3%" })
      .backgroundColor($r('app.color.tabBar'))
      .onChange((index: number) => {
        this.currentIndex = index
      })
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
