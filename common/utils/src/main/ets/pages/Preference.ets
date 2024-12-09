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

import { preferences } from "@kit.ArkData"

export class Preference {
  context: Context;
  fileName: string;
  preferences: Promise<preferences.Preferences>;

  constructor(context: Context, fileName: string) {
    this.context = context;
    this.fileName = fileName;
    this.preferences = preferences.getPreferences(this.context, this.fileName);
  }

  public async has(name: string) {
    return (await this.preferences).hasSync(name);
  }

  public async get(name: string, defValue: preferences.ValueType): Promise<string | number | bigint | boolean | Object> {
    return (await this.preferences).getSync(name, defValue)
  }

  public async put(name: string, value: preferences.ValueType) {
    const preferences = await this.preferences;

    preferences.putSync(name, value);
    preferences.flush();
  }
}