{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2015, SAS.Planet development team.                      *}
{* This program is free software: you can redistribute it and/or modify       *}
{* it under the terms of the GNU General Public License as published by       *}
{* the Free Software Foundation, either version 3 of the License, or          *}
{* (at your option) any later version.                                        *}
{*                                                                            *}
{* This program is distributed in the hope that it will be useful,            *}
{* but WITHOUT ANY WARRANTY; without even the implied warranty of             *}
{* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *}
{* GNU General Public License for more details.                               *}
{*                                                                            *}
{* You should have received a copy of the GNU General Public License          *}
{* along with this program.  If not, see <http://www.gnu.org/licenses/>.      *}
{*                                                                            *}
{* http://sasgis.org                                                          *}
{* info@sasgis.org                                                            *}
{******************************************************************************}

unit i_MarkCategoryFactoryDbInternalORM;

interface

uses
  t_MarkSystemORM,
  i_MarkCategory;

type
  IMarkCategoryFactoryDbInternalORM = interface
    ['{FBDD146A-4CE8-453E-B8D7-AC8DCA63A92C}']
    function CreateCategory(
      const AId: TID;
      const AName: string;
      const AVisible: Boolean;
      const AAfterScale: Byte;
      const ABeforeScale: Byte
    ): IMarkCategory; overload;

    function CreateCategory(
      const ACategoryRec: TSQLCategoryRec
    ): IMarkCategory; overload;
  end;

implementation

end.
