unit u_UIS_Settings;

interface
uses frm_Main;
function UISSettingsTestHide(val:Boolean):Boolean;


implementation


function UISSettingsTestHide(val:Boolean):Boolean;
begin
  frmMain.TBXMainMenu.Visible:=val;
  Result:=True;
end;

end.
