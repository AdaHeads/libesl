-------------------------------------------------------------------------------
--                                                                           --
--                     Copyright (C) 2012-, AdaHeads K/S                     --
--                                                                           --
--  This is free software;  you can redistribute it and/or modify it         --
--  under terms of the  GNU General Public License  as published by the      --
--  Free Software  Foundation;  either version 3,  or (at your  option) any  --
--  later version. This library is distributed in the hope that it will be   --
--  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of  --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     --
--  You should have received a copy of the GNU General Public License and    --
--  a copy of the GCC Runtime Library Exception along with this program;     --
--  see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
--  <http://www.gnu.org/licenses/>.                                          --
--                                                                           --
-------------------------------------------------------------------------------

with URL_Utilities;

with ESL.Trace;
with ESL.Parsing_Utilities;

package body ESL.Packet is
   use ESL.Packet_Keys;

   --------------------
   --  Add_Variable  --
   --------------------

   procedure Add_Variable (Obj      : in out Instance;
                           Variable : in     Packet_Variable.Instance) is
      Context : constant String := Package_Name & ".Add_Variable";
   begin

      Obj.Variables.Insert (Key      => Variable.Name,
                            New_Item => Variable);
      ESL.Trace.Debug
        (Message => "Adding variable: " & Packet_Variable.Image (Variable),
         Context => Context);

   exception
      when others =>
         ESL.Trace.Error (Context => Context,
                          Message => "Error Adding " &
                            Packet_Variable.Image (Variable));
   end Add_Variable;

   ----------------------
   --  Content_Length  --
   ----------------------

   function Content_Length (Obj : in Instance) return Natural is
   begin
      return Obj.Headers.Content_Length;
   end Content_Length;

   -------------------
   --  Set_Headers  --
   -------------------

   procedure Set_Headers (Obj     :    out Instance;
                          Headers : in     Packet_Header.Instance) is
   begin
      Obj.Headers := Headers;
   end Set_Headers;

   -----------------------
   --  Equivalent_Keys  --
   -----------------------

   function Equivalent_Keys (Left  : in Unbounded_String;
                             Right : in Unbounded_String) return Boolean is
   begin
      return Left = Right;
   end Equivalent_Keys;

   function Equivalent_Keys (Left  : in Packet_Keys.Event_Keys;
                             Right : in Packet_Keys.Event_Keys) return Boolean
   is
   begin
      return Left = Right;
   end Equivalent_Keys;

   ------------------
   --  Has_Header  --
   ------------------

   function Has_Header (Obj : in Instance;
                        Key : in Packet_Keys.Event_Keys) return Boolean is
   begin
      return not Obj.Headers.Empty;
   end Has_Header;

   function Hash_Field (Item : in Packet_Keys.Event_Keys) return
     Ada.Containers.Hash_Type is
   begin
      return Packet_Keys.Event_Keys'Pos (Item);
   end Hash_Field;

   -------------
   --  Image  --
   -------------

   function Image (Obj : in Instance) return String is
   begin
      if Obj.Content_Type = Text_Event_JSON then
         return "Content_Type:" & Image (Obj.Content_Type) &
           ASCII.LF & ASCII.LF &
           "Headers:" & ASCII.LF & Image (Obj.Headers) & ASCII.LF & ASCII.LF &
           Obj.JSON.Write;
      end if;

      return "Content_Type:" & Image (Obj.Content_Type) & ASCII.LF & ASCII.LF &
        "Headers:" & ASCII.LF & Image (Obj.Headers) & ASCII.LF & ASCII.LF &
        "Payload:" & ASCII.LF & Image (Obj.Payload) & ASCII.LF & ASCII.LF &
        "Variables:" & ASCII.LF & Image (Obj.Variables);
   end Image;

   function Image (List : Header_Storage.Map) return String is
      use Header_Storage;

      Buffer : Unbounded_String;
   begin
      for C in List.Iterate loop
         Append (Buffer, (Key (C)'Img));
         Append (Buffer, ": ");
         Append (Buffer, Element (C).Value);
         Append (Buffer, ASCII.LF);
      end loop;
      return To_String (Buffer);
   end Image;

   function Image (List : Payload_Storage.Map) return String is
      use Payload_Storage;
      Buffer : Unbounded_String;
   begin
      for C in List.Iterate loop
         Append (Buffer, Element (C).Key'Img);
         Append (Buffer, ": ");
         Append (Buffer, Element (C).Value);
         Append (Buffer, ASCII.LF);
      end loop;
      return To_String (Buffer);
   end Image;

   function Image (List : Variable_Storage.Map) return String is
      use Variable_Storage;
      Buffer : Unbounded_String;
   begin
      for C in List.Iterate loop
         Append (Buffer, Key (C));
         Append (Buffer, ": ");
         Append (Buffer, Element (C).Value);
         Append (Buffer, ASCII.LF);
      end loop;
      return To_String (Buffer);
   end Image;

   function Is_Event (Obj : in Instance) return Boolean is
   begin
      return Obj.Payload.Contains (Key => Event_Name);
   end Is_Event;

   function Event (Obj : in Instance) return Packet_Keys.Inbound_Events is
      Context   : constant String := Package_Name & ".Event";
      Not_Event : exception;
   begin
      if not Is_Event (Obj => Obj) then
         raise Not_Event;
      end if;

      return Packet_Keys.Inbound_Events'Value
        (Obj.Payload.Element (Key => Event_Name).Value);
   exception
      when Not_Event =>
         ESL.Trace.Error (Message => "Packet accessed erroneusly as event",
                          Context => Context);
         raise Constraint_Error with "Packet is not an event";
      when Constraint_Error =>
         ESL.Trace.Error (Message => "Unknown Event name : " &
                            Obj.Payload.Element (Key => Event_Name).Value,
                          Context => Context);
         raise Constraint_Error with  "Unknown Event name : " &
                            Obj.Payload.Element (Key => Event_Name).Value;

   end Event;

   ------------------------
   --  Payload_Contains  --
   ------------------------

   function Payload_Contains (Obj : in Instance;
                              Key : in Packet_Keys.Event_Keys) return Boolean
   is
   begin
      return Obj.Payload.Contains (Key => Key);
   end Payload_Contains;

   ---------------------
   --  Payload_Field  --
   ---------------------

   function Payload_Field (Obj : in Instance;
                           Key : in Packet_Keys.Event_Keys)
                           return Packet_Field.Instance is
   begin
      return Obj.Payload.Element (Key => Key);
   end Payload_Field;

   ----------------------------
   --  Process_And_Add_Body  --
   ----------------------------

   procedure Process_And_Add_Body (Obj      : in out Instance;
                                   Raw_Data : in     String) is
      use Parsing_Utilities;

      Context    : constant String := Package_Name & ".Process_And_Add_Body";

      Linebuffer : String (Raw_Data'Range) := (others => ASCII.NUL);
      Position   : Natural := Raw_Data'First;
   begin

      Obj.Raw_Body := To_Unbounded_String (Raw_Data);

      if Obj.Content_Type = API_Response then
         ESL.Trace.Information (Message => "Skipping package of type " &
                                  Image (Obj.Content_Type),
                                Context => Context);
         return;
      elsif Obj.Content_Type = Text_Event_JSON then
         Obj.JSON := GNATCOLL.JSON.Read (Raw_Data, "json.errors");
         return;
      end if;

      for I in Raw_Data'Range loop
         case Raw_Data (I) is
            when ASCII.CR =>
               null;
            when ASCII.LF => --  Seen a full line.
               declare
                  Field : ESL.Packet_Field.Instance;
                  Line  : String renames
                    Linebuffer (Linebuffer'First .. Position - 1);
                  Variable_String : constant String := "variable_";
               begin
                  if Line'Length > Variable_String'Length and then
                    Line (Variable_String'Range) = Variable_String then
                     --  declare
                     --  Variable : Packet_Variable.Instance := Parse_Line (
                     --  begin
                     --  Obj.Variables.Insert (Parse_Line
                     Obj.Add_Variable
                       (Variable => Parse_Line (Line
                        (Variable_String'Length + 1 .. Line'Last)));
                  else

                     Field := Parse_Line (Item => Line);
                     ESL.Trace.Debug
                       (Message => "Processing line: " &
                          URL_Utilities.Decode (Field.Value),
                        Context => Context);

                     if Field = Empty_Line then
                        if Obj.Payload_Contains (Key => Content_Length) then
                           --  Skip the payload.
                           --  TODO:
                           return;
                        end if;

                     elsif Field.Key /= Unknown then

                        Obj.Payload.Insert (Key      => Field.Key,
                                            New_Item => Field);
                     end if;

                  end if;
               exception
                  when Constraint_Error =>
                     ESL.Trace.Error (Message => Line,
                                      Context => Context);
                     raise;
               end;
               Position := Raw_Data'First;
            when others =>
               Linebuffer (Position) := Raw_Data (I);
               Position := Position + 1;
         end case;
      end loop;
   end Process_And_Add_Body;
end ESL.Packet;
