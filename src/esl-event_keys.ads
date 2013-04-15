
package ESL.Event_Keys is

   type Events is (Unknown, Channel_Create);
   type Event_Keys is
     (Unknown,
      Event_Name,
      Core_UUID,
      FreeSWITCH_Hostname,
      FreeSWITCH_IPv4,
      FreeSWITCH_IPv6,
      Event_Date_Local,
      Event_Date_GMT,
      Event_Date_Timestamp,
      Event_Calling_File,
      Event_Calling_Function,
      Event_Calling_Line_Number,
      Channel_State,
      Channel_State_Number,
      Channel_Name,
      Unique_ID,
      Call_Direction,
      Presence_Call_Direction,
      Answer_State,
      Original_Channel_Call_State,
      Channel_Call_State,
      Channel_Presence_ID,
      Channel_Read_Codec_Name,
      Channel_Read_Codec_Rate,
      Channel_Read_Codec_Bit_Rate,
      Channel_Write_Codec_Name,
      Channel_Write_Codec_Rate,
      Channel_Write_Codec_Bit_Rate,
      Caller_Direction,
      Caller_Username,
      Caller_Dialplan,
      Caller_Caller_ID_Name,
      Caller_Caller_ID_Number,
      Caller_Network_Addr,
      Caller_ANI,
      Caller_Destination_Number,
      Caller_Unique_ID,
      Caller_Source,
      Caller_Context,
      Caller_Channel_Name,
      Caller_Profile_Index,
      Caller_Profile_Created_Time,
      Caller_Channel_Created_Time,
      Caller_Channel_Answered_Time,
      Caller_Channel_Progress_Time,
      Caller_Channel_Progress_Media_Time,
      Caller_Channel_Hangup_Time,
      Caller_Channel_Transfer_Time,
      Caller_Screen_Bit,
      Caller_Privacy_Hide_Name,
      Caller_Privacy_Hide_Number,
      FreeSWITCH_Switchname,
      Event_Sequence,
      Caller_Callee_ID_Name,
      Caller_Callee_ID_Number,
      Caller_Channel_Bridged_Time,
      Caller_Channel_Hold_Accum,
      Caller_Channel_Last_Hold,
      Caller_Channel_Resurrect_Time,
      Channel_Call_UUID,
      Channel_HIT_Dialplan,
      Other_Leg_ANI,
      Other_Leg_Caller_ID_Name,
      Other_Leg_Caller_ID_Number,
      Other_Leg_Channel_Answered_Time,
      Other_Leg_Channel_Bridged_Time,
      Other_Leg_Channel_Created_Time,
      Other_Leg_Channel_Hangup_Time,
      Other_Leg_Channel_Hold_Accum,
      Other_Leg_Channel_Last_Hold,
      Other_Leg_Channel_Name,
      Other_Leg_Channel_Progress_Media_Time,
      Other_Leg_Channel_Progress_Time,
      Other_Leg_Channel_Resurrect_Time,
      Other_Leg_Channel_Transfer_Time,
      Other_Leg_Context,
      Other_Leg_Destination_Number,
      Other_Leg_Dialplan,
      Other_Leg_Direction,
      Other_Leg_Network_Addr,
      Other_Leg_Privacy_Hide_Name,
      Other_Leg_Privacy_Hide_Number,
      Other_Leg_Profile_Created_Time,
      Other_Leg_Screen_Bit,
      Other_Leg_Source,
      Other_Leg_Unique_ID,
      Other_Leg_Username,
      Other_Type,
      variable_RFC2822_DATE,
      variable_absolute_codec_string,
      variable_advertised_media_ip,
      variable_call_uuid,
      variable_channel_name,
      variable_dialed_domain,
      variable_dialed_extension,
      variable_dialed_user,
      variable_direction,
      variable_dtmf_type,
      variable_ep_codec_string,
      variable_export_vars,
      variable_is_outbound,
      variable_local_media_ip,
      variable_local_media_port,
      variable_max_forwards,
      variable_originate_early_media,
      variable_originating_leg_uuid,
      variable_originator,
      variable_originator_codec,
      variable_presence_id,
      variable_read_codec,
      variable_read_rate,
      variable_recovery_profile_name,
      variable_remote_media_ip,
      variable_remote_media_port,
      variable_rtp_use_ssrc,
      variable_session_id,
      variable_signal_bond,
      variable_sip_audio_recv_pt,
      variable_sip_call_id,
      variable_sip_contact_host,
      variable_sip_contact_port
     );

   Seperator : constant String := ":";
end ESL.Event_Keys;
