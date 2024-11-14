import { fileIo as fs } from '@kit.CoreFileKit';
import { JSON } from "@kit.ArkTS"
import { Logger } from './Logger';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Constants } from '../common/Constants';

const TAG: string = "WriteToJson";
const logger = new Logger(getContext(this))

interface SecretItem {
  alias: string;
  secret: string;
}

export async function WriteToJson(filePath: string, newItem: SecretItem): Promise<void> {
  hilog.info(Constants.DOMAIN, TAG, "WriteToJson Start")

  try {
    let dataArray: SecretItem[] = [];

    const res: boolean = await fs.access(filePath);
    if (res) {
      hilog.debug(Constants.DOMAIN, TAG, "Access to SECRET JSON file succeed")
      const fileContent = await fs.readText(filePath);

      if (fileContent.trim().length !== 0) {
        const data = JSON.parse(fileContent);
        dataArray = Array.isArray(data) ? data : [data];
      }
    }

    const fd = (await fs.open(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC)).fd;
    const index = dataArray.findIndex((item) => item.alias === newItem.alias);

    if (index !== -1) {
      dataArray[index] = newItem;
      logger.warn(Constants.DOMAIN, TAG, "%{public}s(Alias) already exists and has overwritten the original data", newItem.alias)
    } else {
      dataArray.push(newItem);
      hilog.info(Constants.DOMAIN, TAG, "%{public}s(Alias) added successfully", newItem.alias)
    }
    await fs.write(fd, JSON.stringify(dataArray, null, 2));
    hilog.info(Constants.DOMAIN, TAG, "WriteToJson Succeed")
  } catch (e) {
    logger.fatal(Constants.DOMAIN, TAG, "WriteToJson fatal: %{public}s", String(e))
    throw new Error(`WriteToJson fatal: ${e}`);
  }
}

// Not yet tested
export async function RemoveFromJson(filePath: string, name: string): Promise<void> {
  fs.access(filePath).then(async (res: boolean) => {
    if (res) {
      const fileContent = await fs.readText(filePath);
      let dataArray: SecretItem[] = [];

      if (fileContent.trim().length !== 0) {
        const data = JSON.parse(fileContent);
        dataArray = Array.isArray(data) ? data : [data];
        dataArray = dataArray.filter((item) => item.alias !== name);

        const fd = (await fs.open(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC)).fd;
        await fs.write(fd, JSON.stringify(dataArray, null, 2));
      }
    } else {
      hilog.info(Constants.DOMAIN, TAG, "RemoveFromJson: The file does not exist")
    }
  })
}
