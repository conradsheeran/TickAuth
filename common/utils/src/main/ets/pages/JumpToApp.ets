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

import { Want, common } from '@kit.AbilityKit';

export function JumpToApp(context: common.UIAbilityContext, bundleName: string, abilityName: string, uri?: string): void {
  let want: Want = {
    bundleName: bundleName,
    abilityName: abilityName,
    uri: uri
  };
  context.startAbility(want);
}