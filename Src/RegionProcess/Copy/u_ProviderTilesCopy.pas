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

unit u_ProviderTilesCopy;

interface

uses
  Forms,
  i_NotifierTime,
  i_LanguageManager,
  i_GeometryLonLat,
  i_MapTypeSet,
  i_MapTypeListBuilder,
  i_ActiveMapsConfig,
  i_MapTypeGUIConfigList,
  i_ContentTypeManager,
  i_GeometryProjectedFactory,
  i_TileStorage,
  i_TileStorageTypeList,
  i_MapVersionInfo,
  i_ContentTypeInfo,
  i_GlobalBerkeleyDBHelper,
  i_RegionProcessProgressInfoInternalFactory,
  i_Bitmap32BufferFactory,
  i_BitmapTileSaveLoadFactory,
  u_ExportProviderAbstract,
  fr_MapSelect;

type
  TProviderTilesCopy = class(TExportProviderAbstract)
  private
    FMapTypeListBuilderFactory: IMapTypeListBuilderFactory;
    FTimerNoifier: INotifierTime;
    FGlobalBerkeleyDBHelper: IGlobalBerkeleyDBHelper;
    FVectorGeometryProjectedFactory: IGeometryProjectedFactory;
    FContentTypeManager: IContentTypeManager;
    FTileStorageTypeList: ITileStorageTypeListStatic;
    FMainMapConfig: IActiveMapConfig;
    FFullMapsSet: IMapTypeSet;
    FGUIConfigList: IMapTypeGUIConfigList;
    FBitmap32StaticFactory: IBitmap32StaticFactory;
    FBitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory;
  protected
    function CreateFrame: TFrame; override;
  protected
    function GetCaption: string; override;
    procedure StartProcess(const APolygon: IGeometryLonLatPolygon); override;
  public
    constructor Create(
      const ATimerNoifier: INotifierTime;
      const AProgressFactory: IRegionProcessProgressInfoInternalFactory;
      const ALanguageManager: ILanguageManager;
      const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
      const AMainMapConfig: IActiveMapConfig;
      const AGlobalBerkeleyDBHelper: IGlobalBerkeleyDBHelper;
      const AFullMapsSet: IMapTypeSet;
      const AGUIConfigList: IMapTypeGUIConfigList;
      const AMapTypeListBuilderFactory: IMapTypeListBuilderFactory;
      const AContentTypeManager: IContentTypeManager;
      const AVectorGeometryProjectedFactory: IGeometryProjectedFactory;
      const ATileStorageTypeList: ITileStorageTypeListStatic;
      const ABitmap32StaticFactory: IBitmap32StaticFactory;
      const ABitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory
    );
  end;

implementation

uses
  Types,
  Classes,
  SysUtils,
  i_MapType,
  i_MapTypeListStatic,
  i_TileStorageAbilities,
  i_TileStorageTypeListItem,
  i_RegionProcessParamsFrame,
  i_RegionProcessProgressInfo,
  u_ThreadCopyFromStorageToStorage,
  u_ThreadCopyWithModification,
  u_ResStrings,
  fr_TilesCopy;

{ TProviderTilesCopy }

constructor TProviderTilesCopy.Create(
  const ATimerNoifier: INotifierTime;
  const AProgressFactory: IRegionProcessProgressInfoInternalFactory;
  const ALanguageManager: ILanguageManager;
  const AMapSelectFrameBuilder: IMapSelectFrameBuilder;
  const AMainMapConfig: IActiveMapConfig;
  const AGlobalBerkeleyDBHelper: IGlobalBerkeleyDBHelper;
  const AFullMapsSet: IMapTypeSet;
  const AGUIConfigList: IMapTypeGUIConfigList;
  const AMapTypeListBuilderFactory: IMapTypeListBuilderFactory;
  const AContentTypeManager: IContentTypeManager;
  const AVectorGeometryProjectedFactory: IGeometryProjectedFactory;
  const ATileStorageTypeList: ITileStorageTypeListStatic;
  const ABitmap32StaticFactory: IBitmap32StaticFactory;
  const ABitmapTileSaveLoadFactory: IBitmapTileSaveLoadFactory
);
begin
  inherited Create(
    AProgressFactory,
    ALanguageManager,
    AMapSelectFrameBuilder
  );
  FMainMapConfig := AMainMapConfig;
  FFullMapsSet := AFullMapsSet;
  FGUIConfigList := AGUIConfigList;
  FMapTypeListBuilderFactory := AMapTypeListBuilderFactory;
  FTimerNoifier := ATimerNoifier;
  FGlobalBerkeleyDBHelper := AGlobalBerkeleyDBHelper;
  FContentTypeManager := AContentTypeManager;
  FVectorGeometryProjectedFactory := AVectorGeometryProjectedFactory;
  FTileStorageTypeList := ATileStorageTypeList;
  FBitmap32StaticFactory := ABitmap32StaticFactory;
  FBitmapTileSaveLoadFactory := ABitmapTileSaveLoadFactory;
end;

function TProviderTilesCopy.CreateFrame: TFrame;
begin
  Result :=
    TfrTilesCopy.Create(
      Self.LanguageManager,
      Self.MapSelectFrameBuilder,
      FMapTypeListBuilderFactory,
      FMainMapConfig,
      FFullMapsSet,
      FGUIConfigList,
      FTileStorageTypeList,
      FBitmap32StaticFactory,
      FBitmapTileSaveLoadFactory,
      FContentTypeManager
    );
  Assert(Supports(Result, IRegionProcessParamsFrameZoomArray));
  Assert(Supports(Result, IRegionProcessParamsFrameTargetPath));
  Assert(Supports(Result, IRegionProcessParamsFrameTilesCopy));
end;

function TProviderTilesCopy.GetCaption: string;
begin
  Result := SAS_STR_OperationTilesCopyCaption;
end;

procedure TProviderTilesCopy.StartProcess(const APolygon: IGeometryLonLatPolygon);
var
  VMaps: IMapTypeListStatic;

  function DoDirectCopy: Boolean;
  begin
    Result := Assigned(VMaps);
  end;

  function PrepareDirectCopy(const VProgressInfo: IRegionProcessProgressInfoInternal; const VCacheType: Byte; const VZoomArr: TByteDynArray; const VDeleteSource, VReplace: Boolean): TThread;
  var
    VTasks: TCopyTaskArray;
    VPlaceInSubFolder: Boolean;
    VSetTargetVersionEnabled: Boolean;
    VSetTargetVersionValue: String;
    VTargetStoragePath: String;
    i: Integer;
    VMapType: IMapType;
    VStorageType: ITileStorageTypeListItem;
    VPath: String;
  begin
    VPlaceInSubFolder := (ParamsFrame as IRegionProcessParamsFrameTilesCopy).PlaceInNameSubFolder;
    if VMaps.Count > 1 then begin
      VPlaceInSubFolder := True;
    end;
    VPath := (ParamsFrame as IRegionProcessParamsFrameTargetPath).Path;
    if VPlaceInSubFolder then begin
      VPath := IncludeTrailingPathDelimiter(VPath);
    end;

    // set version options
    VSetTargetVersionEnabled := (ParamsFrame as IRegionProcessParamsFrameTilesCopy).SetTargetVersionEnabled;
    if VSetTargetVersionEnabled then begin
      VSetTargetVersionValue := (ParamsFrame as IRegionProcessParamsFrameTilesCopy).SetTargetVersionValue;
    end else begin
      VSetTargetVersionValue := '';
    end;
    VStorageType := FTileStorageTypeList.GetItemByCode(VCacheType);

    SetLength(VTasks, VMaps.Count);
    for i := 0 to VMaps.Count - 1 do begin
      VMapType := VMaps.Items[i];
      VTasks[i].FSource := VMapType.TileStorage;
      VTasks[i].FSourceVersion := VMapType.VersionRequest.GetStatic;
      if VPlaceInSubFolder then begin
        VTargetStoragePath := VPath + VMapType.GetShortFolderName;
      end else begin
        VTargetStoragePath := VPath;
      end;
      if VStorageType.StorageType.Abilities.StorageClass in [tstcFolder, tstcInSeparateFiles] then begin
        VTargetStoragePath := IncludeTrailingPathDelimiter(VTargetStoragePath);
      end;
      if Assigned(VStorageType) then begin
        VTasks[i].FTarget :=
          VStorageType.StorageType.BuildStorage(
            nil,
            VTasks[i].FSource.ProjectionSet,
            VMapType.ContentType,
            nil,
            VTargetStoragePath,
            nil
          );
      end;
      if VSetTargetVersionEnabled then begin
        VTasks[i].FTargetVersionForce := VMapType.VersionFactory.GetStatic.CreateByStoreString(VSetTargetVersionValue);
      end else begin
        VTasks[i].FTargetVersionForce := nil;
      end;
    end;

    Result :=
      TThreadCopyFromStorageToStorage.Create(
        VProgressInfo,
        FVectorGeometryProjectedFactory,
        APolygon,
        VTasks,
        VZoomArr,
        True,
        VDeleteSource,
        VReplace
      );
  end;

  function PrepareModification(const VProgressInfo: IRegionProcessProgressInfoInternal; const VCacheType: Byte; const VZoomArr: TByteDynArray; const VDeleteSource, VReplace: Boolean): TThread;
  var
    VSetTargetVersionEnabled: Boolean;
    VSetTargetVersionValue: String;
    VStorageType: ITileStorageTypeListItem;
    ATarget: ITileStorage;
    ATargetVersionForce: IMapVersionInfo;
    VMapType: IMapType;
    VContentType: IContentTypeInfoBasic;
    VPath: String;
  begin
    VMapType := (ParamsFrame as IRegionProcessParamsFrameTilesCopy).MapSource;
    VContentType := (ParamsFrame as IRegionProcessParamsFrameTilesCopy).ContentType;
    VPath := IncludeTrailingPathDelimiter((ParamsFrame as IRegionProcessParamsFrameTargetPath).Path);

    VStorageType := FTileStorageTypeList.GetItemByCode(VCacheType);
    if Assigned(VStorageType) then begin
      ATarget :=
        VStorageType.StorageType.BuildStorage(
          nil,
          VMapType.TileStorage.ProjectionSet,
          VContentType,
          nil,
          VPath,
          nil
        );
    end;

    // set version options
    VSetTargetVersionEnabled := (ParamsFrame as IRegionProcessParamsFrameTilesCopy).SetTargetVersionEnabled;
    if VSetTargetVersionEnabled then begin
      VSetTargetVersionValue := (ParamsFrame as IRegionProcessParamsFrameTilesCopy).SetTargetVersionValue;
    end else begin
      VSetTargetVersionValue := '';
    end;

    if VSetTargetVersionEnabled then begin
      ATargetVersionForce := VMapType.VersionFactory.GetStatic.CreateByStoreString(VSetTargetVersionValue);
    end else begin
      ATargetVersionForce := nil;
    end;

    Result :=
      TThreadCopyWithModification.Create(
        VProgressInfo,
        FVectorGeometryProjectedFactory,
        APolygon,
        ATarget,
        ATargetVersionForce,
        VMapType,
        (ParamsFrame as IRegionProcessParamsFrameTilesCopy).Overlay,
        (ParamsFrame as IRegionProcessParamsFrameImageProvider).Provider,
        (ParamsFrame as IRegionProcessParamsFrameTilesCopy).BitmapTileSaver,
        VZoomArr,
        VContentType,
        True,
        VReplace
      );
  end;

var
  VCacheType: Byte;
  VZoomArr: TByteDynArray;
  VDeleteSource: Boolean;
  VReplace: Boolean;
  VProgressInfo: IRegionProcessProgressInfoInternal;
  VThread: TThread;
begin
  VMaps := (ParamsFrame as IRegionProcessParamsFrameTilesCopy).MapTypeList;
  VCacheType := (ParamsFrame as IRegionProcessParamsFrameTilesCopy).TargetCacheType;
  VZoomArr := (ParamsFrame as IRegionProcessParamsFrameZoomArray).ZoomArray;
  VDeleteSource := (ParamsFrame as IRegionProcessParamsFrameTilesCopy).DeleteSource;
  VReplace := (ParamsFrame as IRegionProcessParamsFrameTilesCopy).ReplaseTarget;

  VProgressInfo := ProgressFactory.Build(APolygon);

  if DoDirectCopy then begin
    VThread := PrepareDirectCopy(VProgressInfo, VCacheType, VZoomArr, VDeleteSource, VReplace);
  end else begin
    VThread := PrepareModification(VProgressInfo, VCacheType, VZoomArr, VDeleteSource, VReplace);
  end;

  if Assigned(VThread) then begin
    VThread.Resume;
  end;
end;

end.
