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
import { AddSteamTOTP } from "../view/AddSteamTOTP";
import { SymbolGlyphModifier } from "@kit.ArkUI";

@Component
export struct SteamPage {
  @Consume("pathStack") pathStack: NavPathStack;

  private plus: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.plus'));
  private refreshSymbol: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise'));

  private TitleMenuItem1: NavigationMenuItem = {
    'value':"",
    'symbolIcon': this.refreshSymbol,
    'action': () => {
      //
    }
  };

  private TitleMenuItem2: NavigationMenuItem = {
    'value':"",
    'symbolIcon': this.plus,
    'action': () => {
      //
    }
  };

  build() {
    NavDestination() {
      Column() {
        AddSteamTOTP()
      }
      .width('100%')
      .height('100%')
    }
    .backgroundColor("#F8F4ED")
    .title('Steam', { backgroundColor: "#93B5CF" })
    .menus([this.TitleMenuItem1, this.TitleMenuItem2])
    .onBackPressed(() => {
      this.pathStack.pop()
      return true;
    })
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}

@Builder
export function SteamPageBuilder(name: string, param: Object) {
  SteamPage()
}