use [DWH_QuantumDM];


--declare @LoadLogId bigint;

--exec Logging.GetLoadLogId
--    @ServerExecutionID = null,
--    @LoadLogId = @LoadLogId output;

--select @LoadLogId as LoadLogId;

--exec [qLoad].[Load_dimAccount] @LoadLogId = @LoadLogId;

--exec [qLoad].[Load_dimPolicy] @LoadLogId = @LoadLogId;

----exec [qLoad].[Load_dimCalendar] @LoadLogId = @LoadLogId;

--exec [qLoad].[Load_dimPolicyLimit] @LoadLogId = @LoadLogId;

--exec [qLoad].[Load_factPolicyWrittenPremium] @LoadLogId = @LoadLogId;

--exec [qLoad].[Load_factGeneralLedger] @LoadLogId = @LoadLogId;


/* 
SELECT * FROM qDm.dimAccount

SELECT * FROM qDm.dimCalendar

SELECT top 100 * FROM qDm.dimPolicyLimit



SELECT top 100 * FROM qDm.dimPolicy

SELECT top 1000 * FROM qDM.factPolicyWrittenPremium

SELECT top 1000 * FROM qDm.factGeneralLedger

SELECT top 100 * FROM qDm.factPolicyWrittenPremium

SELECT * FROM qDm.dimCedant

SELECT * FROM qDm.dimBroker
*/


