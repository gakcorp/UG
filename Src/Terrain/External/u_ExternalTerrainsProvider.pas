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

unit u_ExternalTerrainsProvider;

interface

uses
  Windows,
  Types,
  Classes,
  t_GeoTypes,
  u_ExternalTerrainAPI,
  i_Notifier,
  i_ConfigDataProvider,
  i_ProjConverter,
  i_TerrainProvider,
  u_BaseInterfacedObject;

type
  TTerrainProviderByExternal = class(TBaseInterfacedObject, ITerrainProvider)
  private
    FDefaultPath: String;
    FProjConverter: IProjConverter;
    // opened file
    FFileHandle: THandle;
    FFileName: String;
    FBaseFolder: String;
    // options
    FAvailable: Boolean;
    FSamplesCount: Integer;
    FLinesCount: Integer;
    FVoidValue: Integer;
    FByteOrder: Integer;
    FPrefix, FSuffix: String;
  private
    procedure InternalClose;
  private
    function GetFilenamePart(
      const AValue: Integer;
      const APrefIfPlus, APrefIfMinus: Char;
      const AWidth: Byte
    ): String;
  protected
    { ITerrainProvider }
    function GetPointElevation(
      const ALonLat: TDoublePoint;
      const AZoom: Byte
    ): Single;
    function GetAvailable: Boolean;
    function GetStateChangeNotifier: INotifier;
  public
    constructor Create(
      const ADefaultPath: String;
      const AProjConverter: IProjConverter;
      const AOptions: IConfigDataProvider
    );
    destructor Destroy; override;
  end;

implementation

uses
  Math,
  StrUtils,
  SysUtils,
  c_TerrainProvider,
  u_FileSystemFunc;

{ TTerrainProviderByExternal }

constructor TTerrainProviderByExternal.Create(
  const ADefaultPath: String;
  const AProjConverter: IProjConverter;
  const AOptions: IConfigDataProvider
);
begin
  inherited Create;

  FProjConverter := AProjConverter;
  FDefaultPath := ADefaultPath;

  // read options
  // if failed - create object but disable it
  FFileHandle := 0;
  FFileName := '';
  FBaseFolder := '';
  FAvailable := AOptions.ReadBool('Enabled', False);

  if (not FAvailable) then begin
    Exit;
  end;

  // folder - terrain file(s) storage
  FBaseFolder := AOptions.ReadString('Folder', '');
  if Length(FBaseFolder) = 0 then begin
    FBaseFolder := IncludeTrailingPathDelimiter(FDefaultPath);
  end;

  // get absolute path to starage if it's not
  if StartsText('TerrainData', FBaseFolder) then begin
    FBaseFolder := StringReplace(FBaseFolder, 'TerrainData', FDefaultPath, [rfIgnoreCase]);
  end else if StartsText('.\TerrainData', FBaseFolder) then begin
    FBaseFolder := StringReplace(FBaseFolder, '.\TerrainData', FDefaultPath, [rfIgnoreCase]);
  end else if StartsText('.', FBaseFolder) then begin
    FBaseFolder := LowerCase(GetFullPath(IncludeTrailingPathDelimiter(FDefaultPath), FBaseFolder));
  end else begin
    // it's absolute path
  end;

  if Length(FBaseFolder) = 0 then begin
    FAvailable := FALSE;
    Exit;
  end else begin
    FBaseFolder := IncludeTrailingPathDelimiter(FBaseFolder);
  end;

  // samples count in single file (mandatory)
  FSamplesCount := AOptions.ReadInteger('SamplesCount', -1);
  if (FSamplesCount <= 0) then begin
    FAvailable := FALSE;
    Exit;
  end;

  // lines count in single file (check if defined)
  FLinesCount := AOptions.ReadInteger('LinesCount', 0);

  // some optional values
  FVoidValue := AOptions.ReadInteger('VoidValue', cUndefinedElevationValue);

  FByteOrder := AOptions.ReadInteger('ByteOrder', 0);

  FPrefix := Trim(AOptions.ReadString('Prefix', ''));
  FSuffix := Trim(AOptions.ReadString('Suffix', ''));
end;

destructor TTerrainProviderByExternal.Destroy;
begin
  InternalClose;

  FProjConverter := nil;

  inherited;
end;

function TTerrainProviderByExternal.GetAvailable: Boolean;
begin
  Result := FAvailable;
end;

function TTerrainProviderByExternal.GetFilenamePart(
  const AValue: Integer;
  const APrefIfPlus, APrefIfMinus: Char;
  const AWidth: Byte
): String;
begin
  // 'N60'
  // 'E056'
  Result := IntToStr(Abs(AValue));

  while (Length(Result) < AWidth) do begin
    Result := '0' + Result;
  end;

  if (AValue < 0) then begin
    Result := APrefIfMinus + Result;
  end else begin
    Result := APrefIfPlus + Result;
  end;
end;

function TTerrainProviderByExternal.GetPointElevation(
  const ALonLat: TDoublePoint;
  const AZoom: Byte
): Single;
var
  VFilePoint: TPoint;
  VIndexInLines, VIndexInSamples: LongInt;
  VCustomRowCount: Integer;
  VFilenameForPoint: String;
  VDone: Boolean;
  VElevationData: SmallInt; // signed 16bit
begin
  if (FProjConverter <> nil) then begin
    // TODO: convert to WGS84/EGM96 geoid
    Result := cUndefinedElevationValue;
  end else begin
    // without conversion
    Result := cUndefinedElevationValue;

    // get filename for given point
    // use common 1x1 distribution (GDEM, STRM, viewfinderpanoramas)
    // TODO: see 'file' implementation for ETOPO1 in ExternalTerrains.dll source
    // TODO: see 'a-p,50' implementation for GLOBE in ExternalTerrains.dll source
    VCustomRowCount := FLinesCount;

    VFilePoint.X := Floor(ALonLat.X);
    VFilePoint.Y := Floor(ALonLat.Y);

    // StripIndex
    VIndexInLines := Round((1 - (ALonLat.Y - VFilePoint.Y)) * (FLinesCount - 1));
    // ColumnIndex
    VIndexInSamples := Round((ALonLat.X - VFilePoint.X) * (FSamplesCount - 1));

    // make filename
    VFilenameForPoint := FBaseFolder + FPrefix + GetFilenamePart(VFilePoint.Y, 'N', 'S', 2) + GetFilenamePart(VFilePoint.X, 'E', 'W', 3) + FSuffix;

    // if file not opened or opened another file - open this
    if (FFileName <> VFilenameForPoint) or (0 = FFileHandle) then begin
      InternalClose;
      FFileName := VFilenameForPoint;
      // open file
      FFileHandle := CreateFile(PChar(FFileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
      if (INVALID_HANDLE_VALUE = FFileHandle) then begin
        FFileHandle := 0;
      end;
    end;

    // if file opened
    if (FFileHandle <> 0) then begin
      // check format
      if SameText(ExtractFileExt(FFileName), '.tif') then begin
        // with tiff header
        VDone := FindElevationInTiff(
          FFileHandle,
          VIndexInLines,
          VIndexInSamples,
          VCustomRowCount,
          FSamplesCount,
          VElevationData
        );
      end else begin
        // without header
        VDone := FindElevationInPlain(
          FFileHandle,
          VIndexInLines,
          VIndexInSamples,
          VCustomRowCount,
          FSamplesCount,
          VElevationData
        );
      end;

      // check byte inversion
      if VDone and (FByteOrder <> 0) then begin
        SwapInWord(@VElevationData);
      end;

      // check voids and result
      if (not VDone) or ((FVoidValue <> 0) and (FVoidValue = VElevationData)) then begin
        // void or failed
        Result := cUndefinedElevationValue;
      end else begin
        // ok
        Result := VElevationData;
      end;
    end;
  end;
end;

function TTerrainProviderByExternal.GetStateChangeNotifier: INotifier;
begin
  Result := nil;
end;

procedure TTerrainProviderByExternal.InternalClose;
begin
  if (FFileHandle <> 0) then begin
    CloseHandle(FFileHandle);
    FFileHandle := 0;
  end;
end;

end.
