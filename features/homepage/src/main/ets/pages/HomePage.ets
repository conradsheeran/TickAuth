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

import { Constants } from "../common/Constants"
import { TOTP } from "../view/TOTPView"

@Component
export struct HomePage {
  @Link pathStack: NavPathStack;
  @Link onForeground: boolean;
  @Link refresh: boolean;

  build() {
    Column() {
      if (this.onForeground || this.refresh) {
        TOTP({ pathStack: this.pathStack, refresh: this.refresh, onForeground: this.onForeground })
      } else {
        TOTP({ pathStack: this.pathStack, refresh: this.refresh, onForeground: this.onForeground })
      }
    }
    .height(Constants.HOMEPAGE_SIZE)
    .width(Constants.HOMEPAGE_SIZE)
    .padding({ top: $r('app.float.HomePage_padding') })
  }
}
