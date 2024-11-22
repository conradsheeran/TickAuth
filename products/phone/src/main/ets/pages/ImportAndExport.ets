import  { picker } from '@kit.CoreFileKit';
import { bufferToString, Logger, WriteToJson } from "utils";
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { Constants } from '../common/Constants';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { buffer } from '@kit.ArkTS';

const TAG: string = "ImportAndExport"
const logger = new Logger(getContext(this))

@Entry
@Component
struct ImportAndExport {
  @StorageLink("refresh") refresh: boolean = false;

  private context = getContext(this) as common.UIAbilityContext;
  private secretFileDir = this.context.filesDir + Constants.SECRET_FILE_DIR;

  build() {
    Column() {
      SymbolGlyph($r('sys.symbol.doc_text'))
        .fontSize($r('app.float.ImportAndExport_Symbol_size'))
        .margin({ top: Constants.IMPORTANDEXPORT_ITEM_MARGIN, bottom: $r('app.float.ImportAndExport_Symbol_margin') })

      Text() {
        Span($r('app.string.ImportAndExport_explanation_1'))
          .fontColor(Color.Gray)
        Span($r('app.string.ImportAndExport_explanation_2'))
          .fontColor($r('app.color.ImportAndExport_explanation_fontcolor'))
          .decoration({
            type: TextDecorationType.Underline,
            color: $r('app.color.ImportAndExport_explanation_fontcolor')
          })
          .onClick(() => {
            const documentSaveOptions = new picker.DocumentSaveOptions();
            documentSaveOptions.newFileNames = ["请选择一个文件夹保存示例文件.json"];
            documentSaveOptions.fileSuffixChoices = ['.json'];

            const documentViewPicker = new picker.DocumentViewPicker(this.context);
            documentViewPicker.save(documentSaveOptions).then((documentSaveResult: Array<string>) => {
              fs.open(documentSaveResult[0], fs.OpenMode.READ_WRITE).then(async (file) => {
                getContext(this).resourceManager.getRawFileContent("demo.json").then((content) => {
                  WriteToJson(file.path, bufferToString(content), "append")
                })
              })
            }).catch((e: BusinessError) => {
              logger.error(Constants.DOMAIN, TAG, "documentViewPicker.save Fatal: %{public}s code: {public}d", e.message, e.code)
            })
          })
      }
      .margin({ top: $r('app.float.ImportAndExport_Explanation_margin') })
      .width(Constants.IMPORTANDEXPORT_ITEM_WIDTH)
      .fontSize($r('app.float.ImportAndExport_Explanation_fontsize'))

      Row() {
        Button($r('app.string.ImportAndExport_Button_import'))
          .backgroundColor($r('app.color.ImportAndExport_Button_color'))
          .onClick(() => {
            let documentSelectOptions = new picker.DocumentSelectOptions();
            documentSelectOptions.maxSelectNumber = 1;
            documentSelectOptions.fileSuffixFilters = ["json"];

            let documentPicker = new picker.DocumentViewPicker(this.context);
            documentPicker.select(documentSelectOptions).then((documentSelectResult: Array<string>) => {
              fs.open(documentSelectResult[0], fs.OpenMode.READ_ONLY).then((file) => {
                let arrayBuffer = new ArrayBuffer(4096);
                fs.read(file.fd, arrayBuffer).then((readLen) => {
                  let buf = buffer.from(arrayBuffer, 0, readLen);
                  WriteToJson(this.secretFileDir, bufferToString(new Uint8Array(buf.buffer)).replace(/[\u0000-\u001F\u007F-\u009F]/g, "").trim(), "append").then(() => {
                    this.refresh = true;
                    hilog.info(Constants.DOMAIN, TAG, "WriteToJson Succeed")
                  })
                }).catch((e: BusinessError) => {
                  logger.error(Constants.DOMAIN, TAG, "Read JSON file fatal: %{public}s", String(e))
                })
              })
              hilog.info(Constants.DOMAIN, TAG, "WriteToJson Succeed")
            }).catch((e: BusinessError) => {
              logger.error(Constants.DOMAIN, TAG, "documentViewPicker.select Fatal: %{public}s code: {public}d", e.message, e.code)
            });
          })

        Blank()

        Button($r('app.string.ImportAndExport_Button_export'))
          .backgroundColor($r('app.color.ImportAndExport_Button_color'))
          .onClick(() => {
            const documentSaveOptions = new picker.DocumentSaveOptions();
            documentSaveOptions.newFileNames = ["secret.json"];
            documentSaveOptions.fileSuffixChoices = ['.json'];

            const documentViewPicker = new picker.DocumentViewPicker(this.context);
            documentViewPicker.save(documentSaveOptions).then((documentSaveResult: Array<string>) => {
              fs.open(documentSaveResult[0], fs.OpenMode.READ_WRITE).then((file) => {
                fs.copyFile(this.secretFileDir, file.fd).then(() => {
                  hilog.debug(Constants.DOMAIN, TAG, "copyFile: Export Succeed")
                }).catch((e: BusinessError) => {
                  logger.error(Constants.DOMAIN, TAG, "copyFile Fatal: %{public}s code: {public}d", e.message, e.code)
                });
              })
            }).catch((e: BusinessError) => {
              logger.error(Constants.DOMAIN, TAG, "documentViewPicker.save Fatal: %{public}s code: {public}d", e.message, e.code)
            })
          })
      }
      .margin({ top: Constants.IMPORTANDEXPORT_ITEM_MARGIN })
      .width(Constants.IMPORTANDEXPORT_ITEM_WIDTH)

    }
    .width(Constants.IMPORTANDEXPORT_SIZE)
    .height(Constants.IMPORTANDEXPORT_SIZE)
    .backgroundColor($r('app.color.background'))
    .justifyContent(FlexAlign.Center)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}