{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2012, SAS.Planet development team.                      *}
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

unit u_ArchiveWriteLibTar;

interface

uses
  Classes,
  i_ArchiveReadWrite,
  i_ArchiveReadWriteFactory,
  u_BaseInterfacedObject;

type
  TArchiveWriterFactoryLibTar = class(TBaseInterfacedObject, IArchiveWriterFactory)
  private
    function BuildByFileName(const AFileName: string): IArchiveWriter;
    function BuildByStream(const AStream: TStream): IArchiveWriter;
  public
    constructor Create;
  end;

implementation

uses
  SysUtils,
  LibTar,
  i_BinaryData,
  u_StreamReadOnlyByBinaryData;

{ TArchiveWriteByLibTar }

type
  TArchiveWriteByLibTar = class(TBaseInterfacedObject, IArchiveWriter)
  private
    FTar: TTarWriter;
    FFilesCount: Integer;
  private
    function AddFile(
      const AFileData: IBinaryData;
      const AFileNameInArchive: string;
      const AFileDate: TDateTime
    ): Integer;
  public
    constructor Create(const AFileName: string); overload;
    constructor Create(const AStream: TStream); overload;
    destructor Destroy; override;
  end;

constructor TArchiveWriteByLibTar.Create(const AFileName: string);
begin
  inherited Create;
  FFilesCount := 0;
  FTar := TTarWriter.Create(AFileName);
end;

constructor TArchiveWriteByLibTar.Create(const AStream: TStream);
begin
  inherited Create;
  FFilesCount := 0;
  FTar := TTarWriter.Create(AStream);
end;

destructor TArchiveWriteByLibTar.Destroy;
begin
  FreeAndNil(FTar);
  inherited;
end;

function TArchiveWriteByLibTar.AddFile(
  const AFileData: IBinaryData;
  const AFileNameInArchive: string;
  const AFileDate: TDateTime
): Integer;
var
  VStream: TStream;
begin
  VStream := TStreamReadOnlyByBinaryData.Create(AFileData);
  try
    FTar.AddStream(
      VStream,
      AnsiString(AFileNameInArchive),
      AFileDate
    );
    Inc(FFilesCount);
    Result := FFilesCount;
  finally
    VStream.Free;
  end;
end;

{ TArchiveWriterFactoryLibTar }

constructor TArchiveWriterFactoryLibTar.Create;
begin
  inherited Create;
end;

function TArchiveWriterFactoryLibTar.BuildByFileName(
  const AFileName: string): IArchiveWriter;
begin
  Result := TArchiveWriteByLibTar.Create(AFileName);
end;

function TArchiveWriterFactoryLibTar.BuildByStream(
  const AStream: TStream): IArchiveWriter;
begin
  Result := TArchiveWriteByLibTar.Create(AStream);
end;

end.
