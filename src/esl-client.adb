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

with Ada.Calendar;

with ESL.Parsing_Utilities;
with ESL.Trace;
with Ada.Exceptions;

package body ESL.Client is
   use ESL.Trace;
   use ESL;

   -----------
   --  "="  --
   -----------

   function "=" (Left, Right : in Reference) return Boolean is
   begin
      return Left.Socket = Right.Socket;
   end "=";

   -----------
   --  API  --
   -----------

   procedure API (Client  : in out Instance;
                  Command : in     ESL.Command.Instance'Class) is
   begin
      Client.Send (Known_Commands'Image (API) & " " &
                     String (Command.Serialize));
      ESL.Trace.Debug ("sent!");
   end API;

   ----------------------
   --  Background_API  --
   ----------------------

   procedure Background_API (Client  : in     Instance;
                             Command : in     ESL.Command.Instance'class) is
   begin
      Client.Send (Known_Commands'Image (BGAPI) & " " &
                     String (Command.Serialize));
   end Background_API;

   --------------------
   --  Channel_List  --
   --------------------

   function Channel_List (Obj : in Instance) return Channel.List.Reference is
   begin
      return Obj.Channels;
   end Channel_List;

   ---------------
   --  Connect  --
   ---------------

   procedure Connect (Client   : in out Instance;
                      Hostname : in     String;
                      Port     : in     Natural) is
      use Ada.Exceptions;

      Context : constant String := Package_Name & ".Connect";
      Address : constant Sock_Addr_Type :=
        (Family => GNAT.Sockets.Family_Inet,
         Addr   => Addresses (Get_Host_By_Name (Hostname)),
         Port   => Port_Type (Port));

      Socket   : Socket_Type;
      Status   : GNAT.Sockets.Selector_Status;
   begin
      Create_Socket (Socket);
      Client.Socket := Socket;

      Client.Connected := False;
      Client.Connecting := True;
      Client.Authenticated := False;

      Trace.Information ("Connecting to " &
                         Hostname & ":" &
                         Positive'Image (Port),
                         Context);

      Connect_Socket (Socket   => Client.Socket,
                      Server   => Address,
                      Timeout  => GNAT.Sockets.Forever,
                      Selector => Client.Selector'Access,
                      Status   => Status);

      if Status = Completed then
         Client.Channel := Stream (Client.Socket);
         Client.Connected := True;

         Trace.Information ("Connected to " &
                              Hostname & ":" &
                              Positive'Image (Port)& ".", Context);

         --  Signal the connected event listener.
         Client.On_Connect_Handler.all;
      else
         Trace.Information ("Could not connect to " & Image (Address)
                            & ".", Context);
      end if;

      --  Pull down the connecting flag.
      Client.Connecting := False;

   exception
      when E : GNAT.Sockets.Socket_Error =>
         --  Pull down the connecting flag.
         Client.Connecting := False;
         --  Assert the state
         Client.Connected := False;
         Client.Authenticated := False;
         --  Client.On_Disconnect_Handler.all;
         Trace.Error (Context => Context, Message =>
                        "Failed to connect: " & Exception_Message (E));
   end Connect;

   -----------------
   --  Connected  --
   -----------------

   function Connected (Client : in Instance) return Boolean is
   begin
      return Client.Connected;
   end Connected;

   --------------
   --  Create  --
   --------------

   function Create
     (On_Connect_Handler    : in Connection_Event_Handler;
      On_Disconnect_Handler : in Connection_Event_Handler)
      return Reference is
   begin
      return new Instance
        (On_Connect_Handler    => On_Connect_Handler,
         On_Disconnect_Handler => On_Disconnect_Handler);
   end Create;

   ------------------
   --  Disconnect  --
   ------------------

   procedure Disconnect (Client : in out Instance) is
      Context : constant String := Package_Name & ".Disconnect";
   begin
      if Client.Connecting then
         Abort_Selector (Client.Selector);
      elsif Client.Connected then
         Shutdown_Socket (Client.Socket);
      end if;
   exception
      when Program_Error =>
         ESL.Trace.Error (Message => "Tried to abort a closed selector!",
                          Context => Context);
      when E : others =>
         ESL.Trace.Error (Message => Ada.Exceptions.Exception_Information (E),
                          Context => Context);
   end Disconnect;

   ----------------
   --  Finalize  --
   ----------------

   procedure Finalize (Obj : in out Instance) is
      Context : constant String := Package_Name & ".Finalize";
   begin
      Obj.Disconnect;
      GNAT.Sockets.Close_Selector (Obj.Selector);

   exception
      when E : others =>
         ESL.Trace.Error (Message => Ada.Exceptions.Exception_Information (E),
                          Context => Context);
   end Finalize;

   ----------------
   --  Get_Line  --
   ----------------

   function Get_Line (Client : in Instance) return String is
   begin
      return Parsing_Utilities.Get_Line (Stream => Client.Channel);
   end Get_Line;

   -------------
   --  Image  --
   -------------

   function Image (Client : in Instance) return String is
   begin
      raise Program_Error with "Not implemented!";
      return "";
   end Image;

   ------------------
   --  Initialize  --
   ------------------

   procedure Initialize (Obj : in out Instance) is
   begin
      GNAT.Sockets.Create_Selector (Obj.Selector);
   end Initialize;

   ---------------
   --  Receive  --
   ---------------

   function Receive (Client : in Instance;
                     Count  : in Natural) return String is
      Buffer : String (1 .. Count);
   begin
      String'Read (Client.Channel, Buffer);

      return Buffer;
   exception
      when others =>
         ESL.Trace.Error (Message => "Receive failed!.",
                          Context => "ESL.Client.Receive");
         raise;
   end Receive;

   ------------
   --  Send  --
   ------------

   procedure Send (Client : in Instance;
                   Item   : in String) is
   begin
      String'Write (Client.Channel, Item &
                      ASCII.CR & ASCII.LF &
                      ASCII.CR & ASCII.LF);
      ESL.Trace.Debug (Message => "Sent: " & Item,
                       Context => "ESL.Client.Send");
   exception
      when others =>
         ESL.Trace.Error (Message => "Send failed!",
                          Context => "ESL.Client.Send");
   end Send;

   ------------
   --  Send  --
   ------------

   procedure Send (Client : in Instance;
                   Item   : in ESL.Command.Instance'Class) is
   begin
      Client.Send (String (Item.Serialize));
   end Send;

   ------------
   --  Send  --
   ------------

   procedure Set_Log_Level (Obj   : in out Instance;
                            Level : in     Natural) is
   begin
      --  TODO
      if Level > 0 then
         Obj.Send ("log" & Level'Img & ESL.End_Packet_String);
      else
         Obj.Send ("nolog" & ESL.End_Packet_String);
      end if;
   end Set_Log_Level;

   -----------------------------
   --  Skip_Until_Empty_Line  --
   -----------------------------

   procedure Skip_Until_Empty_Line (Obj : in Instance) is
   begin
      while Obj.Get_Line'Length > 0 loop
         null;
      end loop;
   end Skip_Until_Empty_Line;

   function Stream (Obj : in Instance)
                       return Ada.Streams.Stream_IO.Stream_Access is
   begin
      return Ada.Streams.Stream_IO.Stream_Access (Obj.Channel);
   end Stream;

   ---------------------------
   --  Wait_For_Connection  --
   ---------------------------

   procedure Wait_For_Connection (Client  : in Instance;
                                  Timeout : in Duration := 3.0) is
      use Ada.Calendar;
      Absolute_Timeout : constant Time := Clock + Timeout;
   begin
      if Client.Connected then
         return;
      end if;

      loop
         exit when
           Client.Connected or
           Client.Shutdown or
           Clock > Absolute_Timeout;
         delay 0.05;

      end loop;

      if not Client.Connected then
         raise Connection_Timeout;
      end if;
   end Wait_For_Connection;
end ESL.Client;
