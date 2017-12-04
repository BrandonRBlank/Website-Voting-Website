## Platform: Ruby (version developed on 2.4.2p198)
## Web Framework: Sinatra

## Required gems:
- Sinatra
- Bcrypt
- Sqlite3
- Zip
- CSV
- FileUtils

## How to sign in/sign up:
  Click the _sign-in_ button at the top right. You can create an account using the 
  _sign-up_ button at the top righ also. A default Instructor/TA account is Username='Joe' 
  password='1235'.
  
## How to upload .zip and .csv files:
   Once signed-in as an Instructor/TA, at the top left you can see an _Upload_ button. There you can browse for your .zip file or 
   .csv file (.csv file should be in format of || Username || (unhashed)Password || Role('1' for Student and '2' for Instructor/TA) 
   ||).
   
## How to download reports:
   Once signed-in as an Instructor/TA, at the top left you can see a _Report_ button. There you can view all students and how they 
   used their votes. At the bottom you can click the _Download Report_ button to download the .csv file of the report.
   
## How to view submissions and vote:
  To view submissions you need to be logged in. If you are not logged in and try to view submissions you will be redirected to the
  _sign-up_ page. You can view subissions by clicking the _Submissions_ button at the top left of the page.
  Students can view websites, vote (1st, 2nd, 3rd place), and view total score fora given website.
  Instructors/TAs can view websites and view total scores, but cannot vote on submissions.
   
## Additional Notes:
   Instructor/TA roles cannot vote and will not be shown the the _Report_ section; though, they can see total votes for websites.
   Students do not have access to the _Uplaod_ or _Report_ features, but are able to vote on submissions but get only one vote for 
   each place (1st, 2nd, 3rd) with each vote given a weight (3pts for 1st, 2pts for 2nd, 1pt for 3rd) and the votes are tallied and
   added underneath each website on the _Submissions_ page.
