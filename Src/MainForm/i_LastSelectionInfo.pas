{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2014, SAS.Planet development team.                      *}
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

unit i_LastSelectionInfo;

interface

uses
  i_GeometryLonLat,
  i_Changeable;

type
  ILastSelectionInfo = interface(IChangeable)
    ['{8F34A418-0320-4B19-A569-B44FA73146F4}']
    function GetZoom: Byte;
    property Zoom: Byte read GetZoom;

    function GetPolygon: IGeometryLonLatPolygon;
    property Polygon: IGeometryLonLatPolygon read GetPolygon;

    procedure SetPolygon(
      const ALonLatPolygon: IGeometryLonLatPolygon;
      AZoom: Byte
    );
  end;

implementation

end.
