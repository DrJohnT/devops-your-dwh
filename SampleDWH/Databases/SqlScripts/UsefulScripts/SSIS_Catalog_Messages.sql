/*
 * For viewing SSIS catalog messages
 * Uncomment the message_type part to add filters
 */
SELECT 
	@@servername as database_name
		,event_message_id
		--,cast(message_time as datetime) as message_time
		,package_name
		,message_source_name
		,event_name
		,[message]
		,operation_id
		--,package_path
		,execution_path
		--,message_type_name
		--,message_source_type
FROM   (
       SELECT  em.*,
			case 
				when message_type = 120 then 'Error'
				when message_type = 110 then 'Warning'
				when message_type = 70 then 'Info'
				else 'Other'
			end as message_type_name
       FROM    SSISDB.catalog.event_messages em
       WHERE
			em.operation_id = (SELECT MAX(execution_id) FROM SSISDB.catalog.executions) 
           and event_name NOT LIKE '%Validate%'
		   and message_type in (
		120	-- Error
		--,110	-- warning	
		--,70		-- Info
		)
       ) q
ORDER BY operation_id desc, event_message_id desc