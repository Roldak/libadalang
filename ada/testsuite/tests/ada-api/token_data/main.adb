with Ada.Text_IO; use Ada.Text_IO;

with Langkit_Support.Slocs; use Langkit_Support.Slocs;
with Langkit_Support.Text;  use Langkit_Support.Text;
with Langkit_Support.Token_Data_Handler;
use Langkit_Support.Token_Data_Handler;

with Libadalang.Analysis;  use Libadalang.Analysis;
with Libadalang.AST;       use Libadalang.AST;
with Libadalang.AST.Types; use Libadalang.AST.Types;
with Libadalang.Lexer;     use Libadalang.Lexer;

procedure Main is
   Ctx    : Analysis_Context := Create;
   Unit   : Analysis_Unit := Get_From_File (Ctx, "foo.adb");

   It          : Ada_Node_Iterators.Iterator'Class :=
     Find (Root (Unit), new Ada_Node_Kind_Filter'(Kind => Identifier_Kind));
   Has_Element : Boolean;
   N           : Ada_Node;
begin
   Next (It, Has_Element, N);
   if not Has_Element then
      raise Program_Error;
   end if;

   declare
      Id     : constant Single_Tok_Node := Single_Tok_Node (N);
      Tok_Id : constant Token_Index := F_Tok (Id);
      Tok    : constant Token_Data_Type := Data (Token (Id, Tok_Id));
   begin
      Put_Line ("Token data for the ""foo"" identifier:");
      Put_Line ("Text: " & Image (Tok.Text.all));
      Put_Line ("Sloc range: " & Image (Tok.Sloc_Range));
   end;

   Destroy (Ctx);
   Put_Line ("Done.");
end Main;
