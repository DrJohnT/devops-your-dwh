/*
{| class="wikitable"
!colspan="8"|Source to Target Mapping: Quantum to QuantumDM
|+
!colspan="5" |QuantumDM Data Mart View ||colspan="3" |Quantum Table 
|+
!View Name ||Column Name ||Comment ||Data Type ||Length ||Database ||Table ||Column 
*/
use DWH_Metadata;

with twoRows as (
select '|-' as NewRow, 1 as Indicator
union all
select '' as NewRow, 2 as Indicator
)

select 
case when twoRows.Indicator = 1 then twoRows.NewRow
else 
N'||' + ViewNameInQuantumDM + N' ||' + ColumnNameInQuantumDM + N' ||' + Comment + N' ||' + DataType + N' || style="text-align:right;" |' + [Length] + N' ||' + SourceDatabaseName + N' ||' + SourceTableName + N' ||' + SourceColumnName 
end as WikiText

FROM twoRows
cross join (
select distinct ViewNameInQuantumDM , ColumnNameInQuantumDM ,Comment , DataType , [Length] , SourceDatabaseName ,SourceTableName , SourceColumnName  from [Metadata].[QuantumDataMartColumnMapping]
) as B
--order by ViewNameInQuantumDM, ColumnNameInQuantumDM, Indicator

/*
End table
|}
*/

