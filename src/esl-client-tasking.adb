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
with Ada.Task_Identification;
with Ada.Task_Termination;
with Ada.Exceptions;
with Ada.IO_Exceptions;
--  with Ada.Strings.Unbounded;
--  with Ada.Containers.Vectors;

with ESL.Trace;
with ESL.Packet;
with ESL.Parsing_Utilities;

package body ESL.Client.Tasking is
   use ESL;
   protected Shutdown_Handler is
      procedure Termination_Finalizer
        (Cause : in Ada.Task_Termination.Cause_Of_Termination;
         T     : in Ada.Task_Identification.Task_Id;
         X     : in Ada.Exceptions.Exception_Occurrence);
   end Shutdown_Handler;

   function Event_Stream (Client : in Instance;
                          Stream : in ESL.Packet_Keys.Inbound_Events)
                          return Event_Streams_Access is
   begin
      return Client.Event_Observers (Stream)'Access;
   end Event_Stream;

   function Sub_Event_Stream (Client : in Instance;
                              Stream : in ESL.Packet_Keys.Inbound_Sub_Events)
                              return Event_Streams_Access is
   begin
      return Client.Sub_Event_Observers (Stream)'Access;
   end Sub_Event_Stream;

   ----------------
   --  Dispatch  --
   ----------------

--     procedure Dispatch (Ref    : in Client.Reference;
--                         Packet : in AMI.Parser.Packet_Type) is
--        Context : constant String := Package_Name & ".Dispatch";
--        pragma Unreferenced (Context);
--        use AMI.Packet_Keys;
--
--        Attr : Client_Data renames Client_Attribute.Value;
--
--     begin
--
--        if Packet.Header.Key = AMI.Packet_Keys.Event then
--           --  Notify the local observers.
--           Notify (Event     => AMI.Event.Event_Type'Value
--                   (To_String (Packet.Header.Value)),
--                   Packet    => Packet);
--           --  Notify the global observers.
--           AMI.Observers.Notify (AMI.Event.Event_Type'Value
--                                 (To_String (Packet.Header.Value)),
--                                 Packet);
--        end if;
--     end Dispatch;

   ------------------------
   --  Shutdown_Handler  --
   ------------------------

   protected body Shutdown_Handler is

      procedure Termination_Finalizer
        (Cause : in Ada.Task_Termination.Cause_Of_Termination;
         T     : in Ada.Task_Identification.Task_Id;
         X     : in Ada.Exceptions.Exception_Occurrence)
      is
         use Ada.Task_Termination;
         use Ada.Task_Identification;
         use Ada.Exceptions;

         Context : constant String :=
           Package_Name & ".Shutdown_Handler.Termination_Finalizer";
      begin

         case Cause is
         when Normal =>
            Trace.Debug
              (Context => Context,
               Message => "Task " & Image (T => T) & " terminated normally");
         when Abnormal =>
            Trace.Error
              (Context => Context,
               Message => "Task " & Image (T => T) &
                 " terminated abnormally.");
         when Unhandled_Exception =>
            Trace.Error
              (Context => Context,
               Message => "Task " & Image (T => T) &
                 " terminated with exception: " & Exception_Information (X));
         end case;

      end Termination_Finalizer;

   end Shutdown_Handler;

   --------------------------
   --  Stream_Reader Task  --
   --------------------------

   task body Stream_Reader is
      use Ada.Calendar;
      use ESL.Observer;

      function Current_Time return Time renames Clock;
      procedure Reader_Loop;

      Next_Attempt    : Time := Current_Time;
--      Event_Observers : Client_Event_Listeners;

      use Ada.Task_Identification;

      Context : constant String :=
        Package_Name & ".Instance(" & Image (Current_Task) & ")";

      procedure Reader_Loop is
      begin
         loop
            Trace.Debug (Context => Context,
                         Message => "Waiting for connection...");
            Owner.Wait_For_Connection (Timeout => 3.0);
            Trace.Debug (Context => Context,
                         Message => "Connection ok!");

            declare
               Packet : constant ESL.Packet.Instance :=
                 ESL.Parsing_Utilities.Read_Packet (Stream => Owner.Stream);
            begin
               if Packet.Is_Event then
                  Trace.Debug (Context => Context,
                               Message => Packet.Content_Type'Img);

                  ESL.Observer.Notify_Observers
                    (Observing =>
                       ESL.Observer.Observables
                         (ESL.Client.Tasking.Reference
                              (Owner).Event_Observers (Packet.Event)),
                     Packet    => Packet,
                     Client    => ESL.Client.Reference (Owner));
               end if;

            end;
         end loop;
--           Dispatch (Ref    => Client,
--                     Packet => Client.Read_Packet);
      exception
         when Ada.IO_Exceptions.End_Error =>
            Trace.Debug (Context => Context,
                             Message => "Reader operated on closed socket");
            Owner.Connected := False;
         when Connection_Timeout =>
            Trace.Debug (Context => Context,
                             Message => "Timeout reached for reader");
      end Reader_Loop;

   begin
      while not Owner.Shutdown loop
         delay until Next_Attempt;
         Next_Attempt := Next_Attempt + Recheck_Connection_Delay;
         Reader_Loop;
      end loop;
   end Stream_Reader;

   --------------
   --  Notify  --
   --------------

--     procedure Notify (Event  : in AMI.Event.Event_Type;
--                       Packet : in AMI.Parser.Packet_Type) is
--        Context : constant String := Package_Name & ".Notify ";
--        use Client_Callback_Collections;
--
--        procedure Call (C : Cursor);
--
--        Attr : Client_Data renames
--          Client_Attribute.Value;
--
--        procedure Call (C : Cursor) is
--        begin
--           Element (C) (Attr.Client_Ref, Packet);
--        end Call;
--
--     begin
--        if Attr.Event_Observers (Event).Is_Empty then
--         AMI.Trace.Debug ("Nobody cared about event " & Event'Img, Context);
--        end if;
--
--        Attr.Event_Observers (Event).Iterate (Process => Call'Access);
--     end Notify;

--     -----------------
--     --  Subscribe  --
--     -----------------
--
--     procedure Subscribe (Obj      : in Instance;
--                          Event    : in ESL.Packet_Keys.Inbound_Events;
--                          Observer : in
--  ESL.Observer.Event_Listener_Reference) is
--        Attr : Client_Data renames
--          Client_Attribute.Value (T => Obj'Identity);
--     begin
--           Attr.Event_Observers (Event).Append (New_Item => Observer);
--     end Subscribe;

end ESL.Client.Tasking;
