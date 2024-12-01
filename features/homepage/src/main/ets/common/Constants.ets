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

export class Constants {
  static readonly DOMAIN: number = 0x00201;

  static readonly SECRET_FILE_DIR: string = "/secret.json";

  static readonly HOMEPAGE_SIZE: string = "100%";

  static readonly TOTPVIEW_LIST_SIZE: string = "100%";

  static readonly TOTPVIEW_LIST_SPACE: number = 12;

  static readonly TOTPVIEW_LISTITEM_MAXLINE: number = 1;

  static readonly TOTPVIEW_LISTITEM_TOTP_WIDTH: string = "50%";

  static readonly TOTPVIEW_LISTITEM_TOTP_HEIGHT: string = "50%";

  static readonly TOTPVIEW_LISTITEM_WIDTH: string = "100%";

  static readonly TOTPVIEW_LISTITEM_HEIGHT: string = "13.5%";

  static readonly NOKEYINJSON_IMAGE_MARGIN: string = "7%";

  static readonly ANIMATION_DURING: number = 500;
}