SELECT A.max_length , B.max_length, 
* 
from sys.columns A
	join sys.columns B on
		A.[name] = B.[name]
	and B.OBJECT_ID = OBJECT_ID('qLoad.dimPolicyInsert')
where A.OBJECT_ID = OBJECT_ID('qDm.dimPolicy')
	and A.max_length <> B.max_length