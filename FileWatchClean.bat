@echo off
REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : Ư���� ���丮�� ���� �� ���� �������ڸ� �������� ���ؽð� ������ ������ �ֱ������� �����ϱ�       #
REM #                                                                                                                  #
REM # ���α׷��� : FileWatchClean.bat                                                                                  #
REM #                                                                                                                  #
REM # ================================================================================================================ #
REM #    ����        ��¥         �ۼ���          ����                                                                 #
REM #   ------   ------------   ---------   -------------------------------------------------------------------------  #
REM #    v1.0     2018.05.18      k.s.k        �����ۼ�                                                                #
REM #                                                                                                                  #
REM ####################################################################################################################

REM ############################################[ Global Variables START ]##############################################
REM ������ ��ġ ���α׷� Local�θ� ���� �� ���� ���� �� ��� ����ϱ� �ɼ�(EnableDelayedExpansion) �ѱ�
setlocal EnableDelayedExpansion

REM VER : �α׿� version ���� �����.
SET VERSION_INFO=v1.0

REM �Լ� ������ �ڵ� ���� ����
SET Func_Result=0

REM Retry Sleep Time ( Seconds ���� )
SET RETRY_SLEEP_SECONDS=55
REM ############################################[ Global Variables END   ]###############################################


REM ############################################[ Main Fuction START ]###################################################

:BEGIN_PGM
REM �Լ���� ���� �ʱ�ȭ
call :RESET_FUNC_RESULT

REM ���α׷� ��ó�� �۾� - �ʱ�ȭ �� �Ķ���� üũ
call :BATCH_INIT %0 %*
IF %Func_Result% == 255 (
    REM Batch ���α׷� ���� ����
    goto :EXIT_FAILURE_BATCH
)

:RETRY_TASK
REM ���α׷� Main �۾� 
call :BATCH_MAIN
IF %Func_Result% == 255 (
    REM Batch ���α׷� ���� ����
    goto :EXIT_FAILURE_BATCH
)

REM �ݺ����� ���� üũ
IF !RETRY_EXECUTE_COUNT! EQU 0 (
    TIMEOUT /T %RETRY_SLEEP_SECONDS% /NOBREAK
	goto :RETRY_TASK
) ELSE (
    SET /a RETRY_EXECUTE_COUNT-=1
	IF !RETRY_EXECUTE_COUNT! EQU 0 (
	       goto :EXIT_SUCCEESS_BATCH
	) ELSE (
	    TIMEOUT /T %RETRY_SLEEP_SECONDS% /NOBREAK
	    goto :RETRY_TASK
	)
)

REM Batch ���α׷� ���� ����
goto :EXIT_SUCCEESS_BATCH

REM :BEGIN_PGM END

REM ############################################[ Main Fuction End   ]###################################################


REM ############################################[ Sub Fuctions START ]###################################################

REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : ���α׷� ��ó�� �۾� - �ʱ�ȭ �� �Ķ���� üũ                                                      #
REM # ��  ��  �� : BATCH_INIT                                                                                          #
REM #                                                                                                                  #
REM ####################################################################################################################
:BATCH_INIT
REM �Լ���� ���� �ʱ�ȭ
call :RESET_FUNC_RESULT

REM Character Set ���� : 949
chcp 949 > nil

REM START -- Logging ���� �̸� ���� �� ���� �α� �߰�
REM 1. Batch ���� �̸�
SET BATCHFNAME=%1
SET BATCHSNAME=%~n0

REM 2. ������ Logging ������� �� ���� �̸� ``
SET BATCHLOGDIR=C:\FileWatchClean
SET BATCHLOGFILE="%BATCHLOGDIR%\%BATCHSNAME%.log"

REM echo ".. %BATCHLOGDIR%  %BATCHLOGFILE% .."
REM 3. ���� ���丮 ����
SET CURR_DIRECTORY=%cd%
REM 4. Log ���丮 ������ Hidden �Ӽ����� �����ϱ�
IF NOT EXIST %BATCHLOGDIR% (
	call :CREATE_DIR %BATCHLOGDIR%
    IF NOT %Func_Result% == 0 (
        REM ���� �Լ� ����
		call :SET_ERROR_FUNC_RESULT
	    EXIT /B 
    ) 
	call :SET_HIDDEN_ATTR_DIR %BATCHLOGDIR%
)

REM 5. ���α׷� ���� ���� �α� �߰�
echo "%date% %time% [%VERSION_INFO%] Process Start"
call :WRITE_LOG_INFO "---------------------------------------------------"
call :WRITE_LOG_INFO "[%VERSION_INFO%] Process Start"
call :WRITE_LOG_INFO " * Command Line : %*"

REM END  -- Logging ���� �̸� ���� �� ���� �α� �߰�

REM START   -- �Է� �Ķ���� ���� üũ (�߿���� : �������α׷� �̸����� �Ķ���� ���ڷ� �Ѿ�´�.)
SET argc=0
FOR %%x in (%*) do (
    SET /a argc+=1
	REM echo %%x
)

IF %argc% NEQ 4 (
    echo ""
	echo "Usage : %1 [���������������(��ҹ��ڱ���)] [�����Ⱓ(�д���: �ּ� 10�� �̻�)] [����Ƚ��(0�̸� ������ �ݺ�)]"
	echo "  ex1) D:\Applications\logs ������ ���� �߿� �����Ⱓ 1�ð��� ���� ������ 1ȸ �����ϱ�"
	echo "        %1  D:\Applications\logs   60  1 "
	echo "  ex2) D:\Applications\logs ������ ���� �߿� �����Ⱓ 1�ð��� ���� ������ ��� �ݺ� �����ϱ�"
	echo "        %1  D:\Applications\logs   60  0 "
	echo "  ex3) �������������� �����̽����� ���Ե� ��� �����Ⱓ 2�ð��� ���� ������ 3ȸ �����ϱ�"
	echo "        %1  "D:\Applications\ �����̽� ���ԵǸ� �ο빮�ڷ� ����"   120  3 "
	echo ""
    call :WRITE_LOG_ERROR "�Էº��� ����"
    REM ���� �Լ� ����
	call :SET_ERROR_FUNC_RESULT
	EXIT /B 
)
REM END   -- �Է� �Ķ���� ���� üũ (�߿���� : �������α׷� �̸����� �Ķ���� ���ڷ� �Ѿ�´�.)

REM START - Input �� Log ���� ����

REM 2. ���������������
SET WATCHDIR=%2
REM 3. �����Ⱓ(�д���)
SET KEEP_FILES_MINUTE=%3
REM 4. ����Ƚ��
SET RETRY_EXECUTE_COUNT=%4

REM echo "Input Parameters : < %WATCHDIR% , %KEEP_FILES_MINUTE%, %RETRY_EXECUTE_COUNT% >"
REM END   - Input �� Log ���� ����

REM START - Input ���� Validation üũ 
REM parameter 1 : �������� ��� ������ ���� ��� üũ
IF NOT EXIST %WATCHDIR% (
    echo " Error : %WATCHDIR% is not found "
    call :WRITE_LOG_ERROR "%WATCHDIR% is not found "
    REM ���� �Լ� ����
	call :SET_ERROR_FUNC_RESULT
	EXIT /B 
)

REM parameter 2 : �����Ⱓ �� ����
IF %KEEP_FILES_MINUTE% LSS 10 (
    echo "%date% %time% �Է��� �����Ⱓ �� [ %KEEP_FILES_MINUTE% ]�� �ּ������� 10������ �����Ͽ� �����մϴ�."
    call :WRITE_LOG_INFO "�Է��� �����Ⱓ �� [ %KEEP_FILES_MINUTE% ]�� �ּ������� 10������ �����Ͽ� �����մϴ�."
	SET KEEP_FILES_MINUTE=10
) ELSE (
    IF %KEEP_FILES_MINUTE% GEQ a (
        echo "Error : �����Ⱓ ���� 10 �̻� ������ �Է��ϼ���!"
        call :WRITE_LOG_ERROR "�����Ⱓ ���� 10 �̻� ������ �Է��ϼ���!"
        REM ���� �Լ� ����
	    call :SET_ERROR_FUNC_RESULT
    	EXIT /B 	
	)
)
REM parameter 3 : ����Ƚ�� Validation üũ
IF %RETRY_EXECUTE_COUNT% LSS 0 (
    echo "Error : ����Ƚ���� 0 �̻� ������ �Է��ϼ���!"
    call :WRITE_LOG_ERROR "����Ƚ���� 0 �̻� ������ �Է��ϼ���!"
    REM ���� �Լ� ����
	call :SET_ERROR_FUNC_RESULT
	EXIT /B 	
) ELSE (
    IF %RETRY_EXECUTE_COUNT% GEQ a (
        echo "Error : ����Ƚ���� 0 �̻� ������ �Է��ϼ���!"
        call :WRITE_LOG_ERROR "����Ƚ���� 0 �̻� ������ �Է��ϼ���!"
        REM ���� �Լ� ����
	    call :SET_ERROR_FUNC_RESULT
    	EXIT /B 	
	)
)
REM END   - Input ���� Validation üũ 

REM ���� �Լ� ����
EXIT /B 
REM :BATCH_INIT END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : ���α׷� Main �۾� - Log ���� ���� �ֱ��� ���� �� ����                                              #
REM # ��  ��  �� : BATCH_MAIN                                                                                          #
REM #                                                                                                                  #
REM ####################################################################################################################
:BATCH_MAIN
REM �Լ���� ���� �ʱ�ȭ
call :RESET_FUNC_RESULT

REM START - �Ķ���� �ʱ�ȭ �� ���� 
REM ������� ���� ����
SET TOT_FILES=0
SET DEL_FILES=0
SET SKIP_FILES=0
SET ERR_FILES=0

REM working ����
SET WatchFileTimeFormat="dummy time format"
SET WatchFileTime="dummy time"
REM END   - �Ķ���� �ʱ�ȭ �� ���� 


REM ���丮 �˻� ���� �ý��� ���� �� �ð� ȹ��
REM format : yyyymmdd
SET curr_date=%date:~0,4%%date:~5,2%%date:~8,2%
REM �׽�Ʈ�� SET curr_date=20040302
REM format : hhmm - �д����� �ʿ�
SET curr_time=%time:~0,2%%time:~3,2%
REM �׽�Ʈ�� SET curr_time=0011

FOR /R "%WATCHDIR%" %%i in (*) do (
    REM echo "%%~i, %%~ti"
    REM ��� : ���� ���� ���� �� ����
	SET /A TOT_FILES+=1
	REM �ð� ���� ���� �м� - 12H, 24H
	call :ANAL_TIME_FORMAT "%%~ti"
	REM �׽�Ʈ�� - call :ANAL_TIME_FORMAT "2018-05-01 HEY 09:15 "
	IF "!WatchFileTimeFormat:~0,7!" == "UnKnown" (
	    REM ������ ��¥ ������ tt hh:mm:ss  or hh:mm:ss ������ �ƴ� ���·� ����ó���Ѵ�. 
		REM ����ó���Ϸ���, ������ ��¥ ���˿� ���߾� :ANAL_TIME_FORMAT�� ������ �����ϴ���? ������ ��¥ ������ �����Ѵ�.
		echo "������ ��¥ ���� �м� ����(tt hh:mm:ss or hh:mm:ss ���� �ƴ�) - !WatchFileTimeFormat!"
		call :WRITE_LOG_ERROR "[%%~i][%%~ti] ������ ��¥ ���� �м� ����(tt hh:mm:ss or hh:mm:ss ���� �ƴ�) - !WatchFileTimeFormat!"
		REM ��� : �����߻� ���� ���� �� ����
		SET /A ERR_FILES+=1
        REM ���α׷� ���� ��� �α� �߰�
        echo "ó����� : �� !TOT_FILES! �� = ���� !SKIP_FILES! �� + ���� !DEL_FILES! �� + ���� !ERR_FILES! �� "
        call :WRITE_LOG_INFO " - ó����� : �� !TOT_FILES! �� = ���� !SKIP_FILES! �� + ���� !DEL_FILES! �� + ���� !ERR_FILES! ��"
        REM ���� �Լ� ����
		call :SET_ERROR_FUNC_RESULT
	    EXIT /B 
	)
	REM ���� �� ����, ANAL_TIME_FORMAT���� ������ ������ �̿��Ͽ� üũ 
	call :JUDGE_KEEP_FILE "%%~i"
	REM ���ؽð� ���� ������ ����ó��
	IF !is_before_time_file! == "TRUE" (
	    call :DELETE_FILE "%%~i"
	) ELSE (
	    REM ��� : ������� ���� ���� �� ����
	    SET /A SKIP_FILES+=1
	)
)

REM ���α׷� ���� ��� �α� �߰�
echo "ó����� : �� !TOT_FILES! �� = ���� !SKIP_FILES! �� + ���� !DEL_FILES! �� + ���� !ERR_FILES! �� "
call :WRITE_LOG_INFO " - ó����� : �� !TOT_FILES! �� = ���� !SKIP_FILES! �� + ���� !DEL_FILES! �� + ���� !ERR_FILES! ��"

REM ���� �Լ� ����
EXIT /B 
REM :BATCH_MAIN END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : ������ �ð� ���� �м��ϱ�                                                                           #
REM # ��  ��  �� : ANAL_TIME_FORMAT                                                                                    #
REM #                                                                                                                  #
REM ####################################################################################################################
:ANAL_TIME_FORMAT
REM �Լ���� ���� �ʱ�ȭ
call :RESET_FUNC_RESULT

FOR /F "tokens=1,2,3 delims= " %%A in ( "%1" ) do (
    SET WatchFileTime=%%A %%C
    IF "%%B" == "����" (
	    SET WatchFileTimeFormat="Morning"
	) ELSE (
        IF "%%B" == "am" (
		    SET WatchFileTimeFormat="Morning"
		) ELSE (
    		IF "%%B" == "AM" (
			    SET WatchFileTimeFormat="Morning"
			) ELSE (
                IF "%%B" == "����" (
    				SET WatchFileTimeFormat="Afternoon"
				) ELSE (
                    IF "%%B" == "pm" (
					    SET WatchFileTimeFormat="Afternoon"
					) ELSE (
	                    IF "%%B" == "PM" (
						    SET WatchFileTimeFormat="Afternoon"
						) ELSE SET WatchFileTimeFormat=UnKnown:%%B
					)
				)
			)
		)
	)
	IF "%%C" == "" (
	    SET WatchFileTimeFormat="24hour"
		SET WatchFileTime=%%B
	)
	REM echo ":ANAL_TIME_FORMAT => %%B, %%C, !WatchFileTimeFormat!, !WatchFileTime!"
)

REM ���� �Լ� ����
EXIT /B 
REM :ANAL_TIME_FORMAT END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : ������ �ð��� �����Ⱓ�� ���Ͽ� ���� ���� �����ϱ�                                                #
REM # ��  ��  �� : JUDGE_KEEP_FILE                                                                                     #
REM #                                                                                                                  #
REM ####################################################################################################################
:JUDGE_KEEP_FILE
REM �Լ���� ���� �ʱ�ȭ
call :RESET_FUNC_RESULT

REM [[ ���� ���� �ð� ��� ]] ================================<< START >>===============================
REM current �ð����� �����Ⱓ�� �� ���� yymmddhhmm format���� ���
REM Minutes ���� ��� 
IF "%curr_time:~2,1%" == "0" (
	SET /a calc_minutes="%curr_time:~3,1%-%KEEP_FILES_MINUTE%"
    REM echo "!calc_minutes! = %curr_time:~3,1% - %KEEP_FILES_MINUTE%"
) ELSE (
    SET /a calc_minutes="%curr_time:~2,2%-%KEEP_FILES_MINUTE%"
    REM echo "!calc_minutes! = %curr_time:~2,2% - %KEEP_FILES_MINUTE%"
)
IF !calc_minutes! GTR 10 (
    SET calc_datetime=%curr_date%%curr_time:~0,2%!calc_minutes!
) ELSE (
    IF !calc_minutes! GEQ 0 (
        SET calc_datetime=%curr_date%%curr_time:~0,2%0!calc_minutes!
    ) ELSE (
		REM 60�� ȹ���Ͽ� �����ֱ�
		SET /a calc_minutes="!calc_minutes!+60"
	    REM hours -1 �����ϱ� 
		IF "%curr_time:~0,1%" == "0" (
		         SET /a calc_hours="%curr_time:~1,1%-1"
		) ELSE   SET /a calc_hours="%curr_time:~0,2%-1"
		IF !calc_hours! GEQ 10 (
		    SET calc_datetime=%curr_date%!calc_hours!!calc_minutes!
		) ELSE (
		    IF !calc_hours! GEQ 0 (
		        SET calc_datetime=%curr_date%0!calc_hours!!calc_minutes!
			) ELSE (
				REM 24�ð� ȹ���Ͽ� �����ֱ� 
				SET /a calc_hours="!calc_hours!+24"
		        REM ��¥ �����ʿ�
				SET curr_year=%curr_date:~0,4%
				SET curr_month=%curr_date:~4,2%
			    REM Day -1 �����ϱ�
				IF "%curr_date:~6,1%" == "0" (
				          SET /a calc_days="%curr_date:~7,1%-1"
				) ELSE    SET /a calc_days="%curr_date:~6,2%-1" 
                IF !calc_days! GTR 10 (
                    SET calc_date=!curr_year!!curr_month!!calc_days!        
                ) ELSE (
	 			    IF !calc_days! GTR 0 (
				        SET calc_date=!curr_year!!curr_month!0!calc_days!
				    ) ELSE (
                        REM MONTH �����ʿ�  
						IF "!curr_month:~0,1!" == "0" (
						          SET /a calc_month="!curr_month:~1,1!"
						) ELSE    SET /a calc_month="!curr_month!"						
						REM !calc_month!�� 3���̸�, ������ 2���� Day ��� �� ������ ����Ͽ� 28,29,¦��/Ȧ�� ����Ͽ� 30,31�� �����ش�.
						IF !calc_month! EQU 3 (
							REM ���� üũ�ϱ�
    						call :CHECK_LEAP_YEAR "!curr_year!"
							IF !is_leap_year!	== "TRUE" (
							    REM �������� 29���� ȹ���Ͽ� �����ֱ�
							    SET /a calc_days+=29
							) ELSE (
							    REM ������� 28���� ȹ���Ͽ� �����ֱ�
							    SET /a calc_days+=28
							)
							REM MONTH -1 �����ϱ�
							SET /a calc_month-=1
							REM YEAR ���� ����
							SET /a calc_year=!curr_year!
						) ELSE (
						    IF !calc_month! EQU 1 (
							    REM 1���� ������ 12������ 31�� ȹ���Ͽ� �����ֱ�
							    SET /a calc_days+=31
								SET calc_month=12
								REM 1���� YEAR-1 �����ϱ�
								SET /a calc_year="!curr_year!-1"
							) ELSE (
							    SET /a mod_by_2="!calc_month!%%2"
								REM ¦������ 31�� �����ֱ�
								IF !mod_by_2! EQU 0 (
						            REM ¦������ �������� 31�� ȹ���Ͽ� �����ֱ�
									SET /a calc_days+=31
								) ELSE (
						            REM Ȧ������ �������� 30�� ȹ���Ͽ� �����ֱ�
									SET /a calc_days+=30
                                )
    							REM MONTH -1 �����ϱ�
								SET /a calc_month-=1
							    REM YEAR ���� ����
							    SET /a calc_year=!curr_year!
							)
						)
                        IF !calc_month! LSS 10 (
						          SET calc_date=!calc_year!0!calc_month!!calc_days!
						) ELSE    SET calc_date=!calc_year!!calc_month!!calc_days!
                    )
                )							
				IF !calc_hours! LSS 10 (
				        SET calc_datetime=!calc_date!0!calc_hours!!calc_minutes!
				) ELSE  SET calc_datetime=!calc_date!!calc_hours!!calc_minutes!
			)
		)
    )
)
REM [[ ���� ���� �ð� ��� ]] ================================<< END   >>===============================

REM [[ ���� �ð� ��� ]] ================================<< START >>===============================
IF !WatchFileTimeFormat! == "Afternoon" (
    REM Afternoon�� 12�ð��� ���ϴ� �ð������� �Ѵ�.
	IF "!WatchFileTime:~12,1!" == "0" (
	          SET /a file_calc_hours="!WatchFileTime:~13,1!+12"
	) ELSE    SET /a file_calc_hours="!WatchFileTime:~12,2!+12"
    SET file_datetime=!WatchFileTime:~1,4!!WatchFileTime:~6,2!!WatchFileTime:~9,2!!file_calc_hours!!WatchFileTime:~15,2!
) ELSE (
    REM Morning�� 24hour �� �ð� ���� ����
    SET file_datetime=!WatchFileTime:~1,4!!WatchFileTime:~6,2!!WatchFileTime:~9,2!!WatchFileTime:~12,2!!WatchFileTime:~15,2!
)
REM [[ ���� �ð� ��� ]] ================================<< END   >>===============================

REM [[ �������� üũ ]] ================================<< START >>===============================
SET /a diff_time1=!file_datetime:~0,6!-!calc_datetime:~0,6!
SET diff_time2=
IF !diff_time1! GTR 0 (
    SET is_before_time_file="FALSE"
) ELSE (
    IF !diff_time1! LSS 0 (
	    SET is_before_time_file="TRUE"
	) ELSE (
        IF "!file_datetime:~6,1!" == "0" (
            IF "!calc_datetime:~6,1!" == "0" (
	                  SET /a diff_time2=!file_datetime:~7,5!-!calc_datetime:~7,5!
	        ) ELSE    SET /a diff_time2=!file_datetime:~7,5!-!calc_datetime:~6,6!
        ) ELSE (
            IF "!calc_datetime:~6,1!" == "0" (
                   SET /a diff_time2=!file_datetime:~6,6!-!calc_datetime:~7,5!
	        ) ELSE SET /a diff_time2=!file_datetime:~6,6!-!calc_datetime:~6,6!
        )
		IF !diff_time2! GEQ 0 (
		       SET is_before_time_file="FALSE"
		) ELSE SET is_before_time_file="TRUE"
	)
)
REM echo "!WatchFileTime! !WatchFileTime:~1,4! !WatchFileTime:~6,2! !WatchFileTime:~9,2! !WatchFileTime:~12,2! !WatchFileTime:~15,2!"
REM echo "calc_datetime => !calc_datetime!, file_datetime => !file_datetime!, is_before_time_file=!is_before_time_file! "
REM [[ �������� üũ ]] ================================<< END   >>===============================

REM ���� �Լ� ����
EXIT /B 
REM :JUDGE_KEEP_FILE END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : ���⿩�� ����ϱ�                                                                                   #
REM # ��  ��  �� : CHECK_LEAP_YEAR                                                                                     #
REM #                                                                                                                  #
REM ####################################################################################################################
:CHECK_LEAP_YEAR
REM �Լ���� ���� �ʱ�ȭ
call :RESET_FUNC_RESULT

REM �������ϱ� - 1) 4�� ����� ���� 2) 100�� ����� ��� 3) 100�� ����̰� 400�� ����� ����
SET /a mod_by_4="!curr_year!%%4"
SET /a mod_by_100="!curr_year!%%100"
SET /a mod_by_400="!curr_year!%%400"

IF !mod_by_4! EQU 0 (
    IF !mod_by_100! EQU 0 (
	    IF !mod_by_400! EQU 0 (
		    SET is_leap_year="TRUE"
		) ELSE (
	        SET is_leap_year="FALSE"
		)
	) ELSE (
	    SET is_leap_year="TRUE"
	)
) ELSE (
    SET is_leap_year="FALSE"
)
REM ���� �Լ� ����
EXIT /B 
REM :CHECK_LEAP_YEAR END


REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : ���丮 �����ϱ�                                                                                   #
REM # ��  ��  �� : CREATE_DIR                                                                                          #
REM #                                                                                                                  #
REM ####################################################################################################################
:CREATE_DIR
REM �Լ���� ���� �ʱ�ȭ
call :RESET_FUNC_RESULT

REM ���丮 �����ϱ�
mkdir %1
IF NOT %ERRORLEVEL% == 0 (
    REM ���� �Լ� ����
    call :SET_ERROR_FUNC_RESULT
    EXIT /B 
)
REM ���� �Լ� ����
EXIT /B 
REM :CREATE_DIR END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : ���丮 Hidden �Ӽ����� ����                                                                       #
REM # ��  ��  �� : SET_HIDDEN_ATTR_DIR                                                                                 #
REM #                                                                                                                  #
REM ####################################################################################################################
:SET_HIDDEN_ATTR_DIR
REM �Լ���� ���� �ʱ�ȭ
call :RESET_FUNC_RESULT

REM Hidden system �Ӽ� ����
attrib +H +S %1
	
REM ���� �Լ� ����
EXIT /B 
REM :SET_HIDDEN_ATTR_DIR END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : ������ �����ϱ�                                                                                     #
REM # ��  ��  �� : DELETE_FILE                                                                                         #
REM #                                                                                                                  #
REM ####################################################################################################################
:DELETE_FILE
REM �Լ���� ���� �ʱ�ȭ
call :RESET_FUNC_RESULT

REM �����ϱ�
del %~1 2> "%~1.del"

REM ��� : ������� ���� ���� �� ����
IF NOT EXIST %~1 (
    SET /A DEL_FILES+=1
) ELSE (
      SET /A ERR_FILES+=1
      call :WRITE_LOG_INFO "[%~1] ���� Delete �� ���� �߻�"
	  REM del ���� �������� �α����Ͽ� �߰�
	  type "%~1.del" >> %BATCHLOGFILE%
)
REM �������� ��� �ӽ÷α� �����ϱ�
del "%~1.del" 2> nil
REM ���� �Լ� ����
EXIT /B 
REM :DELETE_FILE END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : ���� ���ڿ��� �α����Ͽ� ����                                                                       #
REM # ��  ��  �� : WRITE_LOG_ERROR                                                                                     #
REM #                                                                                                                  #
REM ####################################################################################################################
:WRITE_LOG_ERROR
call :WRITE_LOG "(E)%date% %time% :%~1"
REM ���� �Լ� ����
EXIT /B 
REM :WRITE_LOG_ERROR END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : Information ���ڿ��� �α����Ͽ� ����                                                                #
REM # ��  ��  �� : WRITE_LOG_INFO                                                                                      #
REM #                                                                                                                  #
REM ####################################################################################################################
:WRITE_LOG_INFO
call :WRITE_LOG "(I)%date% %time% :%~1"
REM ���� �Լ� ����
EXIT /B 
REM :WRITE_LOG_INFO END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : DEBUG ���ڿ��� �α����Ͽ� ����                                                                      #
REM # ��  ��  �� : WRITE_LOG_DEBUG                                                                                     #
REM #                                                                                                                  #
REM ####################################################################################################################
:WRITE_LOG_DEBUG
call :WRITE_LOG_DEBUG "(D)%date% %time% :%~1"
REM ���� �Լ� ����
EXIT /B 
REM :WRITE_LOG_DEBUG END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : ���ڿ��� �α����Ͽ� ����                                                                            #
REM # ��  ��  �� : WRITE_LOG                                                                                           #
REM #                                                                                                                  #
REM ####################################################################################################################
:WRITE_LOG
REM �Լ���� ���� �ʱ�ȭ
call :RESET_FUNC_RESULT

REM echo "WRITE_LOG ���� Ȯ�� : %BATCHLOGDIR%, %BATCHLOGFILE%"
REM ���丮 �����ϱ�
IF EXIST %BATCHLOGFILE% (
    REM LOG ���� ���丮�� �̵�
    cd "%BATCHLOGDIR%"
    FOR  %%i in ( %BATCHLOGFILE% ) do (
        REM echo "WRITE_LOG ���ϻ�����: %BATCHLOGFILE% %%~zi "
	    IF %%~zi GTR 512000 ( 
            del "%%~i.bak" 2>nul
            ren "%%~i" "%BATCHSNAME%.log.bak"
            echo ============================================================= >> %BATCHLOGFILE%
            echo %DATE% %TIME% Logfile Backup And Re-create >> %BATCHLOGFILE%
            echo ============================================================= >> %BATCHLOGFILE%
        )
    )
	REM ���� ���丮�� ��ȯ
	cd "%CURR_DIRECTORY%"
) ELSE (
    echo ============================================================= >> %BATCHLOGFILE%
    echo %DATE% %TIME% Logfile is not exist Logfile create >> %BATCHLOGFILE%
    echo ============================================================= >> %BATCHLOGFILE%
)
echo %~1 >> %BATCHLOGFILE%

REM ���� �Լ� ����
EXIT /B 
REM :WRITE_LOG END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : �Լ� ó������ڵ� ���� �ʱ�ȭ ó��                                                                  #
REM # ��  ��  �� : RESET_FUNC_RESULT                                                                                   #
REM #                                                                                                                  #
REM ####################################################################################################################
:RESET_FUNC_RESULT
SET Func_Result=0
REM ���� �Լ� ����
EXIT /B 
REM :RESET_FUNC_RESULT END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : �Լ� ó����� ���� �ڵ� ���� ����                                                                   #
REM # ��  ��  �� : SER_ERROR_FUNC_RESULT                                                                               #
REM #                                                                                                                  #
REM ####################################################################################################################
:SET_ERROR_FUNC_RESULT
SET Func_Result=255
REM ���� �Լ� ����
EXIT /B 
REM :SET_ERROR_FUNC_RESULT END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : ���α׷� ���� ����ó��                                                                              #
REM # ��  ��  �� : EXIT_SUCCEESS_BATCH                                                                                 #
REM #                                                                                                                  #
REM ####################################################################################################################
:EXIT_SUCCEESS_BATCH
REM ���α׷� ���� ���� ���� �α� �߰�
echo "%date% %time% [%VERSION_INFO%] Process Success Stop "
call :WRITE_LOG_INFO "[%VERSION_INFO%] Process Success Stop"

endlocal
REM ���α׷� ���� ����
EXIT /B 0
REM :EXIT_SUCCEESS_BATCH END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # ��      �� : ���α׷� ���� ����ó��                                                                              #
REM # ��  ��  �� : EXIT_FAILURE_BATCH                                                                                  #
REM #                                                                                                                  #
REM ####################################################################################################################
:EXIT_FAILURE_BATCH
REM ���α׷� ���� ���� ���� �α� �߰�
echo "%date% %time% [%VERSION_INFO%] Process Error Stop "
call :WRITE_LOG_ERROR "[%VERSION_INFO%] Process Error Stop"

endlocal
REM ���α׷� ���� ����
EXIT /B 255
REM :EXIT_FAILURE_BATCH END

REM ############################################[ Sub Fuctions END   ]##################################################
