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
        .fontSize(120)
        .margin({ top: "20%", bottom: 12 })

      Text() {
        Span("● 请保证导入的密钥文件格式正确：")
          .fontColor(Color.Gray)
        Span("示例文件")
          .fontColor("#FF0A59F7")
          .decoration({
            type: TextDecorationType.Underline,
            color: "#FF0A59F7"
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
      .margin({ top: 48 })
      .width("80%")
      .fontSize(12)

      Row() {
        Button("导入密钥文件")
          .backgroundColor("#4e7ca1")
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

        Button("导出密钥文件")
          .backgroundColor("#4e7ca1")
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
      .margin({ top: "20%" })
      .width("80%")

    }
    .width("100%")
    .height("100%")
    .backgroundColor($r('app.color.start_window_background'))
    .justifyContent(FlexAlign.Center)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}