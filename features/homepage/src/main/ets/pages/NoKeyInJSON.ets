import { Constants } from "../common/Constants";
import { CustomDialog_editTOTPItem } from "../uicomponent/EditTOTPItem";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { CatchSecretByScan } from "../model/CatchSecretByScan";
import { Logger, SecretParams, WriteToJson } from "utils";
import { common } from "@kit.AbilityKit";

const TAG: string = "NoKeyInJSON"
const logger = new Logger(getContext(this))

@Component
export struct NoKeyInJSON {
  @State alias: string = "default";
  @Link hasKey: boolean;
  @State CustomDialog_editTOTPItemIsClosed: boolean = false;

  private context = getContext(this) as common.UIAbilityContext;
  private secret: SecretParams = {
    secret: "",
    algorithm: "SH1",
    digits: 6,
    period: 30,
    issuer: "default"
  };
  private writeToJson = new WriteToJson(this.context.filesDir + Constants.SECRET_FILE_DIR)

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

  build() {
    Row() {
      Column() {
        Image($r('app.media.plus_square'))
          .size({ height: $r('app.float.NoKeyInJSON_Image_size'), width: $r('app.float.NoKeyInJSON_Image_size') })
          .margin({ bottom: Constants.NOKEYINJSON_IMAGE_MARGIN })
          .onClick(async () => {
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

              await this.writeToJson.write({ "alias": this.secret.issuer, "secret": this.secret.secret });
              hilog.debug(Constants.DOMAIN, TAG, "WriteToJson completed", this.secret.issuer)

              this.hasKey = true;
              this.CustomDialog_editTOTPItemIsClosed = false
              logger.info(Constants.DOMAIN, TAG, "The SECRET(%{public}s) has been added", this.secret.issuer)
            } catch (e) {
              logger.error(Constants.DOMAIN, TAG, "ADD button: %{public}s", String(e));
            }
          })

        Text($r('app.string.NoKeyInJSON_content'))
          .fontSize($r('app.float.NoKeyInJSON_fontsize'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.NoKeyInJSON_fontcolor'))
      }
      .width(Constants.HOMEPAGE_SIZE)
    }
    .height(Constants.HOMEPAGE_SIZE)
  }
}
