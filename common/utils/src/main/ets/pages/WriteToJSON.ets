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

import { fileIo as fs } from '@kit.CoreFileKit';
import { JSON } from "@kit.ArkTS"
import { Logger } from './Logger';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Constants } from '../common/Constants';

const TAG: string = "WriteToJson";
const logger = new Logger(getContext(this))

export interface SecretItem {
  alias: string;
  secret: string;
}

export class WriteToJson {
  private filePath: string;

  constructor(filePath: string) {
    this.filePath = filePath;
  }

  private async readJsonFile(): Promise<SecretItem[]> {
    let dataArray: SecretItem[] = [];

    try {
      const res: boolean = await fs.access(this.filePath);
      if (res) {
        const fileContent = await fs.readText(this.filePath);
        if (fileContent.trim().length !== 0) {
          const data = JSON.parse(fileContent);
          dataArray = Array.isArray(data) ? data : [data];
        }
      }
    } catch (e) {
      logger.warn(Constants.DOMAIN, TAG, "File not found or empty, creating a new one.");
    }

    return dataArray;
  }

  private async writeJsonFile(dataArray: SecretItem[]): Promise<void> {
    const fd = (
      await fs.open(this.filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC)
    ).fd;
    await fs.write(fd, JSON.stringify(dataArray, null, 2));
    fs.close(fd)
  }

  async write(newItem: SecretItem): Promise<void> {
    hilog.info(Constants.DOMAIN, TAG, "Write mode start");

    try {
      const dataArray = await this.readJsonFile();
      const index = dataArray.findIndex((item) => item.alias === newItem.alias);

      if (index !== -1) {
        dataArray[index] = newItem;
        hilog.warn(
          Constants.DOMAIN,
          TAG,
          "%{public}s(Alias) already exists and has overwritten the original data",
          newItem.alias
        );
      } else {
        dataArray.push(newItem);
        hilog.info(Constants.DOMAIN, TAG, "%{public}s(Alias) added successfully", newItem.alias);
      }

      await this.writeJsonFile(dataArray);
      hilog.info(Constants.DOMAIN, TAG, "Write mode succeed");
    } catch (e) {
      logger.fatal(Constants.DOMAIN, TAG, "Write mode fatal: %{public}s", String(e));
      throw new Error(`Write mode fatal: ${e}`);
    }
  }

  async append(jsonString: string): Promise<void> {
    hilog.info(Constants.DOMAIN, TAG, "Append mode start");

    try {
      const dataArray = await this.readJsonFile();
      const newContent = JSON.parse(jsonString);

      if (!Array.isArray(newContent)) {
        throw new Error("Provided string content must be a JSON array.");
      }

      newContent.forEach((newItem: SecretItem) => {
        const index = dataArray.findIndex((item) => item.alias === newItem.alias);

        if (index !== -1) {
          dataArray[index] = newItem;
          hilog.warn(
            Constants.DOMAIN,
            TAG,
            "%{public}s(Alias) already exists and has overwritten the original data",
            newItem.alias
          );
        } else {
          dataArray.push(newItem);
          hilog.info(Constants.DOMAIN, TAG, "%{public}s(Alias) added successfully", newItem.alias);
        }
      });

      await this.writeJsonFile(dataArray);
      hilog.info(Constants.DOMAIN, TAG, "Append mode succeed");
    } catch (e) {
      logger.fatal(Constants.DOMAIN, TAG, "Append mode fatal: %{public}s", String(e));
      throw new Error(`Append mode fatal: ${e}`);
    }
  }

  async edit(oldItem: SecretItem, newItem: SecretItem): Promise<void> {
    hilog.info(Constants.DOMAIN, TAG, "Edit mode start");

    try {
      const dataArray = await this.readJsonFile();
      const index = dataArray.findIndex((item) => item.alias === oldItem.alias);

      if (index !== -1) {
        if (JSON.stringify(dataArray[index]) === JSON.stringify(oldItem)) {
          dataArray[index] = newItem;
          hilog.info(
            Constants.DOMAIN,
            TAG,
            "%{public}s(Alias) successfully updated to %{public}s(Alias)",
            oldItem.alias,
            newItem.alias
          );
        } else {
          throw new Error("Old item does not match the existing data.");
        }
      } else {
        throw new Error(`Item with alias "${oldItem.alias}" not found.`);
      }

      await this.writeJsonFile(dataArray);
      hilog.info(Constants.DOMAIN, TAG, "Edit mode succeed");
    } catch (e) {
      logger.fatal(Constants.DOMAIN, TAG, "Edit mode fatal: %{public}s", String(e));
      throw new Error(`Edit mode fatal: ${e}`);
    }
  }

  async remove(alias: string): Promise<boolean> {
    hilog.info(Constants.DOMAIN, TAG, "Remove mode start");

    try {
      const fileExists = await fs.access(this.filePath);

      if (fileExists) {
        const dataArray = await this.readJsonFile();
        const filteredArray = dataArray.filter((item) => item.alias !== alias);

        await this.writeJsonFile(filteredArray);
        hilog.info(
          Constants.DOMAIN,
          TAG,
          "%{public}s(Alias) removed successfully, remaining items: %{public}d",
          alias,
          filteredArray.length
        );

        return filteredArray.length > 0;
      } else {
        hilog.info(Constants.DOMAIN, TAG, "Remove: File does not exist.");
        return false;
      }
    } catch (e) {
      logger.fatal(Constants.DOMAIN, TAG, "Remove mode fatal: %{public}s", String(e));
      return false;
    }
  }

  async hasSecret(): Promise<boolean> {
    hilog.info(Constants.DOMAIN, TAG, "HasSecret mode start");

    try {
      const fileExists = await fs.access(this.filePath);

      if (fileExists) {
        const dataArray = await this.readJsonFile();
        const hasData = dataArray.length > 0;
        hilog.info(
          Constants.DOMAIN,
          TAG,
          "HasSecret: File exists and contains %{public}d item(s).",
          dataArray.length
        );
        return hasData;
      } else {
        hilog.info(Constants.DOMAIN, TAG, "HasSecret: File does not exist.");
        return false;
      }
    } catch (e) {
      logger.fatal(Constants.DOMAIN, TAG, "HasSecret mode fatal: %{public}s", String(e));
      return false;
    }
  }
}

