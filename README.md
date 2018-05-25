# FileWatchClean
1. MS DOS Batch 프로그램 - Windows 특정 디렉토리를 주기적으로 감시하며, 파일 변경시간 기준으로 일정기준을 벗어나면 자동으로 삭제하는 프로그램

프로그램명 : FileWatchClean.bat

Usage : FileWatchClean [보존관리폴더경로(대소문자구별)] [보존기간(분단위: 최소10분 이상)] [실행횟수(0이면 무제한 반복)]

* 처리결과 로그 : C:\FileWatchClean\FileWatchClean.log (폴더는 Hidden 속성으로 만들어 짐)

참고 : N번 실행을 요청하는 경우 1회 실행 후 55초 sleep 후 처리하도록 구현되어 있음

* 사유 : 보존 기간이 분 단위로 처리하기 때문에 자원을 효율적으로 사용하기 위함

                 ex1) D:\Applications\logs 폴더의 파일 중에 보존기간 1시간이 지난 파일을 1회 실행하기

                                 FileWatchClean D:\Applications\logs 60 1

                ex2) D:\Applications\logs 폴더의 파일 중에 보존기간 1시간이 지난 파일을 계속 반복 실행하기

                                 FileWatchClean D:\Applications\logs 60 0 

                ex3) 보존관리폴더에 스페이스등이 포함된 경우 보존기간 2시간이 지난 파일을 3회 실행하기

                                FileWatchClean "D:\Applications\ 스페이스 포함되면 인용문자로 묶기" 120 3
                                
2. FileWatchClean.bat를 윈도우 스케쥴러에 등록하여 자동반복 호출하기

프로그램명 : FileWatchClean.vbs

설명 : Windows 스케쥴러를 이용하여 주기적으로 FileWatchClean.bat를 백그라운드로 호출하고자 하는 경우에 사용한다.

사유 - Windows 스케쥴러는 xxx.vbs는 등록 가능하지만, xxx.bat는 등록 불가함.

활용 : 향후 MS DOS Batch 프로그램을 이용하여 주기적으로 처리하고자 하는 경우에 응용하여 처리한다.

        ex1) C:\temp2 디렉토리의 파일을 감시하고, 10분이 경과한 파일을 삭제하는 것을 5번 실행하기, 
                이때 Command 창을 hidden으로 처리하여 사용자에게 노출하지 않기
                ※ FileWatchClean.vbs 프로그램의 소스 내용 수정
                       objShell.ShellExecute "C:\FileWatchClean.bat " , "c:\temp2 10 5", "", "runas", 0

        ex2) C:\temp2 디렉토리의 파일을 감시하고, 10분이 경과한 파일을 삭제하는 것을 10번 실행하기, 
                이때 Command 창을 Pop Up으로 열고 사용자가 확인할 수 있도록 하기
                ※ FileWatchClean.vbs 프로그램의 소스 내용 수정
                       objShell.ShellExecute "C:\FileWatchClean.bat " , "c:\temp2 10 10", "", "runas", 1

        ex3) C:\temp2 디렉토리의 파일을 서버 리부트되더라도 자동으로 15분이 경과한 파일을 삭제하도록 하기
               작업1 :  ※ FileWatchClean.vbs 프로그램의 소스 내용 수정
                                objShell.ShellExecute "C:\FileWatchClean.bat " , "c:\temp2 15 60", "", "runas", 0
               작업2 : 1시간 주기로 윈도우 스케쥴러에 FileWatchClean.vbs를 호출하도록 등록한다.

         *** 상기 예시는 FileWatchClean.bat 파일이 C:\에 복사해 놓았다고 가정한 경우로 프로그램의 실제 경로를 적는다.
