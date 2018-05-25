@echo off
REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : 특정한 디렉토리의 파일 중 파일 변경일자를 기준으로 기준시간 이전의 파일을 주기적으로 삭제하기       #
REM #                                                                                                                  #
REM # 프로그램명 : FileWatchClean.bat                                                                                  #
REM #                                                                                                                  #
REM # ================================================================================================================ #
REM #    버전        날짜         작성자          내용                                                                 #
REM #   ------   ------------   ---------   -------------------------------------------------------------------------  #
REM #    v1.0     2018.05.18      k.s.k        최초작성                                                                #
REM #                                                                                                                  #
REM ####################################################################################################################

REM ############################################[ Global Variables START ]##############################################
REM 변수를 배치 프로그램 Local로만 정의 및 변수 셋팅 후 즉시 사용하기 옵션(EnableDelayedExpansion) 켜기
setlocal EnableDelayedExpansion

REM VER : 로그에 version 정보 남기기.
SET VERSION_INFO=v1.0

REM 함수 실행결과 코드 변수 설정
SET Func_Result=0

REM Retry Sleep Time ( Seconds 단위 )
SET RETRY_SLEEP_SECONDS=55
REM ############################################[ Global Variables END   ]###############################################


REM ############################################[ Main Fuction START ]###################################################

:BEGIN_PGM
REM 함수결과 변수 초기화
call :RESET_FUNC_RESULT

REM 프로그램 선처리 작업 - 초기화 및 파라미터 체크
call :BATCH_INIT %0 %*
IF %Func_Result% == 255 (
    REM Batch 프로그램 정상 종료
    goto :EXIT_FAILURE_BATCH
)

:RETRY_TASK
REM 프로그램 Main 작업 
call :BATCH_MAIN
IF %Func_Result% == 255 (
    REM Batch 프로그램 정상 종료
    goto :EXIT_FAILURE_BATCH
)

REM 반복실행 여부 체크
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

REM Batch 프로그램 정상 종료
goto :EXIT_SUCCEESS_BATCH

REM :BEGIN_PGM END

REM ############################################[ Main Fuction End   ]###################################################


REM ############################################[ Sub Fuctions START ]###################################################

REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : 프로그램 선처리 작업 - 초기화 및 파라미터 체크                                                      #
REM # 함  수  명 : BATCH_INIT                                                                                          #
REM #                                                                                                                  #
REM ####################################################################################################################
:BATCH_INIT
REM 함수결과 변수 초기화
call :RESET_FUNC_RESULT

REM Character Set 설정 : 949
chcp 949 > nil

REM START -- Logging 파일 이름 설정 및 시작 로그 추가
REM 1. Batch 파일 이름
SET BATCHFNAME=%1
SET BATCHSNAME=%~n0

REM 2. 실행결과 Logging 폴더경로 및 파일 이름 ``
SET BATCHLOGDIR=C:\FileWatchClean
SET BATCHLOGFILE="%BATCHLOGDIR%\%BATCHSNAME%.log"

REM echo ".. %BATCHLOGDIR%  %BATCHLOGFILE% .."
REM 3. 실행 디렉토리 정보
SET CURR_DIRECTORY=%cd%
REM 4. Log 디렉토리 없으면 Hidden 속성으로 생성하기
IF NOT EXIST %BATCHLOGDIR% (
	call :CREATE_DIR %BATCHLOGDIR%
    IF NOT %Func_Result% == 0 (
        REM 오류 함수 종료
		call :SET_ERROR_FUNC_RESULT
	    EXIT /B 
    ) 
	call :SET_HIDDEN_ATTR_DIR %BATCHLOGDIR%
)

REM 5. 프로그램 실행 시작 로그 추가
echo "%date% %time% [%VERSION_INFO%] Process Start"
call :WRITE_LOG_INFO "---------------------------------------------------"
call :WRITE_LOG_INFO "[%VERSION_INFO%] Process Start"
call :WRITE_LOG_INFO " * Command Line : %*"

REM END  -- Logging 파일 이름 설정 및 시작 로그 추가

REM START   -- 입력 파라미터 갯수 체크 (중요사항 : 실행프로그램 이름부터 파라미터 인자로 넘어온다.)
SET argc=0
FOR %%x in (%*) do (
    SET /a argc+=1
	REM echo %%x
)

IF %argc% NEQ 4 (
    echo ""
	echo "Usage : %1 [보존관리폴더경로(대소문자구별)] [보존기간(분단위: 최소 10분 이상)] [실행횟수(0이면 무제한 반복)]"
	echo "  ex1) D:\Applications\logs 폴더의 파일 중에 보존기간 1시간이 지난 파일을 1회 실행하기"
	echo "        %1  D:\Applications\logs   60  1 "
	echo "  ex2) D:\Applications\logs 폴더의 파일 중에 보존기간 1시간이 지난 파일을 계속 반복 실행하기"
	echo "        %1  D:\Applications\logs   60  0 "
	echo "  ex3) 보존관리폴더에 스페이스등이 포함된 경우 보존기간 2시간이 지난 파일을 3회 실행하기"
	echo "        %1  "D:\Applications\ 스페이스 포함되면 인용문자로 묶기"   120  3 "
	echo ""
    call :WRITE_LOG_ERROR "입력변수 오류"
    REM 오류 함수 종료
	call :SET_ERROR_FUNC_RESULT
	EXIT /B 
)
REM END   -- 입력 파라미터 갯수 체크 (중요사항 : 실행프로그램 이름부터 파라미터 인자로 넘어온다.)

REM START - Input 및 Log 변수 설정

REM 2. 보존관리폴더경로
SET WATCHDIR=%2
REM 3. 보존기간(분단위)
SET KEEP_FILES_MINUTE=%3
REM 4. 실행횟수
SET RETRY_EXECUTE_COUNT=%4

REM echo "Input Parameters : < %WATCHDIR% , %KEEP_FILES_MINUTE%, %RETRY_EXECUTE_COUNT% >"
REM END   - Input 및 Log 변수 설정

REM START - Input 변수 Validation 체크 
REM parameter 1 : 삭제파일 경로 폴더가 없는 경우 체크
IF NOT EXIST %WATCHDIR% (
    echo " Error : %WATCHDIR% is not found "
    call :WRITE_LOG_ERROR "%WATCHDIR% is not found "
    REM 오류 함수 종료
	call :SET_ERROR_FUNC_RESULT
	EXIT /B 
)

REM parameter 2 : 보존기간 값 설정
IF %KEEP_FILES_MINUTE% LSS 10 (
    echo "%date% %time% 입력한 보존기간 값 [ %KEEP_FILES_MINUTE% ]은 최소조건인 10분으로 조정하여 실행합니다."
    call :WRITE_LOG_INFO "입력한 보존기간 값 [ %KEEP_FILES_MINUTE% ]은 최소조건인 10분으로 조정하여 실행합니다."
	SET KEEP_FILES_MINUTE=10
) ELSE (
    IF %KEEP_FILES_MINUTE% GEQ a (
        echo "Error : 보존기간 값은 10 이상 정수로 입력하세요!"
        call :WRITE_LOG_ERROR "보존기간 값은 10 이상 정수로 입력하세요!"
        REM 오류 함수 종료
	    call :SET_ERROR_FUNC_RESULT
    	EXIT /B 	
	)
)
REM parameter 3 : 실행횟수 Validation 체크
IF %RETRY_EXECUTE_COUNT% LSS 0 (
    echo "Error : 실행횟수는 0 이상 정수로 입력하세요!"
    call :WRITE_LOG_ERROR "실행횟수는 0 이상 정수로 입력하세요!"
    REM 오류 함수 종료
	call :SET_ERROR_FUNC_RESULT
	EXIT /B 	
) ELSE (
    IF %RETRY_EXECUTE_COUNT% GEQ a (
        echo "Error : 실행횟수는 0 이상 정수로 입력하세요!"
        call :WRITE_LOG_ERROR "실행횟수는 0 이상 정수로 입력하세요!"
        REM 오류 함수 종료
	    call :SET_ERROR_FUNC_RESULT
    	EXIT /B 	
	)
)
REM END   - Input 변수 Validation 체크 

REM 정상 함수 종료
EXIT /B 
REM :BATCH_INIT END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : 프로그램 Main 작업 - Log 삭제 파일 주기적 감시 및 삭제                                              #
REM # 함  수  명 : BATCH_MAIN                                                                                          #
REM #                                                                                                                  #
REM ####################################################################################################################
:BATCH_MAIN
REM 함수결과 변수 초기화
call :RESET_FUNC_RESULT

REM START - 파라미터 초기화 및 셋팅 
REM 실행통계 정보 관리
SET TOT_FILES=0
SET DEL_FILES=0
SET SKIP_FILES=0
SET ERR_FILES=0

REM working 변수
SET WatchFileTimeFormat="dummy time format"
SET WatchFileTime="dummy time"
REM END   - 파라미터 초기화 및 셋팅 


REM 디렉토리 검색 직전 시스템 일자 및 시간 획득
REM format : yyyymmdd
SET curr_date=%date:~0,4%%date:~5,2%%date:~8,2%
REM 테스트용 SET curr_date=20040302
REM format : hhmm - 분단위만 필요
SET curr_time=%time:~0,2%%time:~3,2%
REM 테스트용 SET curr_time=0011

FOR /R "%WATCHDIR%" %%i in (*) do (
    REM echo "%%~i, %%~ti"
    REM 통계 : 점검 누적 파일 총 갯수
	SET /A TOT_FILES+=1
	REM 시간 정보 포맷 분석 - 12H, 24H
	call :ANAL_TIME_FORMAT "%%~ti"
	REM 테스트용 - call :ANAL_TIME_FORMAT "2018-05-01 HEY 09:15 "
	IF "!WatchFileTimeFormat:~0,7!" == "UnKnown" (
	    REM 윈도우 날짜 포맷이 tt hh:mm:ss  or hh:mm:ss 포맷이 아닌 형태로 오류처리한다. 
		REM 정상처리하려면, 윈도우 날짜 포맷에 맞추어 :ANAL_TIME_FORMAT의 내용을 수정하던지? 윈도우 날짜 포맷을 변경한다.
		echo "윈도우 날짜 포맷 분석 오류(tt hh:mm:ss or hh:mm:ss 포맷 아님) - !WatchFileTimeFormat!"
		call :WRITE_LOG_ERROR "[%%~i][%%~ti] 윈도우 날짜 포맷 분석 오류(tt hh:mm:ss or hh:mm:ss 포맷 아님) - !WatchFileTimeFormat!"
		REM 통계 : 에러발생 누적 파일 총 갯수
		SET /A ERR_FILES+=1
        REM 프로그램 수행 통계 로그 추가
        echo "처리결과 : 총 !TOT_FILES! 개 = 보존 !SKIP_FILES! 개 + 삭제 !DEL_FILES! 개 + 에러 !ERR_FILES! 개 "
        call :WRITE_LOG_INFO " - 처리결과 : 총 !TOT_FILES! 개 = 보존 !SKIP_FILES! 개 + 삭제 !DEL_FILES! 개 + 에러 !ERR_FILES! 개"
        REM 오류 함수 종료
		call :SET_ERROR_FUNC_RESULT
	    EXIT /B 
	)
	REM 파일 비교 정보, ANAL_TIME_FORMAT에서 셋팅한 변수를 이용하여 체크 
	call :JUDGE_KEEP_FILE "%%~i"
	REM 기준시간 이전 파일은 삭제처리
	IF !is_before_time_file! == "TRUE" (
	    call :DELETE_FILE "%%~i"
	) ELSE (
	    REM 통계 : 보존대상 누적 파일 총 갯수
	    SET /A SKIP_FILES+=1
	)
)

REM 프로그램 수행 통계 로그 추가
echo "처리결과 : 총 !TOT_FILES! 개 = 보존 !SKIP_FILES! 개 + 삭제 !DEL_FILES! 개 + 에러 !ERR_FILES! 개 "
call :WRITE_LOG_INFO " - 처리결과 : 총 !TOT_FILES! 개 = 보존 !SKIP_FILES! 개 + 삭제 !DEL_FILES! 개 + 에러 !ERR_FILES! 개"

REM 정상 함수 종료
EXIT /B 
REM :BATCH_MAIN END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : 파일의 시간 포맷 분석하기                                                                           #
REM # 함  수  명 : ANAL_TIME_FORMAT                                                                                    #
REM #                                                                                                                  #
REM ####################################################################################################################
:ANAL_TIME_FORMAT
REM 함수결과 변수 초기화
call :RESET_FUNC_RESULT

FOR /F "tokens=1,2,3 delims= " %%A in ( "%1" ) do (
    SET WatchFileTime=%%A %%C
    IF "%%B" == "오전" (
	    SET WatchFileTimeFormat="Morning"
	) ELSE (
        IF "%%B" == "am" (
		    SET WatchFileTimeFormat="Morning"
		) ELSE (
    		IF "%%B" == "AM" (
			    SET WatchFileTimeFormat="Morning"
			) ELSE (
                IF "%%B" == "오후" (
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

REM 정상 함수 종료
EXIT /B 
REM :ANAL_TIME_FORMAT END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : 파일의 시간과 보존기간을 비교하여 이전 파일 삭제하기                                                #
REM # 함  수  명 : JUDGE_KEEP_FILE                                                                                     #
REM #                                                                                                                  #
REM ####################################################################################################################
:JUDGE_KEEP_FILE
REM 함수결과 변수 초기화
call :RESET_FUNC_RESULT

REM [[ 보존 기준 시간 계산 ]] ================================<< START >>===============================
REM current 시간으로 보존기간을 뺀 값을 yymmddhhmm format으로 계산
REM Minutes 단위 계산 
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
		REM 60분 획득하여 보태주기
		SET /a calc_minutes="!calc_minutes!+60"
	    REM hours -1 조정하기 
		IF "%curr_time:~0,1%" == "0" (
		         SET /a calc_hours="%curr_time:~1,1%-1"
		) ELSE   SET /a calc_hours="%curr_time:~0,2%-1"
		IF !calc_hours! GEQ 10 (
		    SET calc_datetime=%curr_date%!calc_hours!!calc_minutes!
		) ELSE (
		    IF !calc_hours! GEQ 0 (
		        SET calc_datetime=%curr_date%0!calc_hours!!calc_minutes!
			) ELSE (
				REM 24시간 획득하여 보태주기 
				SET /a calc_hours="!calc_hours!+24"
		        REM 날짜 조정필요
				SET curr_year=%curr_date:~0,4%
				SET curr_month=%curr_date:~4,2%
			    REM Day -1 조정하기
				IF "%curr_date:~6,1%" == "0" (
				          SET /a calc_days="%curr_date:~7,1%-1"
				) ELSE    SET /a calc_days="%curr_date:~6,2%-1" 
                IF !calc_days! GTR 10 (
                    SET calc_date=!curr_year!!curr_month!!calc_days!        
                ) ELSE (
	 			    IF !calc_days! GTR 0 (
				        SET calc_date=!curr_year!!curr_month!0!calc_days!
				    ) ELSE (
                        REM MONTH 조정필요  
						IF "!curr_month:~0,1!" == "0" (
						          SET /a calc_month="!curr_month:~1,1!"
						) ELSE    SET /a calc_month="!curr_month!"						
						REM !calc_month!가 3월이면, 전월이 2월로 Day 계산 시 윤년을 고려하여 28,29,짝수/홀수 고려하여 30,31을 보태준다.
						IF !calc_month! EQU 3 (
							REM 윤년 체크하기
    						call :CHECK_LEAP_YEAR "!curr_year!"
							IF !is_leap_year!	== "TRUE" (
							    REM 윤년으로 29일을 획득하여 보태주기
							    SET /a calc_days+=29
							) ELSE (
							    REM 평년으로 28일을 획득하여 보태주기
							    SET /a calc_days+=28
							)
							REM MONTH -1 조정하기
							SET /a calc_month-=1
							REM YEAR 조정 없음
							SET /a calc_year=!curr_year!
						) ELSE (
						    IF !calc_month! EQU 1 (
							    REM 1월은 전월인 12월에서 31일 획득하여 보태주기
							    SET /a calc_days+=31
								SET calc_month=12
								REM 1월은 YEAR-1 조정하기
								SET /a calc_year="!curr_year!-1"
							) ELSE (
							    SET /a mod_by_2="!calc_month!%%2"
								REM 짝수월은 31일 보태주기
								IF !mod_by_2! EQU 0 (
						            REM 짝수월은 전월에서 31일 획득하여 보태주기
									SET /a calc_days+=31
								) ELSE (
						            REM 홀수월은 전월에서 30일 획득하여 보태주기
									SET /a calc_days+=30
                                )
    							REM MONTH -1 조정하기
								SET /a calc_month-=1
							    REM YEAR 조정 없음
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
REM [[ 보존 기준 시간 계산 ]] ================================<< END   >>===============================

REM [[ 파일 시간 계산 ]] ================================<< START >>===============================
IF !WatchFileTimeFormat! == "Afternoon" (
    REM Afternoon은 12시간을 더하는 시간조정을 한다.
	IF "!WatchFileTime:~12,1!" == "0" (
	          SET /a file_calc_hours="!WatchFileTime:~13,1!+12"
	) ELSE    SET /a file_calc_hours="!WatchFileTime:~12,2!+12"
    SET file_datetime=!WatchFileTime:~1,4!!WatchFileTime:~6,2!!WatchFileTime:~9,2!!file_calc_hours!!WatchFileTime:~15,2!
) ELSE (
    REM Morning과 24hour 는 시간 조정 없음
    SET file_datetime=!WatchFileTime:~1,4!!WatchFileTime:~6,2!!WatchFileTime:~9,2!!WatchFileTime:~12,2!!WatchFileTime:~15,2!
)
REM [[ 파일 시간 계산 ]] ================================<< END   >>===============================

REM [[ 보존여부 체크 ]] ================================<< START >>===============================
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
REM [[ 보존여부 체크 ]] ================================<< END   >>===============================

REM 정상 함수 종료
EXIT /B 
REM :JUDGE_KEEP_FILE END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : 윤년여부 계산하기                                                                                   #
REM # 함  수  명 : CHECK_LEAP_YEAR                                                                                     #
REM #                                                                                                                  #
REM ####################################################################################################################
:CHECK_LEAP_YEAR
REM 함수결과 변수 초기화
call :RESET_FUNC_RESULT

REM 윤년계산하기 - 1) 4의 배수는 윤년 2) 100의 배수는 평년 3) 100의 배수이고 400의 배수는 윤년
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
REM 정상 함수 종료
EXIT /B 
REM :CHECK_LEAP_YEAR END


REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : 디렉토리 생성하기                                                                                   #
REM # 함  수  명 : CREATE_DIR                                                                                          #
REM #                                                                                                                  #
REM ####################################################################################################################
:CREATE_DIR
REM 함수결과 변수 초기화
call :RESET_FUNC_RESULT

REM 디렉토리 생성하기
mkdir %1
IF NOT %ERRORLEVEL% == 0 (
    REM 오류 함수 종료
    call :SET_ERROR_FUNC_RESULT
    EXIT /B 
)
REM 정상 함수 종료
EXIT /B 
REM :CREATE_DIR END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : 디렉토리 Hidden 속성으로 변경                                                                       #
REM # 함  수  명 : SET_HIDDEN_ATTR_DIR                                                                                 #
REM #                                                                                                                  #
REM ####################################################################################################################
:SET_HIDDEN_ATTR_DIR
REM 함수결과 변수 초기화
call :RESET_FUNC_RESULT

REM Hidden system 속성 설정
attrib +H +S %1
	
REM 정상 함수 종료
EXIT /B 
REM :SET_HIDDEN_ATTR_DIR END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : 파일을 삭제하기                                                                                     #
REM # 함  수  명 : DELETE_FILE                                                                                         #
REM #                                                                                                                  #
REM ####################################################################################################################
:DELETE_FILE
REM 함수결과 변수 초기화
call :RESET_FUNC_RESULT

REM 삭제하기
del %~1 2> "%~1.del"

REM 통계 : 보존대상 누적 파일 총 갯수
IF NOT EXIST %~1 (
    SET /A DEL_FILES+=1
) ELSE (
      SET /A ERR_FILES+=1
      call :WRITE_LOG_INFO "[%~1] 파일 Delete 중 오류 발생"
	  REM del 실행 에러정보 로그파일에 추가
	  type "%~1.del" >> %BATCHLOGFILE%
)
REM 삭제실행 결과 임시로그 삭제하기
del "%~1.del" 2> nil
REM 정상 함수 종료
EXIT /B 
REM :DELETE_FILE END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : 에러 문자열을 로그파일에 쓰기                                                                       #
REM # 함  수  명 : WRITE_LOG_ERROR                                                                                     #
REM #                                                                                                                  #
REM ####################################################################################################################
:WRITE_LOG_ERROR
call :WRITE_LOG "(E)%date% %time% :%~1"
REM 정상 함수 종료
EXIT /B 
REM :WRITE_LOG_ERROR END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : Information 문자열을 로그파일에 쓰기                                                                #
REM # 함  수  명 : WRITE_LOG_INFO                                                                                      #
REM #                                                                                                                  #
REM ####################################################################################################################
:WRITE_LOG_INFO
call :WRITE_LOG "(I)%date% %time% :%~1"
REM 정상 함수 종료
EXIT /B 
REM :WRITE_LOG_INFO END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : DEBUG 문자열을 로그파일에 쓰기                                                                      #
REM # 함  수  명 : WRITE_LOG_DEBUG                                                                                     #
REM #                                                                                                                  #
REM ####################################################################################################################
:WRITE_LOG_DEBUG
call :WRITE_LOG_DEBUG "(D)%date% %time% :%~1"
REM 정상 함수 종료
EXIT /B 
REM :WRITE_LOG_DEBUG END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : 문자열을 로그파일에 쓰기                                                                            #
REM # 함  수  명 : WRITE_LOG                                                                                           #
REM #                                                                                                                  #
REM ####################################################################################################################
:WRITE_LOG
REM 함수결과 변수 초기화
call :RESET_FUNC_RESULT

REM echo "WRITE_LOG 변수 확인 : %BATCHLOGDIR%, %BATCHLOGFILE%"
REM 디렉토리 생성하기
IF EXIST %BATCHLOGFILE% (
    REM LOG 파일 디렉토리로 이동
    cd "%BATCHLOGDIR%"
    FOR  %%i in ( %BATCHLOGFILE% ) do (
        REM echo "WRITE_LOG 파일사이즈: %BATCHLOGFILE% %%~zi "
	    IF %%~zi GTR 512000 ( 
            del "%%~i.bak" 2>nul
            ren "%%~i" "%BATCHSNAME%.log.bak"
            echo ============================================================= >> %BATCHLOGFILE%
            echo %DATE% %TIME% Logfile Backup And Re-create >> %BATCHLOGFILE%
            echo ============================================================= >> %BATCHLOGFILE%
        )
    )
	REM 이전 디렉토리로 전환
	cd "%CURR_DIRECTORY%"
) ELSE (
    echo ============================================================= >> %BATCHLOGFILE%
    echo %DATE% %TIME% Logfile is not exist Logfile create >> %BATCHLOGFILE%
    echo ============================================================= >> %BATCHLOGFILE%
)
echo %~1 >> %BATCHLOGFILE%

REM 정상 함수 종료
EXIT /B 
REM :WRITE_LOG END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : 함수 처리결과코드 정보 초기화 처리                                                                  #
REM # 함  수  명 : RESET_FUNC_RESULT                                                                                   #
REM #                                                                                                                  #
REM ####################################################################################################################
:RESET_FUNC_RESULT
SET Func_Result=0
REM 정상 함수 종료
EXIT /B 
REM :RESET_FUNC_RESULT END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : 함수 처리결과 에러 코드 정보 셋팅                                                                   #
REM # 함  수  명 : SER_ERROR_FUNC_RESULT                                                                               #
REM #                                                                                                                  #
REM ####################################################################################################################
:SET_ERROR_FUNC_RESULT
SET Func_Result=255
REM 정상 함수 종료
EXIT /B 
REM :SET_ERROR_FUNC_RESULT END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : 프로그램 정상 종료처리                                                                              #
REM # 함  수  명 : EXIT_SUCCEESS_BATCH                                                                                 #
REM #                                                                                                                  #
REM ####################################################################################################################
:EXIT_SUCCEESS_BATCH
REM 프로그램 실행 정상 종료 로그 추가
echo "%date% %time% [%VERSION_INFO%] Process Success Stop "
call :WRITE_LOG_INFO "[%VERSION_INFO%] Process Success Stop"

endlocal
REM 프로그램 정상 종료
EXIT /B 0
REM :EXIT_SUCCEESS_BATCH END

REM ####################################################################################################################
REM #                                                                                                                  #
REM # 목      적 : 프로그램 오류 종료처리                                                                              #
REM # 함  수  명 : EXIT_FAILURE_BATCH                                                                                  #
REM #                                                                                                                  #
REM ####################################################################################################################
:EXIT_FAILURE_BATCH
REM 프로그램 실행 오류 종료 로그 추가
echo "%date% %time% [%VERSION_INFO%] Process Error Stop "
call :WRITE_LOG_ERROR "[%VERSION_INFO%] Process Error Stop"

endlocal
REM 프로그램 오류 종료
EXIT /B 255
REM :EXIT_FAILURE_BATCH END

REM ############################################[ Sub Fuctions END   ]##################################################
